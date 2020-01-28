# Diode Server
# Copyright 2019 IoT Blockchain Technology Corporation LLC (IBTC)
# Licensed under the Diode License, Version 1.0
defmodule TransactionTest do
  use ExUnit.Case
  alias Chain.Transaction
  alias Chain.State
  alias Chain.Account

  test "recoding" do
    [from, to] = Diode.wallets() |> Enum.reverse() |> Enum.take(2)

    before = Chain.peak_state()
    nonce = State.ensure_account(before, from) |> Account.nonce()
    to = Wallet.address!(to)

    tx =
      Network.Rpc.create_transaction(from, <<"">>, %{
        "value" => 1000,
        "nonce" => nonce,
        "to" => to,
        "gasPrice" => 0
      })

    rlp = tx |> Transaction.to_rlp() |> Rlp.encode!()
    tx2 = Transaction.from_rlp(rlp)

    assert tx == tx2
    assert tx2.chain_id == Diode.chain_id()
  end

  test "decoding metamask signed transaction" do
    origin = "0x2e13a61e2be33404976f7e04dd7e99f9ec1f0edf"

    tx =
      "0xf90386018085174876e8008080b90333608060405234801561001057600080fd5b506040516060806102d383398101604090815281516020830151919092015160018054600160a060020a03938416600160a060020a03199182161790915560008054948416948216949094179093556002805492909116919092161790556102568061007d6000396000f3006080604052600436106100775763ffffffff7c01000000000000000000000000000000000000000000000000000000006000350416633c5f7d46811461007c5780634ef1aee4146100a45780634fb3ccc5146100df578063504f04b714610110578063570ca7351461013c578063d90bd65114610151575b600080fd5b34801561008857600080fd5b506100a2600160a060020a03600435166024351515610172565b005b3480156100b057600080fd5b506100cb600160a060020a036004358116906024351661019d565b604080519115158252519081900360200190f35b3480156100eb57600080fd5b506100f46101bd565b60408051600160a060020a039092168252519081900360200190f35b34801561011c57600080fd5b506100a2600160a060020a036004358116906024351660443515156101cc565b34801561014857600080fd5b506100f4610206565b34801561015d57600080fd5b506100cb600160a060020a0360043516610215565b600160a060020a03919091166000908152600660205260409020805460ff1916911515919091179055565b600760209081526000928352604080842090915290825290205460ff1681565b600254600160a060020a031681565b600160a060020a03928316600090815260076020908152604080832094909516825292909252919020805460ff1916911515919091179055565b600154600160a060020a031681565b60066020526000908152604090205460ff16815600a165627a7a723058208df217001cef7e510f8f0352585a03e46b30eba1feaeaf76becbe261832a627f002900000000000000000000000050000000000000000000000000000000000000000000000000000000000000002e13a61e2be33404976f7e04dd7e99f9ec1f0edf0000000000000000000000002e13a61e2be33404976f7e04dd7e99f9ec1f0edf830140caa027cf2c32c9aebf122668b020501f16b0ce9dda8bac8e17c46569c8ad93409c35a0559df7c2b3e34c26b04325aeeac8560bfb24179df1366c250a662ab1fbf094a9"
      |> Base16.decode()

    tx = Transaction.from_rlp(tx)
    assert Transaction.chain_id(tx) == Diode.chain_id()
    assert Wallet.address!(Transaction.origin(tx)) == Base16.decode(origin)
  end
end
