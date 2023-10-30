// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

contract HoldHelper {
    struct UserAccount {
        uint256 amount;
        uint256 unlocktime;
    }

    mapping(address => UserAccount) private accountInfo;
    uint256 internal totalETH = address(this).balance ; //allow echidna test

    function deposit(uint256 holdSeconds) public payable {
        UserAccount storage info = accountInfo[msg.sender];
        require(holdSeconds <= 365 * 24 * 60 * 60, "Maximum incremental holding time is 1 year!");

        if (holdSeconds > 0 || info.unlocktime == 0) {
            // handle both initialization and increase holding time.
            uint256 basetime = (info.unlocktime == 0) ? (block.timestamp) : (info.unlocktime);
            info.unlocktime = holdSeconds + basetime;
        }

        if (msg.value > 0) {
            info.amount += msg.value;
        }
        totalETH += msg.value;
    }

    function withdraw(uint256 amount) public {
        UserAccount storage info = accountInfo[msg.sender];
        require(block.timestamp >= info.unlocktime, "Still need to hold longer!");
        require(amount <= info.amount, "your balance is insufficient");
        if (amount == 0) {
            amount = info.amount;
        }
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed!");
        totalETH -= amount;
    }
}
