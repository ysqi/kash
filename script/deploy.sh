#!/bin/sh
source ./script/init.sh

ret_val=""

ZERO_ADDRESS="0x0000000000000000000000000000000000000000"

deployToken(){
  echo "deploy ERC20"
  if  is_exsit  "so3" ; then
    echo "skip deploy when exist"
  else
    cmd="forge create src/SO3.sol:SO3 $commargs --json"
    deployContract "so3" "$cmd"
  fi
}


deployVaultController(){
  echo "deploy config contract"
  if  is_exsit  "vaultController" ; then
    echo "skip deploy when exist"
  else
      # deploy implement
    cmd="forge create src/VaultController.sol:VaultController $commargs --json"
    deployContract "VaultControllerImpl" "$cmd"
    # load var
    loadValue "VaultControllerImpl" "IMPL"
    loadValue "so3" "SO3"
    loadValue "treasury" "treasury"
    loadValue "chef" "chef"

    # deploy proxy
    initializeData="$(cast calldata "initialize(address treasury_, address so3, address chef)" \
                  "$treasury"  "$SO3" "$chef")"
    checkErr
    cmd="forge create lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy $commargs  --json --constructor-args $IMPL $initializeData"
    deployContract "vaultController" "$cmd"
  fi
}



case $1 in
"deployVaultController")
  deployVaultController
  ;;
esac