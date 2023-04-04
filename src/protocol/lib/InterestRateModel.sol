// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/utils/math/SafeMath.sol";

contract InterestRateModel {
    using SafeMath for uint256;

    uint256[40] private myExpValues;

    constructor() {
        //Python： hex(e^20x * 1e18)
        // value= hex(int(math.exp(20*v) * 1e18))
        myExpValues[0] = 0xde0b6b3a7640000; // e^0* 1e18
        myExpValues[1] = 0xde7d382e9be5a80; // e^0.0001* 1e18
        myExpValues[2] = 0xdeef3f75c11cf00; // e^0.0002* 1e18
        myExpValues[3] = 0xdf61812dca37f00; // e^0.0003* 1e18
        myExpValues[4] = 0xdfd3fd74aadac80; // e^0.0004* 1e18
        myExpValues[5] = 0xe046b4686603300; // e^0.0005* 1e18
        myExpValues[6] = 0xe0b9a6270e10c80; // e^0.0006* 1e18
        myExpValues[7] = 0xe12cd2cec4cc580; // e^0.0007* 1e18
        myExpValues[8] = 0xe1a03a7dbb70600; // e^0.0008* 1e18
        myExpValues[9] = 0xe213dd5232b0780; // e^0.0009* 1e18
        myExpValues[10] = 0xde0b6b3a7640000; // e^0* 1e18
        myExpValues[11] = 0xe287bb6a7ac1b00; // e^0.001* 1e18
        myExpValues[12] = 0xe71b3e27a22f880; // e^0.002* 1e18
        myExpValues[13] = 0xebc66b6965d1b00; // e^0.003* 1e18
        myExpValues[14] = 0xf089bd93a8a5b00; // e^0.004* 1e18
        myExpValues[15] = 0xf565b1833fdc700; // e^0.005* 1e18
        myExpValues[16] = 0xfa5ac69abc29080; // e^0.006* 1e18
        myExpValues[17] = 0xff697ecf752fc80; // e^0.007* 1e18
        myExpValues[18] = 0x104925eb6d86af00; // e^0.008* 1e18
        myExpValues[19] = 0x109d5ed93fce2b00; // e^0.009* 1e18
        myExpValues[20] = 0xde0b6b3a7640000; // e^0* 1e18
        myExpValues[21] = 0x10f34b5657d1bb00; // e^0.01* 1e18
        myExpValues[22] = 0x14b406a8920ffc00; // e^0.02* 1e18
        myExpValues[23] = 0x194977651bd65100; // e^0.03* 1e18
        myExpValues[24] = 0x1ee2b5aedbe2f700; // e^0.04* 1e18
        myExpValues[25] = 0x25b946ebc0b36000; // e^0.05* 1e18
        myExpValues[26] = 0x2e136cc020799600; // e^0.06* 1e18
        myExpValues[27] = 0x3846f6e26cf3e600; // e^0.07* 1e18
        myExpValues[28] = 0x44bcb4bf69100800; // e^0.08* 1e18
        myExpValues[29] = 0x53f4aa5104ad1800; // e^0.09* 1e18
        myExpValues[30] = 0xde0b6b3a7640000; // e^0* 1e18
        myExpValues[31] = 0x668b335f8231ec00; // e^0.1* 1e18
        myExpValues[32] = 0x2f5b3982e870b4000; // e^0.2* 1e18
        myExpValues[33] = 0x15deb2fe396ae60000; // e^0.3* 1e18
        myExpValues[34] = 0xa1991a376c11b80000; // e^0.4* 1e18
        myExpValues[35] = 0x4aa0e9e5328ca800000; // e^0.5* 1e18
        myExpValues[36] = 0x2276f475c3bdfa000000; // e^0.6* 1e18
        myExpValues[37] = 0xfea94f12894a20000000; // e^0.7* 1e18
        myExpValues[38] = 0x759b5043d8a9640000000; // e^0.8* 1e18
        myExpValues[39] = 0x36500a0f27d01600000000; // e^0.9* 1e18
    }

    /**
     * @notice 求资金使用率
     *     @param cash 市场尚未被借出的资产放贷数量
     *     @param borrows 市场已被借出的资产数量
     *     @param reserves 平台对该资产的储备量
     *     @dev 资金使用率 = borrows/(borrows+cash-reserves)
     */
    function utilizationRate(uint256 cash, uint256 borrows, uint256 reserves)
        public
        pure
        returns (uint256)
    {
        if (borrows == 0) return 0;
        uint256 c = cash.add(borrows).sub(reserves);
        if (c == 0) {
            return 0;
        }
        uint256 r = borrows.mul(1e18).div(c);
        if (r > 1e18) {
            return 1e18;
        }
        return r;
    }

    /**
     * @notice 求借款利率（每秒）
     *     @param cash 市场尚未被借出的资产放贷数量
     *     @param borrows 市场已被借出的资产数量
     *     @param reserves 平台对该资产的储备量
     *     @dev 借款利率=( (e^(20*UR) -1 ) / (e^20 -1) ) * 0.995 + 0.2x+ 0.005
     */
    function borrowRate(uint256 cash, uint256 borrows, uint256 reserves)
        public
        view
        returns (uint256)
    {
        /**
         * 借款利率 R =( (e^(20X) -1 ) / (e^20 -1) ) * 0.995 + 0.2x+ 0.005
         *     R =    (e^(20X) -1 )/( (e^20-1)/0.995 )  + 0.2x+ 0.005
         *       =    (e^(20X) -1 )/487603210.462100781878499 + 0.2x+ 0.005
         *
         *     R*1e18 = 1e18 * (e^(20X) -1 )/487603210.462100781878499 + 1e18* 0.2x+ 1e18*0.005
         *            = 1e18 * e^(20X)/487603210.4621 - 2050847858.5534806 + 1e18 * 0.2x+ 1e18*0.005
         *            = 1e18 * e^(20X)/487603210.4621 - 2050847858.5534806 + 1e18 * 0.2x+ 1e18*0.005
         */
        uint256 urate = utilizationRate(cash, borrows, reserves);
        uint256 v = exp20(urate / 1e14).div(487603210).add(urate.mul(2).div(10)).add(0.005e18).sub(
            2050847859
        );
        if (v > 1e18) {
            v = 1e18;
        }
        return v / (365 days); //blocks
    }

    /**
     * @notice 求存款放贷利率（区块）
     *     @param cash 市场尚未被借出的资产放贷数量
     *     @param borrows 市场已被借出的资产数量
     *     @param reserves 平台对该资产的储备金
     *     @param reserveFactorMantissa  当前市场储备因子
     *     @dev 存款利率=  （借款利率 * 总借款）/ 总存款
     */
    function supplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) public view returns (uint256) {
        uint256 urate = utilizationRate(cash, borrows, reserves);
        uint256 br = borrowRate(cash, borrows, reserves);
        uint256 rateToPool = br.mul(uint256(1e18).sub(reserveFactorMantissa)).div(1e18);
        // total supply = cash + borrows - reserves
        // R_b * borrows = R_s * supply
        // => R_s = R_b * borrows/supply = R_b * UR
        uint256 rate = rateToPool.mul(urate).div(1e18);
        if (rate > 1e18) {
            //<=100%
            rate = 1e18;
        }
        return rate;
    }

    /*
     * @notice 计算 e^(x/10000) 的近似值，其中 x 有效区间是[0,10000]，代表[0.0000,1.0000]。
     * @dev 比如：e^0.4321 = e^(0.4+0.03+0.002+0.0001)=e^0.4*e^0.03*e^0.002*e^0.0001 。
     * @return 返回值是一个尾数
     */
    function exp20(uint256 x) public view returns (uint256) {
        if (x == 0) {
            return 0xde0b6b3a7640000; // e^0*1e18
        } else if (x == 10000) {
            return 0x19151b9f1a247b000000000; // e^20.0000*1e18
        } else if (x == 9999) {
            return 0x1908474cb6edbb000000000; // e^(20*0.9999)*1e18
        }
        uint256 a = x / 1000;
        uint256 b = (x / 100) % 10;
        uint256 c = (x / 10) % 10;
        uint256 d = x % 10;
        return myExpValues[d].mul(myExpValues[c + 10]).div(1e18).mul(myExpValues[b + 20]).div(1e18)
            .mul(myExpValues[a + 30]).div(1e18);
    }
}
