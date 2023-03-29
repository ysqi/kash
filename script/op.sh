#!/bin/sh
source ./script/init.sh

ret_val=""

ZERO_ADDRESS="0x0000000000000000000000000000000000000000"


mintERC20(){
  loadValue "$1" "ASSET"
  echo $ASSET
  cast send $commargs $ASSET "mint(uint256)" 10000000000000000000000000000
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
  # function supply(address token, uint256 amount, bytes calldata customData)
  cast send $commargs $CONTROLLER "function supply(address token, uint256 amount, bytes calldata customData)"  \
  $ASSET "$2"0000000000000000000 0x0000000000000000000000000000000000000000000000000000000000000001
}

setGasLimit(){
  loadValue "controller" "CONTROLLER"
  cast send $commargs $CONTROLLER "function setGasLimit(uint256)"  500000
}

setDoorOnController(){
  loadValue "controller" "CONTROLLER"
  loadValueByKey "map_test.KashDoor" "KashDoor"
  loadValueByKey "map_test.chain" "ChainId"
  cast send $commargs $CONTROLLER "function setDoor(address door,uint256 chainId)" $KashDoor $ChainId
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