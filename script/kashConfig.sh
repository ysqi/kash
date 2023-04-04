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

  targetAssetBytes32="$(cast abi-encode 'f(address)' $targetAsset)"
  # cast send $commargs $DOOR "setMtoken(bytes32,address)" $sideAsset $ASSET
  echo "targetAssetBytes32=$targetAssetBytes32"
  cast send $commargs $DOOR "setChainTokenMapping(address,uint256,bytes32)" $ASSET $targetChainId $targetAssetBytes32
}


checkAsset(){
  symbol=$1
  targetChain=$2
  loadValue "KashDoor" "DOOR"
  loadValueByKey "$targetChain.$symbol" "targetAsset"
  loadValueByKey "$targetChain.chainId" "targetChainId"
  loadValue "market.$symbol.ktoken" "ASSET"

  echo "targetAsset=$targetAsset \n,targetChainId=$targetChainId \n,ASSET=$ASSET"
  sideAsset="$(cast abi-encode 'f(uint256,address)' $targetChainId $targetAsset)"
  sideAsset="$(cast keccak $sideAsset)"
  echo "sideAsset=$sideAsset"

  echo "chainTokenMapping[$ASSET][$targetChainId]="
  cast call $commargs $DOOR "function chainTokenMapping(address,uint256) returns(bytes32)" "$ASSET" "$targetChainId"

  echo "mTokens[$sideAsset]="
  cast call $commargs $DOOR "function mTokens(bytes32) returns(address)" "$sideAsset"


}

# ktoken + id => rtoken
# id+ rtoken = sideAsset

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