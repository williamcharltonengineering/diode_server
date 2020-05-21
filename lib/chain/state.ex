# Diode Server
# Copyright 2019 IoT Blockchain Technology Corporation LLC (IBTC)
# Licensed under the Diode License, Version 1.0
defmodule Chain.State do
  alias Chain.Account

  # @enforce_keys [:store]
  defstruct accounts: %{}, hash: nil
  @type t :: %Chain.State{accounts: %{}, hash: nil}

  def new() do
    %Chain.State{}
  end

  def normalize(%Chain.State{hash: nil, accounts: accounts} = state) do
    accounts =
      accounts
      |> Enum.map(fn {id, acc} -> {id, Account.normalize(acc)} end)
      |> Map.new()

    state = %{state | accounts: accounts}
    %{state | hash: hash(state)}
  end

  def normalize(%Chain.State{} = state) do
    state
  end

  def tree(%Chain.State{accounts: accounts}) do
    items = Enum.map(accounts, fn {id, acc} -> {id, Account.hash(acc)} end)

    MapMerkleTree.new()
    |> MerkleTree.insert_items(items)
  end

  def hash(%Chain.State{hash: nil} = state) do
    MerkleTree.root_hash(tree(state))
  end

  def hash(%Chain.State{hash: hash}) do
    hash
  end

  def accounts(%Chain.State{accounts: accounts}) do
    accounts
  end

  @spec account(Chain.State.t(), <<_::160>>) :: Chain.Account.t() | nil
  def account(%Chain.State{accounts: accounts}, id = <<_::160>>) do
    Map.get(accounts, id)
  end

  @spec ensure_account(Chain.State.t(), <<_::160>> | Wallet.t() | non_neg_integer()) ::
          Chain.Account.t()
  def ensure_account(state = %Chain.State{}, id = <<_::160>>) do
    case account(state, id) do
      nil -> Chain.Account.new(nonce: 0)
      acc -> acc
    end
  end

  def ensure_account(state = %Chain.State{}, id) when is_integer(id) do
    ensure_account(state, <<id::unsigned-size(160)>>)
  end

  def ensure_account(state = %Chain.State{}, id) do
    ensure_account(state, Wallet.address!(id))
  end

  @spec set_account(Chain.State.t(), binary(), Chain.Account.t()) :: Chain.State.t()
  def set_account(state = %Chain.State{accounts: accounts}, id = <<_::160>>, account) do
    %{state | accounts: Map.put(accounts, id, account), hash: nil}
  end

  @spec delete_account(Chain.State.t(), binary()) :: Chain.State.t()
  def delete_account(state = %Chain.State{accounts: accounts}, id = <<_::160>>) do
    %{state | accounts: Map.delete(accounts, id), hash: nil}
  end

  def difference(%Chain.State{} = state_a, %Chain.State{} = state_b) do
    diff = MerkleTree.difference(tree(state_a), tree(state_b))

    Enum.map(diff, fn {id, _} ->
      acc_a = Chain.State.account(state_a, id)
      acc_b = Chain.State.account(state_b, id)
      {Base16.encode(id), MerkleTree.difference(Account.root(acc_a), Account.root(acc_b))}
    end)
  end

  # ========================================================
  # File Import / Export
  # ========================================================
  @spec to_binary(Chain.State.t()) :: binary
  def to_binary(state) do
    Enum.reduce(accounts(state), Map.new(), fn {id, acc}, map ->
      Map.put(map, id, %{
        nonce: acc.nonce,
        balance: acc.balance,
        data: Account.root(acc) |> MerkleTree.to_list(),
        code: acc.code
      })
    end)
    |> BertInt.encode!()
  end

  def from_binary(bin) do
    map = BertInt.decode!(bin)

    Enum.reduce(map, new(), fn {id, acc}, state ->
      set_account(state, id, %Chain.Account{
        nonce: acc.nonce,
        balance: acc.balance,
        storage_root: MapMerkleTree.new() |> MerkleTree.insert_items(acc.data),
        code: acc.code
      })
    end)
  end
end
