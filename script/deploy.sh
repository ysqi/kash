#!/bin/sh
source ./script/init.sh

ret_val=""

ZERO_ADDRESS="0x0000000000000000000000000000000000000000"

deployMToken(){
  name=$1
  symbol=$2
  echo "deploy mtoken contract"
  if  is_exsit  "$symbol" ; then
    echo "skip deploy when $symbol exist"
  else
    loadValue "miner" "MINER"
    cmd="forge create src/protocol/cross/MToken.sol:MToken $commargs --json --constructor-args $name $symbol $MINER "
    deployContract "$symbol" "$cmd"
  fi
}

deployAssetVaultOnSide(){
  symbol=$1

  deployMToken "Kash$symbol" "$symbol"

  loadValue "$symbol" "ASSET"
  loadValue "controler" "CONTROLER"

  VAULT_KEY="vault_$symbol"

  cmd="forge create src/protocol/cross/Vault.sol:Vault $commargs --json --constructor-args $ASSET $CONTROLER"
  deployContract "$VAULT_KEY" "$cmd"
  loadValue "$VAULT_KEY" "VAULT"
  cast send  $commargs $CONTROLER "setVault(address token, address vault)"  $ASSET $VAULT
}

deployAssetToken(){
  name=$1
  symbol=$2
  echo "deploy assetToken contract"
  if  is_exsit  "$symbol" ; then
    echo "skip deploy when $symbol exist"
  else
    cmd="forge create test/Token.sol:Token $commargs --json --constructor-args $name $symbol "
    deployContract "$symbol" "$cmd"


  fi
}

deployDoor(){
  changeNetwork "map_test"

  echo "deploy config contract"
  if  is_exsit  "door" ; then
    echo "skip deploy when exist"
  else
      # deploy implement
    cmd="forge create src/protocol/cross/KashDoor.sol:KashDoor $commargs --json"
    deployContract "doorImpl" "$cmd"
    # load var
    loadValue "doorImpl" "IMPL"
    loadValue "pool" "pool"
    loadValue "mos" "mos"
    loadValue "messenger" "messenger"

    # deploy proxy
    initializeData="$(cast calldata "initialize(address mosAddr,address messengerAddr)" \
                  "$mos" "$messenger")"
    checkErr
    cmd="forge create ./lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy $commargs  --json --constructor-args $IMPL $initializeData"
    deployContract "door" "$cmd"
  fi
}


updateKashDoor(){
# deploy implement
    cmd="forge create src/protocol/cross/KashDoor.sol:KashDoor $commargs --json"
    deployContract "KashDoorImpl" "$cmd"
    # load var
    loadValue "KashDoorImpl" "IMPL"
    loadValue "KashDoor" "PROXY"

    echo "controller($PROXY) upgrade to $IMPL"
    # update
    cast send $commargs $PROXY "upgradeTo(address impl)"  $IMPL
}

deployController(){
  changeNetwork "bsc_test"

  echo "deploy config contract"
  if  is_exsit  "controller" ; then
    echo "skip deploy when exist"
  else
    # deploy implement
    cmd="forge create src/VaultController.sol:VaultController $commargs --json"
    deployContract "controllerImpl" "$cmd"
    # load var
    loadValue "controllerImpl" "IMPL"
    loadValue "mos" "mos"
    loadValue "messenger" "messenger"
    loadValue "weth" "weth"
    door=$(jq .map_test.door deployInfo.json -r)
    chainid=$(jq .map_test.chain deployInfo.json -r)


    # deploy proxy
    initializeData="$(cast calldata "initialize(address messengerAddress,address doorAddress,uint256 chainid,address wethAddress,address mosAddr)" \
                  "$messenger" "$door" "$chainid" "$weth" "$mos")"
    checkErr
    cmd="forge create lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy $commargs  --json --constructor-args $IMPL $initializeData"
    deployContract "controller" "$cmd"
  fi
}

deployVault(){
  changeNetwork "bsc_test"

  echo "deploy config contract"
  if  is_exsit  "vault" ; then
    echo "skip deploy when exist"
  else
      # deploy implement
    cmd="forge create src/Vault.sol:Vault $commargs --json --constructor-args $1 $2"
    deployContract "vault" "$cmd"

  fi
}

updateControler(){
# deploy implement
    cmd="forge create src/protocol/cross/VaultController.sol:VaultController $commargs --json"
    deployContract "controllerImpl" "$cmd"
    # load var
    loadValue "controllerImpl" "IMPL"
    loadValue "controller" "PROXY"

    echo "controller($PROXY) upgrade to $IMPL"
    # update
    cast send $commargs $PROXY "upgradeTo(address impl)"  $IMPL
}

updateKashPool(){

  # forge script script/KashPoolUpdate.s.sol:KashPoolUpdateScript  -vvvv $commargs --slow --broadcast -s "run()"

  # new kash pool
# deploy implement
    cmd="forge create src/protocol/KashPool.sol:KashPool $commargs --json"
    deployContract "KashPoolImpl" "$cmd"
    # load var
    loadValue "KashPoolImpl" "IMPL"
    loadValue "KashPool" "PROXY"

    # update
    cast send  $commargs $PROXY "upgradeTo(address impl)"  $IMPL
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