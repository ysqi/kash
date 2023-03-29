#!/bin/sh
source ./script/init.sh

ret_val=""

ZERO_ADDRESS="0x0000000000000000000000000000000000000000"


kashDoorAddAsset(){
  symbol=$1
  targetChain=$2
  loadValue "KashDoor" "DOOR"
  loadValueByKey "$targetChain.$symbol" "targetAsset"
  loadValueByKey "$targetChain.chainId" "targetChainId"
  loadValue "market.$symbol.ktoken" "ASSET"

  echo "targetAsset=$targetAsset \n,targetChainId=$targetChainId \n,ASSET=$ASSET"
  sideAsset="$(cast abi-encode 'f(uint256,address)' $targetChainId $targetAsset)"
  sideAsset="$(cast keccak $sideAsset)"
  cast send $commargs $DOOR "setMtoken(bytes32,address)" $sideAsset $ASSET
  cast send $commargs $DOOR "setChainTokenMapping(address,uint256,bytes32)" $ASSET $targetChainId $targetAsset
}


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