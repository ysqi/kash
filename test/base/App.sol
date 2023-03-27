// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../../src/protocol/KashPool.sol";
import "../../src/protocol/KashCreditToken.sol";
import "../../src/protocol/KashDebitToken.sol";
import "../../src/protocol/lib/InterestRateModel.sol";
import "../../src/protocol/lib/KashOracle.sol";

import "../mocks/MockERC20.sol";
import "@openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";

struct ReserveState {
    KashPool pool;
    MockERC20 asset;
    KashCreditToken creditToken;
    KashDebitToken debitToken;
    InterestRateModel rateModel;
}

contract App is Test {
    KashPool public pool;
    KashOracle public oracle;

    address public admin;

    constructor() {
        oracle = new KashOracle();

        pool = KashPool(
            address(
                new ERC1967Proxy(
                    address(new KashPool()),
                    abi.encodeWithSelector(
                        KashPool.initialize.selector,
                        address(oracle)
                    )
                )
            )
        );
    }

    function changeMaster(address master) external {
        pool.setMaster(master);
    }

    function createReserve(string calldata symbol, uint8 decimal)
        external
        returns (ReserveState memory)
    {
        MockERC20 asset = new MockERC20(symbol,symbol,decimal);

        KashCreditToken creditToken = new KashCreditToken(
          address(asset),
          string.concat( "Kash credit token ",symbol),
          string.concat( "c_",symbol),
          decimal
        );
        KashDebitToken debitToken = new KashDebitToken(
          address(asset),
          string.concat( "Kash debit token ",symbol),
         string.concat(  "c_",symbol),
          decimal
        );

        creditToken.setPool(address(pool));
        debitToken.setPool(address(pool));

        InterestRateModel rateModel = new InterestRateModel();

        pool.initReserve(
            address(asset),
            address(creditToken),
            address(0),
            address(debitToken),
            address(rateModel)
        );

        // return pool.getReserveData(address(asset));
        return ReserveState({
            pool: pool,
            asset: asset,
            creditToken: creditToken,
            debitToken: debitToken,
            rateModel: rateModel
        });
    }

    function supply(ReserveState calldata reserve, address user, uint256 amount) external {
        reserve.asset.mint(user, amount);

        vm.startPrank(user);
        reserve.asset.approve(address(address(reserve.creditToken)), amount);
        reserve.pool.supply(address(reserve.asset), amount, user, 0);
        vm.stopPrank();
    }

    function setOraclePrice(address asset, uint256 price) external {
        oracle.setPrice(asset, price);
    }
}
