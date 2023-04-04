#!/bin/sh
source ./script/init.sh

ret_val=""

ZERO_ADDRESS="0x0000000000000000000000000000000000000000"


mintERC20(){
  loadValue "$1" "ASSET"
  echo $ASSET
  cast send $commargs $ASSET "mint(uint256)" 10000000000000000000000000000
}


transferShip(){
  # 0x8100f3Bf6FECc9d0bb1889F1E324c1d8B57700c1
  loadValue "$1" "TOKEN"
  cast send  $commargs $TOKEN "transferOwnership(address)"  "0x8100f3Bf6FECc9d0bb1889F1E324c1d8B57700c1"


}

kashDoorMintAsset(){
  loadValue "$1" "ASSET"
  loadValue "KashDoor" "DOOR"
  echo $ASSET
  cast send $commargs $DOOR "execute(address,bytes)" $ASSET "0xa0712d680000000000000000000000000000000000000000000000000000000000111111"
}

transferERC20(){
  loadValue "$1" "ASSET"
  echo $ASSET
  cast send $commargs $ASSET "transfer(address,uint256)" $2 "$3"000000000000000000
}

approve(){
  loadValue "$1" "ASSET"
  echo $ASSET
  cast send $commargs $ASSET "approve(address,uint256)" $2 "0x111110000000000000000000"
}

depositERC20(){
  loadValue "$1" "ASSET"
  loadValue "controller" "CONTROLLER"
  loadValue "tokenMiner" "tokenMiner"
  amount="$2"000000000000000000

  echo "mint asset"
  cast send $commargs $tokenMiner "function mint(address token,address to,uint256 amount)" $ASSET $ETH_FROM $amount

  # function supply(address token, uint256 amount, bytes calldata customData)
  # crossMailNonce
  nonce="$(cast call $commargs $CONTROLLER "function crossMailNonce(address)returns(uint256)" $ETH_FROM)"
  echo "nonce=$nonce"

  cast send $commargs --json $CONTROLLER "function supply(address token, uint256 amount, bytes calldata customData)"  \
  $ASSET $amount 0x0000000000000000000000000000000000000000000000000000000000000001
}

handleWithdraw(){
    loadValue "KashDoor" "DOOR"
  # function supply(address token, uint256 amount, bytes calldata customData)
  cast send $commargs $DOOR "handleWithdraw(address,uint256,address,bytes32,uint256)"  \
  "0x6ecb1e890b68dfa299ddd4856cf30a3d38867b47" "97" "0x02096654B0f3597a6760D29370B2199E8C08e730" "0x6ecb1e890b68dfa299ddd4856cf30a3d38867b47" "200"

}

retryHandleSupply(){
  loadValue "KashDoor" "DOOR"
  # cast call $commargs $DOOR  --data "0xe6d1a087ef30c55df30fe0b76a4734ff521daf75b75955b68f04a5721807717ad082443d0000000000000000000000006ecb1e890b68dfa299ddd4856cf30a3d38867b470000000000000000000000000000000000000000000000302379bf2ca2e0000000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000001600000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001"
  cast send $commargs $DOOR  --data "0xe6d1a087ef30c55df30fe0b76a4734ff521daf75b75955b68f04a5721807717ad082443d0000000000000000000000006ecb1e890b68dfa299ddd4856cf30a3d38867b470000000000000000000000000000000000000000000000302379bf2ca2e0000000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000001600000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001"
}

handleSupply(){

    loadValue "KashDoor" "DOOR"
    # handleSupply(bytes32 sideAsset,bytes32 suppler,uint256 amount,bytes calldata data,uint256 nonce
  cast send $commargs $DOOR "handleSupply(bytes32 sideAsset,bytes32 suppler,uint256 amount,bytes calldata data,uint256 nonce)"  \
  '0xef30c55df30fe0b76a4734ff521daf75b75955b68f04a5721807717ad082443d' \
  '0000000000000000000000006ecb1e890b68dfa299ddd4856cf30a3d38867b47' \
  '0x302379bf2ca2e00000' \
  '0x0000000000000000000000000000000000000000000000000000000000000001' \
  '0x0000000000000000000000000000000000000000000000000000000000000020'
}

decodeHandleSupply(){
  cast cdd "handleSupply(bytes32 sideAsset,bytes32 suppler,uint256 amount,bytes calldata data,uint256 nonce)" $1
  # cast cdd "handleSupply(bytes32 sideAsset,bytes32 suppler,uint256 amount,bytes calldata data,uint256 nonce)" $1
}

setGasLimit(){
  loadValue "controller" "CONTROLLER"
  cast send $commargs $CONTROLLER "function setGasLimit(uint256)"  500000
}

setGasLimitKashDoor(){
  loadValue "KashDoor" "DOOR"
  cast send $commargs $DOOR "function setGasLimit(uint256)"  90000
}

setDoorOnController(){
  loadValue "controller" "CONTROLLER"
  loadValueByKey "map_test.KashDoor" "KashDoor"
  loadValueByKey "map_test.chain" "ChainId"
  cast send $commargs $CONTROLLER "function setDoor(address door,uint256 chainId)" $KashDoor $ChainId
}

setMessagerOnController(){
  loadValue "controller" "CONTROLLER"
  messenger=$1

  cast send $commargs $CONTROLLER "function setMessenger(address)" $1
}

setAssetPrice(){
  loadValue "Oracle" "ORACLE"
  loadValue "market.$1.ktoken" "ASSET"

  price=$(echo "scale=0; 1000000000000000000 * $2 / 1" | bc)
  echo "sending $1 price $price"
  cast send $commargs $ORACLE "function setPrice(address,uint256)" $ASSET $price
}

withdrawERC20(){
  loadValue "$1" "ASSET"
  loadValue "controller" "CONTROLLER"
  cast send $commargs $CONTROLLER "function withdraw(address token, address to, uint256 amount, uint256 nonce)"  \
  $ASSET  0x6Ecb1e890b68DFa299DdD4856cf30a3d38867B47  "$2" 0
}

getMsgId(){


  $data
}

checkMailOnMAP(){
  loadValue "KashDoor" "KashDoor"
  msgId=$1;
  cast call $commargs $KashDoor "function receivedMail(bytes32) returns(bool)" $msgId
}

# createSig

# 检查参数
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <function_name> [args...]"
  exit 1
fi

# 根据参数调用对应的函数
function_name="$1"
shift # 移除第一个参数，保留剩余参数

if [ "$(type -t -- "$function_name")" = "function" ]; then
  $function_name "$@"
else
  echo "Error: Function '$function_name' not found"
  exit 1
fi