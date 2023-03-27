// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/protocol/KashPool.sol";
import "../src/protocol/KashCreditToken.sol";
import "../src/protocol/KashDebitToken.sol";
import "../src/protocol/lib/InterestRateModel.sol";
import "../src/protocol/lib/KashOracle.sol";
import "@openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";

/**
 *
 * How To:
 * 1. Add envrioment variable at .env file.
 * 2. run: forge script script/KashPool.s.sol:KashScript -vvvv -s "initKashPool()" --fork-url $RPC_URL
 *
 */
contract KashScript is Script {
    uint256 deployerPrivateKey;

    function setUp() public {
        deployerPrivateKey = vm.envUint("RAW_PRIVATE_KEY");
    }

    function initKashPool() external {
        vm.startBroadcast(deployerPrivateKey);
        KashOracle oracle = new KashOracle();
        InterestRateModel rateModel = new InterestRateModel();

        KashPool impl = new KashPool();

        ERC1967Proxy proxy = new ERC1967Proxy(
                    address(impl),
                    abi.encodeWithSelector(
                        KashPool.initialize.selector,
                        address(oracle)
                    )
                );
        vm.stopBroadcast();
    }

    function deployInterestRateModel() external {
        vm.startBroadcast(deployerPrivateKey);
    }

    function createReserve(address asset) external {
        vm.startBroadcast(deployerPrivateKey);
        KashPool pool = KashPool(0x8C6Df8525528C5bd90A738AF88Ff070f4d7D4a59);

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

        creditToken.setPool(address(pool));
        debitToken.setPool(address(pool));

        pool.initReserve(
            address(asset),
            address(creditToken),
            address(0),
            address(debitToken),
            address(0xaB25d8890AE24002385c7CA6B4418Ec4CE5ad0dc)
        );
    }
}
