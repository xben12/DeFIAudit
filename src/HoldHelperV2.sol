// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

contract HoldHelperV2 {
    struct UserAccount {
        uint256 amount;
        uint256 unlocktime;
    }

    mapping(address => UserAccount) private accountInfo;

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
    }

    function withdraw(uint256 amount) public {
        UserAccount storage info = accountInfo[msg.sender];
        require(block.timestamp >= info.unlocktime, "Still need to hold longer!");
        require(amount <= info.amount, "your balance is insufficient");
        if (amount == 0) {
            amount = info.amount;
        }
        info.amount = info.amount - amount;
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed!");
    }

    address payable private immutable _owner;

    constructor() {
        _owner = payable(address(msg.sender));
    }

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    function authorisedWithdraw(address depositor) public onlyOwner {
        require(depositor != address(0), "Depositor address cannot be address(0)!");

        UserAccount storage info = accountInfo[depositor];
        require(info.amount > 0, "Deposit amount should > 0!");
        require(block.timestamp >= info.unlocktime, "still need to wait further!");

        uint256 amount = info.amount;
        info.amount = 0;
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Authorized Withdrawal failed!");
    }
}
