#!/bin/sh
source ./script/init.sh


loadValue "so3" "so3"
loadValue "chef" "chef"
loadValue "market" "market"

upgradeChef(){
   # deploy implement
  delValue "chefImpl"
  # deploy implement
  cmd="forge create src/SO3Chef.sol:SO3Chef $commargs --json"
  deployContract "chefImpl" "$cmd"
  loadValue "chefImpl" "IMPL"

  echo "impl address is $IMPL"

  cast send  $commargs $chef "upgradeTo(address)" "$IMPL"
  checkErr
}


upgradeMarket(){
   # deploy implement
  delValue "marketImpl"
  # deploy implement
  cmd="forge create src/SO3Market.sol:SO3Market $commargs --json"
  deployContract "marketImpl" "$cmd"
  loadValue "marketImpl" "IMPL"

  echo "impl address is $IMPL"

  cast send  $commargs $market "upgradeTo(address)" "$IMPL"
  checkErr
}

case $1 in
"chef")
  upgradeChef;;
"market")
  upgradeMarket;;
esac