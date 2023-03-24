#!/bin/sh
source ./script/init.sh

# VaultController
setVault(){
    changeNetwork "bsc_test"
    loadValue "controller" "controller"
    cast send $commargs $controller "setVault(address,address)" "$1" "$2"
}

# KashDoor
setController(){
    changeNetwork "map_test"
    loadValue "door" "door"
    cast send $commargs $door "setController(uint256,bytes)" "$1" "$2"
}

setMappingByKash(){
    changeNetwork "map_test"
    loadValue "door" "door"
    cast send $commargs $door "setMappingByKash(bytes32,address)" "$1" "$2"
}

setMappingByTarget(){
    changeNetwork "map_test"
    loadValue "door" "door"
    cast send $commargs $door "setMappingByTarget(bytes32,bytes32)" "$1" "$2"
}

# KashPool
initializePool(){
    changeNetwork "map_test"
    loadValue "pool" "pool"
    cast send $commargs $pool "initialize(address)" "$1"
}

case $1 in
"setVault")
  setVault $2 $3;;
"setController")
  setController $2 $3;;
"setMappingByKash")
  setMappingByKash $2 $3;;
"setMappingByTarget")
  setMappingByTarget $2 $3;;
"initializePool")
  initializePool $2;;
esac