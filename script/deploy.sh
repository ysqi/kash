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
    loadValue "door" "MINER"
    cmd="forge create src/protocol/cross/MToken.sol:MToken $commargs --json --constructor-args $name $symbol $MINER "
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

case $1 in
"Door")
  deployDoor
  ;;
"Controller")
  deployController
  ;;
"Vault")
  deployVault $2 $3
  ;;
"deployAssetToken")
  deployMToken $2 $3
esac