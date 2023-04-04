


forge script script/KashDoor.s.sol:KashDoorScript  -vvvv  --fork-url $RPC_URL  --sender 0x0046de99a7a1c5439132dd44e16a1810bc39d6ee  --slow --broadcast  -s "run()"
forge script script/KashDoor.s.sol:KashDoorScript  -vvvv  --fork-url $RPC_URL  --sender 0x0046de99a7a1c5439132dd44e16a1810bc39d6ee  --slow --broadcast  -s "setPoolConfig()"


forge script script/SideChain.s.sol:KashDoorScript  -vvvv  --fork-url $GOERLI_URL  --sender 0x0046de99a7a1c5439132dd44e16a1810bc39d6ee  --slow --broadcast  -s "openNewValult(address,string)"
forge script script/SideChain.s.sol:KashDoorScript  -vvvv  --fork-url $GOERLI_URL  --sender 0x0046de99a7a1c5439132dd44e16a1810bc39d6ee  --slow --broadcast  -s "openNewValult(address,string)"

forge script script/createAsset.s.sol:KashDoorScript  -vvvv  --fork-url $RPC_URL  --sender 0x0046de99a7a1c5439132dd44e16a1810bc39d6ee  --slow --broadcast  -s "run()"



forge script script/KashPoolReserves.s.sol:KashPoolReservesScript  --skip-simulation -vvvv  --fork-url $RPC_URL  --sender 0x0046de99a7a1c5439132dd44e16a1810bc39d6ee  --slow --broadcast -s "createAsset(address,address,string)" 0x5310C07Cd8fc53bb47dDbFC8d86E1F0bcE213d17  0x18655E1f7311f5D7B734636c38F2fe8EE09F3b82 kUSDT

forge script script/TestOP.s.sol:TestOPScript  --skip-simulation -vvvv  --fork-url $RPC_URL  --sender 0x0046de99a7a1c5439132dd44e16a1810bc39d6ee  --slow --broadcast -s "addAssetToDoor()"


forge script script/TestOP.s.sol:TestOPScript  --skip-simulation -vvvv  --fork-url $RPC_URL  --sender 0x0046de99a7a1c5439132dd44e16a1810bc39d6ee  --slow --broadcast -s "handleSupply(address who, address targetAsset, uint256 targetChainId, uint256 amount)" 0x0046dE99a7A1C5439132dD44E16A1810bC39D6ee 0x1A0bf00A35350b90a8bDbF220175FdC0C3c8eAcE 5 1000000000000000000000





