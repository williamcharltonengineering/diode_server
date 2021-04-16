# Diode Server
# Copyright 2021 Diode
# Licensed under the Diode License, Version 1.1
defmodule Contract.Registry do
  @moduledoc """
    Wrapper for the DiodeRegistry contract functions
    as needed by the inner workings of the chain
  """

  @spec miner_value(0 | 1 | 2 | 3, <<_::160>> | Wallet.t(), any()) :: non_neg_integer
  def miner_value(type, address, blockRef) when type >= 0 and type <= 3 do
    call("MinerValue", ["uint8", "address"], [type, address], blockRef)
    |> :binary.decode_unsigned()
  end

  @spec fleet_value(0 | 1 | 2 | 3, <<_::160>> | Wallet.t(), any()) :: non_neg_integer
  def fleet_value(type, address, blockRef) when type >= 0 and type <= 3 do
    call("ContractValue", ["uint8", "address"], [type, address], blockRef)
    |> :binary.decode_unsigned()
  end

  @spec min_transaction_fee(any()) :: non_neg_integer
  def min_transaction_fee(blockRef) do
    call("MinTransactionFee", [], [], blockRef)
    |> :binary.decode_unsigned()
  end

  @spec epoch(any()) :: non_neg_integer
  def epoch(blockRef) do
    call("Epoch", [], [], blockRef)
    |> :binary.decode_unsigned()
  end

  @spec fee(any()) :: non_neg_integer
  def fee(blockRef) do
    call("Fee", [], [], blockRef)
    |> :binary.decode_unsigned()
  end

  @spec fee_pool(any()) :: non_neg_integer
  def fee_pool(blockRef) do
    call("FeePool", [], [], blockRef)
    |> :binary.decode_unsigned()
  end

  def submit_ticket_raw_tx(ticket) do
    Shell.transaction(Diode.miner(), Diode.registry_address(), "SubmitTicketRaw", ["bytes32[]"], [
      ticket
    ])
  end

  defp call(name, types, values, blockRef) do
    {ret, _gas} = Shell.call(Diode.registry_address(), name, types, values, blockRef: blockRef)
    ret
  end

  # This is the code for the test/dev variant of the registry contract
  # Imported on 31rd July 2020 from build/contracts/DiodeRegistry.json
  def test_code() do
    "0x60806040526004361061012a5760003560e01c80638e0383a4116100ab578063c487e3f71161006f578063c487e3f7146102ff578063c4a9e11614610307578063c76a11731461031c578063cb106cf81461033c578063f4b7401614610351578063f595416f1461037e5761012a565b80638e0383a41461025d57806399ab110d1461028a578063b0128d92146102aa578063b540f894146102ca578063be3bb93c146102df5761012a565b8063534a2422116100f2578063534a2422146101d357806365c68de5146101e65780636f9874a4146102135780637fca4a29146102285780638da08564146102485761012a565b80630a938dff1461012f5780630ac168a1146101655780631b3b98c81461017c5780631dd447061461019c57806345780f5f146101b1575b600080fd5b34801561013b57600080fd5b5061014f61014a366004612792565b610393565b60405161015c9190612d45565b60405180910390f35b34801561017157600080fd5b5061017a610433565b005b34801561018857600080fd5b5061017a6101973660046126c2565b6104a1565b3480156101a857600080fd5b5061017a610683565b3480156101bd57600080fd5b506101c66107f0565b60405161015c919061284d565b61017a6101e1366004612583565b610853565b3480156101f257600080fd5b50610206610201366004612647565b6109b3565b60405161015c9190612cae565b34801561021f57600080fd5b5061014f610b51565b34801561023457600080fd5b5061017a610243366004612583565b610b69565b34801561025457600080fd5b5061014f610db3565b34801561026957600080fd5b5061027d610278366004612583565b610db9565b60405161015c9190612c33565b34801561029657600080fd5b5061017a6102a53660046125bb565b610e64565b3480156102b657600080fd5b5061017a6102c53660046126aa565b610fa7565b3480156102d657600080fd5b5061014f61109e565b3480156102eb57600080fd5b5061014f6102fa366004612792565b6110a4565b61017a6110b7565b34801561031357600080fd5b5061014f6110c1565b34801561032857600080fd5b5061017a61033736600461267f565b6110c7565b34801561034857600080fd5b5061014f611228565b34801561035d57600080fd5b5061037161036c366004612583565b61122e565b60405161015c9190612839565b34801561038a57600080fd5b5061014f611249565b600060ff83166103b5576103ae6103a98361124e565b6112c8565b905061042d565b8260ff16600114156103d2576103ae6103cd8361124e565b6112d7565b8260ff16600214156103ef576103ae6103ea8361124e565b6112e6565b8260ff166003141561040c576103ae6104078361124e565b6112f5565b60405162461bcd60e51b8152600401610424906129cd565b60405180910390fd5b92915050565b33411480159061044257504115155b80156104775750336001600160a01b037f00000000000000000000000000000000000000000000000000000000000000001614155b156104945760405162461bcd60e51b815260040161042490612b11565b61049f600080611304565b565b864381106104c15760405162461bcd60e51b815260040161042490612ba2565b8484176104e05760405162461bcd60e51b815260040161042490612ab9565b60408051600680825260e082019092526060916020820160c08036833701905050905088408160008151811061051257fe5b60200260200101818152505061052788610850565b8160018151811061053457fe5b60200260200101818152505061054987610850565b8160028151811061055657fe5b6020026020010181815250508560001b8160038151811061057357fe5b6020026020010181815250508460001b8160048151811061059057fe5b60200260200101818152505083816005815181106105aa57fe5b602002602001018181525050600060016105c383611571565b60408087015187516020808a0151845160008152909101938490526105e8949361289a565b6020604051602081039080840390855afa15801561060a573d6000803e3d6000fd5b50505060206040510351905061062089826115a1565b61062d8989838a8a61165b565b806001600160a01b0316886001600160a01b03168a6001600160a01b03167fc21a4132cfb2e72d1dd6f45bcb2dabb1722a19b036c895975db93175b1c5c06f60405160405180910390a450505050505050505050565b3361068c61245b565b506001600160a01b0381166000908152600560208181526040808420815160a081018352815481840190815260018301546060808401919091526002840154608084015290825283519081018452600383015481526004830154818601529190940154918101919091529082015290610704826112f5565b9050600081116107265760405162461bcd60e51b815260040161042490612ae7565b610736828263ffffffff61183616565b6001600160a01b0384166000818152600560208181526040808420865180518255808401516001830155820151600282015595820151805160038801559182015160048701559081015194909101939093559151909183156108fc02918491818181858888f193505050501580156107b2573d6000803e3d6000fd5b5060405181906001600160a01b038516906000907f7f22ec7a37a3fa31352373081b22bb38e1e0abd2a05b181ee7138a360edd3e1a908290a4505050565b6060600a80548060200260200160405190810160405280929190818152602001828054801561084857602002820191906000526020600020905b81546001600160a01b0316815260019091019060200180831161082a575b505050505090505b90565b8061085d8161188b565b6108795760405162461bcd60e51b815260040161042490612996565b6000816001600160a01b031663bcea317f6040518163ffffffff1660e01b815260040160206040518083038186803b1580156108b457600080fd5b505afa1580156108c8573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906108ec919061259f565b90506001600160a01b03811633146109165760405162461bcd60e51b8152600401610424906128eb565b61092f346109238561124e565b9063ffffffff6118c716565b6001600160a01b038416600081815260066020908152604080832085518051825580840151600180840191909155908301516002830155958301518051600383015592830151600482015591810151600590920191909155513493917fd859864511fd3f512da77fc95a8c013b3a0e49bdface8f574b2df8527cecea7191a4505050565b6109bb612480565b60006109c6846118ea565b6001600160a01b038416600090815260048201602052604090206003810154919250906109f1612480565b6040518060800160405280876001600160a01b0316815260200184600101548152602001846002015481526020018367ffffffffffffffff81118015610a3657600080fd5b50604051908082528060200260200182016040528015610a7057816020015b610a5d6124b1565b815260200190600190039081610a555790505b509052905060005b82811015610b46576000846003018281548110610a9157fe5b6000918252602090912001546001600160a01b03169050610ab06124db565b506001600160a01b03811660008181526004870160209081526040918290208251608081018452815460ff1615158152600182015481840152600282015481850190815260039092015460608083019182528551808201875296875292519386019390935291519284019290925290850151805191929185908110610b3157fe5b60209081029190910101525050600101610a78565b509695505050505050565b6000610b6443600463ffffffff61190416565b905090565b80610b738161188b565b610b8f5760405162461bcd60e51b815260040161042490612996565b6000816001600160a01b031663bcea317f6040518163ffffffff1660e01b815260040160206040518083038186803b158015610bca57600080fd5b505afa158015610bde573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610c02919061259f565b90506001600160a01b0381163314610c2c5760405162461bcd60e51b8152600401610424906128eb565b6000836001600160a01b031663bcea317f6040518163ffffffff1660e01b815260040160206040518083038186803b158015610c6757600080fd5b505afa158015610c7b573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610c9f919061259f565b9050610ca961245b565b610cb28561124e565b90506000610cbf826112f5565b905060008111610ce15760405162461bcd60e51b815260040161042490612ae7565b610cf1828263ffffffff61183616565b6001600160a01b038088166000908152600660209081526040808320855180518255808401516001830155820151600282015594820151805160038701559182015160048601559081015160059094019390935591519085169183156108fc02918491818181858888f19350505050158015610d71573d6000803e3d6000fd5b5060405181906001600160a01b038816906001907f7f22ec7a37a3fa31352373081b22bb38e1e0abd2a05b181ee7138a360edd3e1a90600090a4505050505050565b60075490565b610dc1612480565b6000610dcc836118ea565b90506040518060800160405280846001600160a01b03168152602001826001015481526020018260020154815260200182600301805480602002602001604051908101604052809291908181526020018280548015610e5457602002820191906000526020600020905b81546001600160a01b03168152600190910190602001808311610e36575b5050505050815250915050919050565b801580610e7357506009810615155b15610e905760405162461bcd60e51b815260040161042490612930565b60005b81811015610fa257610ea3612505565b6040518060600160405280858585600601818110610ebd57fe5b905060200201358152602001858585600701818110610ed857fe5b905060200201358152602001858585600801818110610ef357fe5b905060200201358152509050610f99848484600001818110610f1157fe5b9050602002013560001c610f39868686600101818110610f2d57fe5b90506020020135610850565b610f4b878787600201818110610f2d57fe5b878787600301818110610f5a57fe5b9050602002013560001c888888600401818110610f7357fe5b9050602002013560001c898989600501818110610f8c57fe5b90506020020135876104a1565b50600901610e93565b505050565b33600081815260056020818152604092839020835160a0810185528154818601908152600183015460608084019190915260028401546080840152908252855190810186526003830154815260048301548185015291909301549381019390935281019190915261101e908363ffffffff61194616565b6001600160a01b03821660008181526005602081815260408084208651805182558084015160018301558201516002820155958201518051600388015591820151600487015590810151949091019390935591518492907f81149c79fef0028ec92e02ee17f72b9bba024dce75220cba8d62f7bbcd0922b6908290a45050565b600d5490565b60006110b083836119a3565b9392505050565b61049f3334611bb5565b60025481565b816110d18161188b565b6110ed5760405162461bcd60e51b815260040161042490612996565b6000816001600160a01b031663bcea317f6040518163ffffffff1660e01b815260040160206040518083038186803b15801561112857600080fd5b505afa15801561113c573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190611160919061259f565b90506001600160a01b038116331461118a5760405162461bcd60e51b8152600401610424906128eb565b6111a3836111978661124e565b9063ffffffff61194616565b6001600160a01b038516600081815260066020908152604080832085518051825580840151600180840191909155908301516002830155958301518051600383015592830151600482015591810151600590920191909155518693917f81149c79fef0028ec92e02ee17f72b9bba024dce75220cba8d62f7bbcd0922b691a450505050565b60035481565b6004602052600090815260409020546001600160a01b031681565b600090565b61125661245b565b506001600160a01b0316600090815260066020908152604091829020825160a08101845281548185019081526001830154606080840191909152600284015460808401529082528451908101855260038301548152600483015481850152600590920154938201939093529082015290565b600061042d8260000151611cb5565b600061042d8260000151611ccc565b600061042d8260200151611ccc565b600061042d8260200151611cb5565b61130c610b51565b6007541461131c5761131c611ce0565b600d5482028110156113405760405162461bcd60e51b815260040161042490612a71565b600c8054600a90830190810490819003909155670de0b6b3a7640000016113724161136d83612710611f3b565b611f75565b6001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000166108fc6113b083600a63ffffffff61190416565b6040518115909202916000818181858888f193505050501580156113d8573d6000803e3d6000fd5b50506301312d0082106113fd5760405162461bcd60e51b815260040161042490612bd9565b629896808210611439576008600d548161141357fe5b04600d600082825401925050819055506064600d541015611434576064600d555b61146c565b624c4b40821161146c576008600d548161144f57fe5b600d805492909104909103908190556064111561146c576000600d555b60005b6008548110156115605760006008828154811061148857fe5b60009182526020808320909101546001600160a01b0316808352600990915260408220549092506114c19061271063ffffffff61190416565b905060006114d06000846119a3565b905066038d7ea4c680008110156114eb575066038d7ea4c680005b808211156114f7578091505b811561153e57611507838361202a565b60405182906001600160a01b038516907fc083a1647e3ee591bf42b82564ffb4d16fdbb26068f0080da911c8d8300fd84a90600090a35b50506001600160a01b031660009081526009602052604081205560010161146f565b5061156d60086000612523565b5050565b60008160405160200161158491906127b4565b604051602081830303815290604052805190602001209050919050565b60405163d90bd65160e01b81528290611655906001600160a01b0383169063d90bd651906115d3908690600401612839565b60206040518083038186803b1580156115eb57600080fd5b505afa1580156115ff573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906116239190612627565b60405180604001604052806013815260200172556e726567697374657265642064657669636560681b815250846120ff565b50505050565b6000611666866118ea565b805490915060ff166116c8578054600160ff1990911681178255600a805491820181556000527fc65a7bb8d6351c1cf70c95a316cc6a92839c986682d98bc35f958f4883f9d2a80180546001600160a01b0319166001600160a01b0388161790555b6001600160a01b03851660009081526004820160205260409020805460ff16611728578054600160ff199091168117825560038301805491820181556000908152602090200180546001600160a01b0319166001600160a01b0388161790555b6001600160a01b03851660009081526004820160205260409020805460ff16611788578054600160ff199091168117825560038301805491820181556000908152602090200180546001600160a01b0319166001600160a01b0388161790555b80600201548511156117da57600281018054908690556001830154908603906117b7908263ffffffff61214e16565b6001808501919091558401546117d3908263ffffffff61214e16565b6001850155505b806003015484111561182c5760038101805490859055600283015490850390611809908263ffffffff61214e16565b600280850191909155840154611825908263ffffffff61214e16565b6002850155505b5050505050505050565b61183e61245b565b8161184c8460200151611cb5565b101561186a5760405162461bcd60e51b815260040161042490612c03565b602083015161187f908363ffffffff61217316565b60208401525090919050565b6000813f7fc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a4708181148015906118bf57508115155b949350505050565b6118cf61245b565b82516118e1908363ffffffff6121be16565b83525090919050565b6001600160a01b03166000908152600b6020526040902090565b60006110b083836040518060400160405280601a81526020017f536166654d6174683a206469766973696f6e206279207a65726f000000000000815250612240565b61194e61245b565b8161195c8460000151611cb5565b101561197a5760405162461bcd60e51b815260040161042490612b61565b825161198c908363ffffffff61217316565b8352602083015161187f908363ffffffff6121be16565b600060ff8316611a26576001600160a01b038216600090815260056020818152604092839020835160a081018552815481860190815260018301546060808401919091526002840154608084015290825285519081018652600383015481526004830154818501529190930154938101939093528101919091526103ae906112c8565b8260ff1660011415611aab576001600160a01b038216600090815260056020818152604092839020835160a081018552815481860190815260018301546060808401919091526002840154608084015290825285519081018652600383015481526004830154818501529190930154938101939093528101919091526103ae906112d7565b8260ff1660021415611b30576001600160a01b038216600090815260056020818152604092839020835160a081018552815481860190815260018301546060808401919091526002840154608084015290825285519081018652600383015481526004830154818501529190930154938101939093528101919091526103ae906112e6565b8260ff166003141561040c576001600160a01b038216600090815260056020818152604092839020835160a081018552815481860190815260018301546060808401919091526002840154608084015290825285519081018652600383015481526004830154818501529190930154938101939093528101919091526103ae906112f5565b6001600160a01b038216600090815260056020818152604092839020835160a08101855281548186019081526001830154606080840191909152600284015460808401529082528551908101865260038301548152600483015481850152919093015493810193909352810191909152611c35908263ffffffff6118c716565b6001600160a01b03831660008181526005602081815260408084208651805182558084015160018301558201516002820155958201518051600388015591820151600487015590810151949091019390935591518392907fd859864511fd3f512da77fc95a8c013b3a0e49bdface8f574b2df8527cecea71908290a45050565b6000611cc28260006121be565b6040015192915050565b6000611cd98260006121be565b5192915050565b600080805b600a54811015611f1f576000600a8281548110611cfe57fe5b60009182526020822001546001600160a01b03169150611d1d82612277565b9050611d3081606463ffffffff61190416565b93506000611d3d836118ea565b90506000611d6e611d5d6104008460010154611f3b90919063ffffffff16565b60028401549063ffffffff61214e16565b905060005b6003830154811015611ed057826003018181548110611d8e57fe5b60009182526020808320909101546001600160a01b031680835260048601909152604082206001810154919a509190611dd390611d5d9061040063ffffffff611f3b16565b9050611e0784611dfb8b611def8561271063ffffffff611f3b16565b9063ffffffff611f3b16565b9063ffffffff61190416565b9050611e138a82611f75565b60005b6003830154811015611e8157826004016000846003018381548110611e3757fe5b60009182526020808320909101546001600160a01b031683528201929092526040018120805460ff1916815560018181018390556002820183905560039091019190915501611e16565b506001600160a01b038a1660009081526004860160205260408120805460ff19168155600181018290556002810182905590611ec06003830182612523565b505060019092019150611d739050565b506001600160a01b0384166000908152600b60205260408120805460ff19168155600181018290556002810182905590611f0d6003830182612523565b505060019094019350611ce592505050565b611f2b600a6000612523565b611f33610b51565b600755505050565b600082611f4a5750600061042d565b82820282848281611f5757fe5b04146110b05760405162461bcd60e51b8152600401610424906129f9565b801561156d576001600160a01b038216600090815260096020526040902054611fe457600880546001810182556000919091527ff3f7a9fe364faab93b216da50a3214154f22a0a2b415b23a84c8169e8b636ee30180546001600160a01b0319166001600160a01b0384161790555b6001600160a01b03821660009081526009602052604090205461200d908263ffffffff61214e16565b6001600160a01b0383166000908152600960205260409020555050565b6001600160a01b038216600090815260056020818152604092839020835160a081018552815481860190815260018301546060808401919091526002840154608084015290825285519081018652600383015481526004830154818501529190930154938101939093528101919091526120aa908263ffffffff61228516565b6001600160a01b03909216600090815260056020818152604092839020855180518255808301516001830155840151600282015594810151805160038701559081015160048601559091015192019190915550565b6060836110b057606083612112846122b0565b6040516020016121239291906127ea565b60405160208183030381529060405290508060405162461bcd60e51b815260040161042491906128b8565b6000828201838110156110b05760405162461bcd60e51b81526004016104249061295f565b61217b612544565b6121868360006121be565b905081816040015110156121ac5760405162461bcd60e51b815260040161042490612a3a565b60408101805192909203909152919050565b6121c6612544565b6121cf8361244c565b612209576040805160608101825283815243602082015284518583015191928301916122009163ffffffff61214e16565b9052905061042d565b604080516060810190915283518190612228908563ffffffff61214e16565b8152436020820152604085810151910152905061042d565b600081836122615760405162461bcd60e51b815260040161042491906128b8565b50600083858161226d57fe5b0495945050505050565b600061042d6103a98361124e565b61228d61245b565b8251604001516122a3908363ffffffff61214e16565b8351604001525090919050565b60408051602a808252606082810190935282919060208201818036833701905050905060008360601b9050600360fc1b826000815181106122ed57fe5b60200101906001600160f81b031916908160001a905350600f60fb1b8260018151811061231657fe5b60200101906001600160f81b031916908160001a90535060005b6014811015612443576040518060400160405280601081526020016f181899199a1a9b1b9c1cb0b131b232b360811b815250601083836014811061237057fe5b1a8161237857fe5b0460ff168151811061238657fe5b602001015160f81c60f81b8382600202600201815181106123a357fe5b60200101906001600160f81b031916908160001a9053506040518060400160405280601081526020016f181899199a1a9b1b9c1cb0b131b232b360811b81525060108383601481106123f157fe5b1a816123f957fe5b0660ff168151811061240757fe5b602001015160f81c60f81b83826002026003018151811061242457fe5b60200101906001600160f81b031916908160001a905350600101612330565b50909392505050565b60200151600343919091031090565b604051806040016040528061246e612544565b815260200161247b612544565b905290565b604051806080016040528060006001600160a01b031681526020016000815260200160008152602001606081525090565b604051806060016040528060006001600160a01b0316815260200160008152602001600081525090565b60405180608001604052806000151581526020016000815260200160008152602001600081525090565b60405180606001604052806003906020820280368337509192915050565b50805460008255906000526020600020908101906125419190612565565b50565b60405180606001604052806000815260200160008152602001600081525090565b61085091905b8082111561257f576000815560010161256b565b5090565b600060208284031215612594578081fd5b81356110b081612d7a565b6000602082840312156125b0578081fd5b81516110b081612d7a565b600080602083850312156125cd578081fd5b823567ffffffffffffffff808211156125e4578283fd5b81850186601f8201126125f5578384fd5b8035925081831115612605578384fd5b8660208085028301011115612618578384fd5b60200196919550909350505050565b600060208284031215612638578081fd5b815180151581146110b0578182fd5b60008060408385031215612659578182fd5b823561266481612d7a565b9150602083013561267481612d7a565b809150509250929050565b60008060408385031215612691578182fd5b823561269c81612d7a565b946020939093013593505050565b6000602082840312156126bb578081fd5b5035919050565b600080600080600080600061012080898b0312156126de578384fd5b883597506020808a01356126f181612d7a565b975060408a013561270181612d7a565b965060608a0135955060808a0135945060a08a0135935060df8a018b13612726578283fd5b6040516060810181811067ffffffffffffffff82111715612745578485fd5b6040528060c08c01848d018e101561275b578586fd5b8594505b600385101561277e57803582526001949094019390830190830161275f565b505080935050505092959891949750929550565b600080604083850312156127a4578182fd5b823560ff81168114612664578283fd5b815160009082906020808601845b838110156127de578151855293820193908201906001016127c2565b50929695505050505050565b600083516127fc818460208801612d4e565b80830161040560f31b81528451915061281c826002830160208801612d4e565b818101602960f81b60028201526003810193505050509392505050565b6001600160a01b0391909116815260200190565b6020808252825182820181905260009190848201906040850190845b8181101561288e5783516001600160a01b031683529284019291840191600101612869565b50909695505050505050565b93845260ff9290921660208401526040830152606082015260800190565b60006020825282518060208401526128d7816040850160208701612d4e565b601f01601f19169190910160400192915050565b60208082526025908201527f4f6e6c792074686520666c656574206163636f756e74616e742063616e20646f604082015264207468697360d81b606082015260800190565b602080825260159082015274092dcecc2d8d2c840e8d2c6d6cae840d8cadccee8d605b1b604082015260600190565b6020808252601b908201527f536166654d6174683a206164646974696f6e206f766572666c6f770000000000604082015260600190565b6020808252601e908201527f496e76616c696420666c65657420636f6e747261637420616464726573730000604082015260600190565b602080825260129082015271155b9a185b991b195908185c99dd5b595b9d60721b604082015260600190565b60208082526021908201527f536166654d6174683a206d756c7469706c69636174696f6e206f766572666c6f6040820152607760f81b606082015260800190565b6020808252601b908201527f496e737566666963656e742066756e647320746f206465647563740000000000604082015260600190565b60208082526028908201527f41766572616765206761732070726963652062656c6f772063757272656e7420604082015267626173652066656560c01b606082015260800190565b602080825260149082015273496e76616c6964207469636b65742076616c756560601b604082015260600190565b60208082526010908201526f043616e277420776974686472617720360841b604082015260600190565b60208082526030908201527f4f6e6c7920746865206d696e6572206f662074686520626c6f636b2063616e2060408201526f18d85b1b081d1a1a5cc81b595d1a1bd960821b606082015260800190565b60208082526021908201527f43616e277420756e7374616b65206d6f7265207468616e206973207374616b656040820152601960fa1b606082015260800190565b60208082526017908201527f5469636b65742066726f6d20746865206675747572653f000000000000000000604082015260600190565b60208082526010908201526f426c6f636b20697320746f6f2062696760801b604082015260600190565b602080825260169082015275496e737566666963656e742066726565207374616b6560501b604082015260600190565b6000602080835260a0830160018060a01b03808651168386015282860151604086015260408601516060860152606086015160808087015282815180855260c08801915085830194508692505b80831015612ca257845184168252938501936001929092019190850190612c80565b50979650505050505050565b602080825282516001600160a01b0390811683830152838201516040808501919091528085015160608086019190915280860151608080870152805160a087018190526000959491850193919286929160c08901905b80851015612d37578651805187168352888101518984015284015184830152958701956001949094019390820190612d04565b509998505050505050505050565b90815260200190565b60005b83811015612d69578181015183820152602001612d51565b838111156116555750506000910152565b6001600160a01b038116811461254157600080fdfea26469706673582212204bad6b0981d672734ac9c0d7cd5e09bcb0b09d8ea74d1f6b6ca33b3e1878075264736f6c63430006050033"
    |> Base16.decode()
  end
end
