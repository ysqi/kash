// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/protocol/KashCreditToken.sol";
import "../src/protocol/KashDebitToken.sol";
import "../src/protocol/lib/InterestRateModel.sol";
import "../src/protocol/lib/KashOracle.sol";
import "../src/interfaces/IPool.sol";
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
contract KashPoolReservesScript is Script {
    uint256 deployerPrivateKey;

    function setUp() public {
        deployerPrivateKey = vm.envUint("RAW_PRIVATE_KEY");
    }

    function initAllAsset() external {
        address pool = 0x5310C07Cd8fc53bb47dDbFC8d86E1F0bcE213d17;
        address inter = 0x18655E1f7311f5D7B734636c38F2fe8EE09F3b82;
        vm.label(address(pool), "KashPool");

        createAsset(pool, inter, "kUSDT");
        createAsset(pool, inter, "kUSDC");
        createAsset(pool, inter, "kETH");
        createAsset(pool, inter, "kWBTC");
    }

    function createAsset(address pool, address inter, string memory symbol) public {
        vm.startBroadcast(deployerPrivateKey);

        address door = 0x8ADc0e2aFd67776df2F8946aA0649d8C19867C20;
        MToken token = new MToken(string.concat("Kash ",symbol),symbol,door);
        console.log(string.concat("Kash ", symbol), address(token));
        vm.label(address(token), symbol);

        createReserve(pool, inter, address(token));
    }

    function createReserve(address pool, address inter, address asset) public {
        string memory symbol = IERC20Metadata(asset).symbol();
        uint8 decimal = IERC20Metadata(asset).decimals();

        KashCreditToken creditToken = new KashCreditToken(
          address(asset),
          string.concat( "Kash Credit ",symbol),
          string.concat( "c",symbol),
          decimal
        );

        KashDebitToken debitToken = new KashDebitToken(
          address(asset),
          string.concat( "Kash Debit ",symbol),
         string.concat(  "d",symbol),
          decimal
        );

        vm.label(address(debitToken), string.concat("d", symbol));
        vm.label(address(creditToken), string.concat("c", symbol));

        console.log(string.concat("d", symbol), address(debitToken));
        console.log(string.concat("c", symbol), address(creditToken));

        creditToken.setPool(address(pool));
        debitToken.setPool(address(pool));

        IPool(pool).initReserve(
            address(asset), address(creditToken), address(0), address(debitToken), address(inter)
        );
    }

    function setAssetPrice() external {
        address[] memory list = new address[](4);
        uint256[] memory prices = new uint256[](4);

        // USDT
        list[0] = 0x02096654B0f3597a6760D29370B2199E8C08e730; //USDT
        prices[0] = 1 * 1e18;

        list[1] = 0x928a4804d2db43f97e9703927EfA8dd95Ca1D3ae; //USDC
        prices[1] = 1 * 1e18;

        list[2] = 0x27953EABe525687b10802B37CA6789026830Df6E; // ETH
        prices[2] = 1700 * 1e18;

        list[3] = 0xFC1b80975BeADa59B69d2ec96C6bc990403A8f1A; // BTC
        prices[3] = 27000 * 1e18;

        KashOracle oracle = KashOracle(0x991A6C5Ed37a71877627B223Ad90d0ba915ed8f7);

        deployerPrivateKey = vm.envUint("RAW_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        oracle.batchSetPrice(list, prices);
        vm.stopBroadcast();
    }
}
