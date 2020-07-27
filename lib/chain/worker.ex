# Diode Server
# Copyright 2019 IoT Blockchain Technology Corporation LLC (IBTC)
# Licensed under the Diode License, Version 1.0
defmodule Chain.Worker do
  alias Chain.BlockCache, as: Block
  alias Chain.Transaction
  use GenServer

  defstruct creds: nil,
            proposal: nil,
            parent_hash: nil,
            candidate: nil,
            target: 0,
            mode: 75,
            working: false

  @type t :: %Chain.Worker{
          creds: Wallet.t(),
          proposal: [Transaction.t()],
          parent_hash: binary(),
          candidate: Chain.Block.t(),
          target: non_neg_integer(),
          mode: non_neg_integer() | :poll | :disabled,
          working: bool()
        }

  def candidate() do
    GenServer.call(__MODULE__, :candidate)
  end

  def work() do
    if Diode.dev_mode?() do
      ret = GenServer.call(__MODULE__, :work)
      GenServer.call(__MODULE__, :sync)
      ret
    else
      GenServer.call(__MODULE__, :work)
    end
  end

  defp parent_hash(%Chain.Worker{parent_hash: parent_hash}), do: parent_hash

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(_mode) do
    GenServer.start_link(__MODULE__, Diode.worker_mode(), name: __MODULE__)
  end

  def init(mode) do
    state = %Chain.Worker{creds: Diode.miner(), mode: mode}
    :erlang.process_flag(:priority, :low)
    {:ok, _ref} = :timer.send_interval(100, :sleep)
    {:ok, activate_timer(state)}
  end

  @spec update() :: :ok
  def update() do
    Debouncer.immediate(Chain.Worker, fn ->
      GenServer.cast(Chain.Worker, :update)
    end)
  end

  @spec update_sync() :: :ok
  def update_sync() do
    GenServer.call(Chain.Worker, :update)
  end

  @spec set_mode(any()) :: :ok
  def set_mode(mode), do: GenServer.cast(__MODULE__, {:set_mode, mode})
  def mode(), do: GenServer.call(__MODULE__, :mode)

  def handle_cast({:set_mode, mode}, state) do
    {:noreply, %{state | mode: mode, proposal: nil}}
  end

  def handle_cast(:update, state) do
    {:noreply, do_update(state)}
  end

  defp do_update(state) do
    state2 = %{
      state
      | parent_hash: Block.hash(Chain.peak_block()),
        proposal: Chain.Pool.proposal()
    }

    if state == state2 do
      state
    else
      %{activate_timer(state2) | candidate: nil}
    end
  end

  def handle_call(:candidate, _from, state) do
    state = generate_candidate(state)
    {:reply, state.candidate, state}
  end

  def handle_call(:sync, _from, state) do
    Chain.sync()
    {:reply, :ok, state}
  end

  def handle_call(:update, _from, state) do
    {:reply, :ok, do_update(state)}
  end

  def handle_call(:work, _from, state) do
    {:reply, :ok, do_work(state)}
  end

  def handle_call(:mode, _from, state) do
    {:reply, state.mode, state}
  end

  def handle_info(:sleep, state = %{mode: mode}) do
    if is_integer(mode) do
      percentage = 100 - min(mode, 100)
      Process.sleep(percentage)
    end

    {:noreply, state}
  end

  def handle_info(:work, state) do
    {:noreply, do_work(state)}
  end

  defp do_work(state = %{mode: :disabled}) do
    state
  end

  defp do_work(state) do
    state = generate_candidate(state)
    %{creds: creds, candidate: candidate, target: target} = state

    candidate = Block.set_timestamp(candidate, System.os_time(:second))

    block =
      Enum.reduce_while(1..100, candidate, fn _, candidate ->
        candidate =
          Block.increment_nonce(candidate)
          |> Block.sign(creds)

        hash = Block.hash(candidate) |> Hash.integer()

        if hash < target do
          {:halt, candidate}
        else
          {:cont, candidate}
        end
      end)

    Stats.incr(:hashrate, 100)

    hash = Block.hash(block) |> Hash.integer()
    state = %{state | working: false, candidate: block}

    if hash < target do
      if Block.valid?(block) do
        case Chain.add_block(block) do
          :added ->
            do_update(state)

          other ->
            :io.format("Self generated block is valid but is not accepted: ~p~n", [other])
            %{state | candidate: nil, parent_hash: nil, proposal: nil}
        end
      else
        :io.format("Self generated block is invalid: ~p~n", [
          Block.validate(block, Block.parent(block))
        ])

        %{state | candidate: nil, parent_hash: nil, proposal: nil}
      end
    else
      state
    end
    |> activate_timer()
  end

  defp generate_candidate(state = %{parent_hash: nil}) do
    parent_hash = Block.hash(Chain.peak_block())
    generate_candidate(%{state | parent_hash: parent_hash})
  end

  defp generate_candidate(state = %{proposal: nil}) do
    generate_candidate(%{state | proposal: Chain.Pool.proposal()})
  end

  defp generate_candidate(state = %{candidate: nil, creds: creds, proposal: txs}) do
    prev_hash = parent_hash(state)
    parent = %Chain.Block{} = Chain.block_by_hash(prev_hash)
    miner = Wallet.address!(creds)

    block = Block.create_empty(parent, creds, System.os_time(:second))
    position = ChainDefinition.block_reward_position(Block.number(block))

    {:ok, block} =
      if position == :first do
        tx =
          %Transaction{
            nonce: Chain.State.ensure_account(Block.state(block), miner) |> Chain.Account.nonce(),
            gasPrice: 0,
            gasLimit: 1_000_000_000,
            to: Diode.registry_address(),
            data: ABI.encode_spec("blockReward"),
            chain_id: Diode.chain_id()
          }
          |> Transaction.sign(Wallet.privkey!(creds))

        Block.append_transaction(block, tx)
      else
        {:ok, block}
      end

    block =
      Enum.reduce(txs, block, fn tx, block ->
        case Block.append_transaction(block, tx) do
          {:error, :wrong_nonce} ->
            Chain.Pool.remove_transaction(Transaction.hash(tx))
            block

          {:error, _other} ->
            block

          {:ok, block} ->
            block
        end
      end)

    {:ok, block} =
      if position == :last do
        used = Block.gas_used(block)
        fees = Block.gas_fees(block)

        tx =
          %Transaction{
            nonce: Chain.State.ensure_account(Block.state(block), miner) |> Chain.Account.nonce(),
            gasPrice: 0,
            gasLimit: 1_000_000_000,
            to: Diode.registry_address(),
            data: ABI.encode_call("blockReward", ["uint256", "uint256"], [used, fees]),
            chain_id: Diode.chain_id()
          }
          |> Transaction.sign(Wallet.privkey!(creds))

        Block.append_transaction(block, tx)
      else
        {:ok, block}
      end

    block = Block.finalize_header(block)
    target = Block.hash_target(block)

    generate_candidate(%{
      state
      | candidate: block,
        target: target,
        proposal: Chain.Pool.proposal()
    })
  end

  defp generate_candidate(state) do
    state
  end

  defp activate_timer(state = %{working: true}) do
    state
  end

  defp activate_timer(state) do
    cond do
      state.mode == :poll and (state.proposal == [] or state.proposal == nil) ->
        state

      state.mode == :disabled ->
        state

      true ->
        send(self(), :work)
        %{state | working: true}
    end
  end
end
