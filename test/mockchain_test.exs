defmodule MockchainTest do
  use ExUnit.Case, async: true
  alias Mockchain.{Account, Block, Transaction, State}
  # alias Mockchain.BlockHeader, as: Header

  test "length" do
    peak = Mockchain.peak()
    peak_block = Mockchain.peakBlock()
    other = Mockchain.block(peak)

    assert peak_block == other
  end

  defp map_accounts(accounts) do
    Enum.map(accounts, fn {addr, state} ->
      addr = Wallet.from_address(Rlp.hex2addr(addr))

      {addr,
       %Account{
         balance: Rlp.bin2num(state["balance"]),
         code: Rlp.bin2addr(state["code"]),
         nonce: Rlp.bin2num(state["nonce"]),
         storageRoot:
           Enum.reduce(state["storage"], MerkleTree.new(), fn {key, value}, tree ->
             MerkleTree.insert(tree, Rlp.hex2num(key), Rlp.bin2num(value))
           end)
       }}
    end)
  end

  test "ethereum-tests" do
    # JSON_TEST=../ethereum-tests/BlockchainTests/bcGasPricerTest/notxs.json mix test test/mockchain_test.exs
    # JSON_TEST=../ethereum-tests/BlockchainTests/bcWalletTest/walletReorganizeOwners.json mix test test/mockchain_test.exs
    case System.get_env("JSON_TEST") do
      nil ->
        for name <- Path.wildcard("test/ethereum-tests/**/*.json") do
          file_test(name)
        end

      name ->
        file_test(name)
    end
  end

  def file_test(filename) do
    case Path.basename(filename, ".json") do
      # Wrong nonces
      "callcodeInInitcodeToExistingContract_d0g0v0" ->
        :skip

      "callcodeInInitcodeToExistingContractWithValueTransfer_d0g0v0" ->
        :skip

      "callcodeInInitcodeToExisContractWithVTransferNEMoney_d0g0v0" ->
        :skip

      "callcodeInInitcodeToEmptyContract_d0g0v0" ->
        :skip

      "callcodeDynamicCode_d0g0v0" ->
        :skip

      "callcodeDynamicCode2SelfCall_d0g0v0" ->
        :skip

      # Missing state entries
      "callcallcallcode_ABCB_RECURSIVE_d0g0v0" ->
        :skip

      "staticcall_createfails_d1g0v0" ->
        :skip

      "staticcall_createfails_d0g0v0" ->
        :skip

      # Whoops wrong nonce
      "CrashingTransaction_d0g0v0" ->
        :skip

      "badOpcodes_d110g0v0" ->
        :skip

      "randomStatetestDEFAULT-Tue_07_58_41-15153-575192_d0g0v0" ->
        :skip

      other ->
        if String.contains?(other, "OOG") do
          :skip
        else
          do_file_test1(filename)
        end
    end
  end

  def do_file_test1(filename) do
    name = Path.basename(filename, ".json")
    key = "#{name}_Constantinople"

    json = File.read!(filename) |> Json.decode!()

    if is_map(json) do
      case Map.fetch(json, key) do
        {:ok, test} ->
          IO.puts("Running  JSON TEST #{name}")
          do_file_test2(test)

        :error ->
          IO.puts("Skipping JSON TEST #{name}")
          :skip
      end
    else
      IO.puts("Skipping JSON TEST #{name}")
    end
  end

  def do_file_test2(test) do
    accounts = map_accounts(test["pre"])

    base = Wallet.from_address(test["genesisBlockHeader"]["coinbase"])
    accounts = [{base, %Account{balance: 100_000_000, nonce: 0}} | accounts]

    transactions = []
    miner = Wallet.new()
    genesis = Mockchain.GenesisFactory.genesis(accounts, transactions, miner)
    hash = Block.hash(genesis)

    Mockchain.set_state(%Mockchain{
      peak: genesis,
      by_hash: %{hash => genesis},
      states: %{},
      length: 1
    })

    chain =
      Enum.reduce(test["blocks"], [genesis], fn block, chain ->
        transactions =
          Enum.map(block["transactions"], fn tx ->
            # "data" : "0x6060604052604051602080611014833960806040818152925160016000818155818055600160a060020a03331660038190558152610102909452938320939093556201518042046101075582917f102d25c49d33fcdb8976a3f2744e0785c98d9e43b88364859e6aec4ae82eff5c91a250610f958061007f6000396000f300606060405236156100b95760e060020a6000350463173825d9811461010b5780632f54bf6e146101675780634123cb6b1461018f5780635c52c2f5146101985780637065cb48146101c9578063746c9171146101fd578063797af62714610206578063b20d30a914610219578063b61d27f61461024d578063b75c7dc61461026e578063ba51a6df1461029e578063c2cf7326146102d2578063cbf0b0c014610312578063f00d4b5d14610346578063f1736d861461037f575b61038960003411156101095760408051600160a060020a033316815234602082015281517fe1fffcc4923d04b559f4d29a8bfc6cda04eb5b0d3c460751c2402c5c5cc9109c929181900390910190a15b565b610389600435600060003643604051808484808284375050509091019081526040519081900360200190209050610693815b600160a060020a0333166000908152610102602052604081205481808083811415610c1357610d6c565b61038b6004355b600160a060020a03811660009081526101026020526040812054115b919050565b61038b60015481565b610389600036436040518084848082843750505090910190815260405190819003602001902090506107e58161013d565b6103896004356000364360405180848480828437505050909101908152604051908190036020019020905061060b8161013d565b61038b60005481565b61038b6004355b600081610a4b8161013d565b610389600435600036436040518084848082843750505090910190815260405190819003602001902090506107d98161013d565b61038b6004803590602480359160443591820191013560006108043361016e565b610389600435600160a060020a033316600090815261010260205260408120549080808381141561039d5761041f565b610389600435600036436040518084848082843750505090910190815260405190819003602001902090506107528161013d565b61038b600435602435600082815261010360209081526040808320600160a060020a0385168452610102909252822054829081818114156107ab576107cf565b610389600435600036436040518084848082843750505090910190815260405190819003602001902090506107f38161013d565b6103896004356024356000600036436040518084848082843750505090910190815260405190819003602001902090506104ac8161013d565b61038b6101055481565b005b60408051918252519081900360200190f35b5050506000828152610103602052604081206001810154600284900a929083168190111561041f5781546001838101805492909101845590849003905560408051600160a060020a03331681526020810187905281517fc7fb647e59b18047309aa15aad418e5d7ca96d173ad704f1031a2c3d7591734b929181900390910190a15b5050505050565b600160a060020a03831660028361010081101561000257508301819055600160a060020a03851660008181526101026020908152604080832083905584835291829020869055815192835282019290925281517fb532073b38c83145e3e5135377a08bf9aab55bc0fd7c1179cd4fb995d2a5159c929181900390910190a15b505b505050565b156104a5576104ba8361016e565b156104c557506104a7565b600160a060020a0384166000908152610102602052604081205492508214156104ee57506104a7565b6104265b6101045460005b81811015610eba57610104805461010891600091849081101561000257600080516020610f7583398151915201548252506020918252604081208054600160a060020a0319168155600181018290556002810180548382559083528383209193610f3f92601f9290920104810190610a33565b60018054810190819055600160a060020a038316906002906101008110156100025790900160005081905550600160005054610102600050600084600160a060020a03168152602001908152602001600020600050819055507f994a936646fe87ffe4f1e469d3d6aa417d6b855598397f323de5b449f765f0c3826040518082600160a060020a0316815260200191505060405180910390a15b505b50565b15610606576106198261016e565b156106245750610608565b61062c6104f2565b60015460fa90106106415761063f610656565b505b60015460fa901061056c5750610608565b6107105b600060015b600154811015610a47575b600154811080156106865750600281610100811015610002570154600014155b15610d7557600101610666565b156104a757600160a060020a0383166000908152610102602052604081205492508214156106c15750610606565b60016001600050540360006000505411156106dc5750610606565b600060028361010081101561000257508301819055600160a060020a038416815261010260205260408120556106526104f2565b5060408051600160a060020a038516815290517f58619076adf5bb0943d100ef88d52d7c3fd691b19d3a9071b555b651fbf418da9181900360200190a1505050565b15610606576001548211156107675750610608565b60008290556107746104f2565b6040805183815290517facbdb084c721332ac59f9b8e392196c9eb0e4932862da8eb9beaf0dad4f550da9181900360200190a15050565b506001830154600282900a908116600014156107ca57600094506107cf565b600194505b5050505092915050565b15610606575061010555565b156106085760006101065550565b156106065781600160a060020a0316ff5b15610a2357610818846000610e4f3361016e565b156108d4577f92ca3a80853e6663fa31fa10b99225f18d4902939b4c53a9caae9043f6efd00433858786866040518086600160a060020a0316815260200185815260200184600160a060020a031681526020018060200182810382528484828181526020019250808284378201915050965050505050505060405180910390a184600160a060020a03168484846040518083838082843750505090810191506000908083038185876185025a03f15060009350610a2392505050565b6000364360405180848480828437505050909101908152604051908190036020019020915061090490508161020d565b158015610927575060008181526101086020526040812054600160a060020a0316145b15610a235760008181526101086020908152604082208054600160a060020a03191688178155600181018790556002018054858255818452928290209092601f01919091048101908490868215610a2b579182015b82811115610a2b57823582600050559160200191906001019061097c565b50600050507f1733cbb53659d713b79580f79f3f9ff215f78a7c7aa45890f3b89fc5cddfbf328133868887876040518087815260200186600160a060020a0316815260200185815260200184600160a060020a03168152602001806020018281038252848482818152602001925080828437820191505097505050505050505060405180910390a15b949350505050565b5061099a9291505b80821115610a475760008155600101610a33565b5090565b15610c005760008381526101086020526040812054600160a060020a031614610c0057604080516000918220805460018201546002929092018054600160a060020a0392909216949293909291819084908015610acd57820191906000526020600020905b815481529060010190602001808311610ab057829003601f168201915b50509250505060006040518083038185876185025a03f1505050600084815261010860209081526040805181842080546001820154600160a060020a033381811686529685018c905294840181905293166060830181905260a06080840181815260029390930180549185018290527fe7c957c06e9a662c1a6c77366179f5b702b97651dc28eee7d5bf1dff6e40bb4a985095968b969294929390929160c083019085908015610ba257820191906000526020600020905b815481529060010190602001808311610b8557829003601f168201915b505097505050505050505060405180910390a160008381526101086020908152604082208054600160a060020a031916815560018101839055600281018054848255908452828420919392610c0692601f9290920104810190610a33565b50919050565b505050600191505061018a565b6000868152610103602052604081208054909450909250821415610c9c578154835560018381018390556101048054918201808255828015829011610c6b57818360005260206000209182019101610c6b9190610a33565b50505060028401819055610104805488929081101561000257600091909152600080516020610f7583398151915201555b506001820154600284900a90811660001415610d6c5760408051600160a060020a03331681526020810188905281517fe1c52dc63b719ade82e8bea94cc41a0d5d28e4aaf536adb5e9cccc9ff8c1aeda929181900390910190a1825460019011610d59576000868152610103602052604090206002015461010480549091908110156100025760406000908120600080516020610f758339815191529290920181905580825560018083018290556002909201559550610d6c9050565b8254600019018355600183018054821790555b50505050919050565b5b60018054118015610d9857506001546002906101008110156100025701546000145b15610dac5760018054600019019055610d76565b60015481108015610dcf5750600154600290610100811015610002570154600014155b8015610de957506002816101008110156100025701546000145b15610e4a57600154600290610100811015610002578101549082610100811015610002578101919091558190610102906000908361010081101561000257810154825260209290925260408120929092556001546101008110156100025701555b61065b565b1561018a5761010754610e655b62015180420490565b1115610e7e57600061010655610e79610e5c565b610107555b6101065480830110801590610e9c5750610106546101055490830111155b15610eb25750610106805482019055600161018a565b50600061018a565b6106066101045460005b81811015610f4a5761010480548290811015610002576000918252600080516020610f75833981519152015414610f3757610104805461010391600091849081101561000257600080516020610f7583398151915201548252506020919091526040812081815560018101829055600201555b600101610ec4565b5050506001016104f9565b61010480546000808355919091526104a790600080516020610f7583398151915290810190610a3356004c0be60200faa20559308cb7b5a1bb3255c16cb1cab91f525b5ae7a03d02fabe",
            # "gasLimit" : "0x012343f0",
            # "gasPrice" : "0x01",
            # "nonce" : "0x00",
            # "r" : "0xc8304ce09c018558fa6c7e19345eee73c4639884225ce26b04a5842d7fb60efb",
            # "s" : "0x29e8299cc5cfd8efd880f6a4a2413146b08ba1acce7c97e68bd9ba97c33b9449",
            # "to" : "",
            # "v" : "0x1b",
            # "value" : "0x64"
            data = Rlp.bin2addr(tx["data"])
            to = Rlp.bin2addr(tx["to"])

            mtx = %Transaction{
              nonce: Rlp.bin2num(tx["nonce"]),
              gasPrice: Rlp.bin2num(tx["gasPrice"]),
              gasLimit: Rlp.bin2num(tx["gasLimit"]),
              to: to,
              value: Rlp.bin2num(tx["value"]),
              init: if(to == nil, do: data, else: nil),
              data: if(to != nil, do: data, else: nil),
              signature:
                Secp256k1.rlp_to_bitcoin(
                  Rlp.bin2addr(tx["v"]),
                  Rlp.bin2addr(tx["r"]),
                  Rlp.bin2addr(tx["s"])
                )
            }

            # ctr should 0x6295ee1b4f6dd65047762f924ecd367c17eabf8f
            # if Transaction.contract_creation?(mtx) do
            #   :io.format("Contract Address: ~p~n", [Transaction.to(mtx) |> Base16.encode()])
            # end

            mtx
          end)

        head =
          Block.create(
            hd(chain),
            transactions,
            Store.wallet(),
            Rlp.bin2num(block["blockHeader"]["timestamp"])
          )
          |> Block.sign(Store.wallet())

        # assert Block.transactions(head) == transactions
        if Block.transactions(head) != transactions do
          IO.puts("\tTransaction mismatch in block #{length(chain)}!")
        end

        # assert Block.gasUsed(head) == Rlp.bin2num(block["blockHeader"]["gasUsed"])
        if Block.gasUsed(head) != Rlp.bin2num(block["blockHeader"]["gasUsed"]) do
          IO.puts(
            "\tGas difference! #{Block.gasUsed(head)} != #{
              Rlp.bin2num(block["blockHeader"]["gasUsed"])
            }"
          )
        else
          IO.puts("\tequal")
        end

        for receipt <- Block.receipts(head) do
          assert receipt.gas_used > 840
        end

        # :io.format("Receipts: ~200p~n", [
        #   Block.receipts(head) |> Enum.map(fn rcpt -> %{rcpt | state: nil} end)
        # ])

        :added = Mockchain.add_block(head, false)
        [head | chain]
      end)

    # "postState" : {
    #   "0x3fb1cd2cd96c6d5c0b5eb3322d807b34482481d4" : {
    #       "balance" : "0x0de0b6b3a75ef08f",
    #       "code" : "",
    #       "nonce" : "0x00",
    #       "storage" : {
    #           "0x00" : "0x01",
    #           "0x01" : "0xfa",
    #           "0x0107" : "0x45fe"
    #       }
    #   },
    state = Block.state(hd(chain))

    reference_accounts = map_accounts(test["postState"])

    :io.format("GOT: ~p~n", [
      State.accounts(state) |> Enum.map(fn {w, acc} -> {w, to_list(acc.storageRoot)} end)
    ])

    for {wallet, account} <- reference_accounts do
      addr = Wallet.address!(wallet)
      # {addr, %Account{}} = {addr, State.account(state, addr)}
      result = State.account(state, addr)

      if result == nil do
        IO.puts("\tMissing account #{Wallet.printable(wallet)}")
      else
        if Account.balance(result) != Account.balance(account) do
          IO.puts(
            "\tBalance mismatch in #{Wallet.printable(wallet)} #{Account.balance(result)} < #{
              Account.balance(account)
            }"
          )
        end

        # if Wallet.equal?(wallet, base) do
        # assert Account.balance(result) <= Account.balance(account)
        # else
        # assert Account.balance(result) == Account.balance(account)
        # end

        assert Account.nonce(result) == Account.nonce(account)
        assert Account.code(result) == Account.code(account)

        # for {key, value} <- to_list(result.storageRoot) do
        #   assert {key, value} == {key, Account.storageInteger(account, key)}
        # end
        assert to_list(result.storageRoot) == to_list(account.storageRoot)
      end
    end

    post_keys = Mockchain.State.accounts(state) |> Map.keys()
    reference_keys = Keyword.keys(reference_accounts) |> Enum.map(&Wallet.address!/1)
    assert post_keys == reference_keys
  end

  defp to_list(tree) do
    MerkleTree.to_list(tree)
    |> Enum.map(fn {key, value} -> {compress(key), compress(value)} end)
    |> Enum.sort()
  end

  defp compress(nil) do
    0
  end

  defp compress(bin) do
    :binary.decode_unsigned(bin)
  end

  #   "genesisBlockHeader" : {
  #     "bloom" : "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  #     "coinbase" : "0x8888f1f195afa192cfee860698584c030f4c9db1",
  #     "difficulty" : "0x020000",
  #     "extraData" : "0x42",
  #     "gasLimit" : "0x01d9a838",
  #     "gasUsed" : "0x00",
  #     "hash" : "0xc7c0cc842bed190774dbe16049d8068e367749f9f3745124c5d6b505e3b600f0",
  #     "mixHash" : "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
  #     "nonce" : "0x0102030405060708",
  #     "number" : "0x00",
  #     "parentHash" : "0x0000000000000000000000000000000000000000000000000000000000000000",
  #     "receiptTrie" : "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
  #     "stateRoot" : "0x7ea0459884b1f9314dbe0644fd182fd4b16708d7f6d775faab302060f19e576a",
  #     "timestamp" : "0x54c98c81",
  #     "transactionsTrie" : "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
  #     "uncleHash" : "0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347"
  # },
  # "genesisRLP" : "0xf901fdf901f8a000000000000000000000000000000000000000000000
  # 00000000000000000000a01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142
  # fd40d49347948888f1f195afa192cfee860698584c030f4c9db1a07ea0459884b1f9314dbe06
  # 44fd182fd4b16708d7f6d775faab302060f19e576aa056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421a056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421b901000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000083020000808401d9a838808454c98c8142a056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421880102030405060708c0c0",
end
