// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/protocol/cross/VaultController.sol";
import { Vault } from "../src/protocol/cross/Vault.sol";
import { MToken } from "../src/protocol/cross/MToken.sol";
import "@openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";

/**
 *
 * How To:
 * 1. Add envrioment variable at .env file.
 * 2. run: forge script script/KashPool.s.sol:KashScript -vvvv -s "initKashPool()" --fork-url $RPC_URL
 *
 */

contract SideChainScript is Script {
    uint256 deployerPrivateKey;

    function setUp() public {
        deployerPrivateKey = vm.envUint("RAW_PRIVATE_KEY");
    }

    function initOnBSCTestnet() external {
        uint256 deployerPrivateKey = vm.envUint("RAW_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address messager = address(0x0);
        address door = 0x4fAE90C5ec94D559abCaD7B26fbfB142D75f0fD6;
        uint256 mosChainId = 212;
        address weth = 0x161aB8635B28a2f190B3f696877A435A032ab1C1;
        address mos = 0xcDf0b81Fea68865158fa00Bd63627d6659A1Bf69;

        // new VaultController
        VaultController impl = new VaultController();

        ERC1967Proxy proxy = new ERC1967Proxy(
                    address(impl),
                    abi.encodeWithSelector(
                        VaultController.initialize.selector,
                        messager,
                        door,mosChainId,weth,mos
                    )
                );
        console.log("VaultController", address(proxy));

        openNewValult(address(proxy), "USDT");
        openNewValult(address(proxy), "USDC");
        openNewValult(address(proxy), "ETH");
        openNewValult(address(proxy), "WBTC");

        vm.stopBroadcast();
    }

    function setVault(address controller, address token, address vault) public {
        VaultController(payable(controller)).setVault(token, vault);
    }

    function openNewValult(address controller, string memory symbol) public {
        vm.startBroadcast(deployerPrivateKey);

        MToken token =
        new MToken(string.concat("Kash ",symbol),symbol,0x0046dE99a7A1C5439132dD44E16A1810bC39D6ee);

        Vault vault = new Vault(address(token),address(controller));

        console.log(string.concat("Kash ", symbol), address(token));
        console.log(string.concat("Kash ", symbol, " valut"), address(vault));

        VaultController(payable(controller)).setVault(address(token), address(vault));
    }
}
