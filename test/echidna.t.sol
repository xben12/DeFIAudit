// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;


import {HoldHelper} from "../src/HoldHelper.sol";


contract EchiTest is HoldHelper {

    event showBalanceCheck(uint expect, uint having);

    function balanceCheck() public {
        if(totalETH != address(this).balance) {
            emit showBalanceCheck(totalETH, address(this).balance);
        }
        assert(totalETH == address(this).balance);
    }

}
