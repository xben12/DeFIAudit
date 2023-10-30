// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

contract HoldHelperV3 {
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

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    uint256 private immutable PROPOSE_WITHDRAW_TIMELOCK;
    mapping(address => uint256) private propTimeLocker;

    modifier onlyAfterTimeLock(address depositor) {
        uint256 expectTime = propTimeLocker[depositor];
        require(expectTime > 0 && block.timestamp >= expectTime, "Still need to wait or not relevant locked proposal!"); // propTimeLocker[depositor] must be set (>0) and be passed by.
        _;
        propTimeLocker[depositor] = 0; // reset the time lock.
    }

    constructor(uint256 defaultTimeLock) {
        _owner = payable(address(msg.sender));

        if (defaultTimeLock == 0) {
            defaultTimeLock = (24 * 60 * 60) * 30 * 6; // approximated 6 months.
        }
        PROPOSE_WITHDRAW_TIMELOCK = defaultTimeLock;
    }

    function proposeWithdraw(address depositor) external onlyOwner {
        require(depositor != address(0), "Invalide depositor address!");
        UserAccount storage info = accountInfo[depositor];
        require(info.amount > 0, "Deposit amount should > 0!");
        require(propTimeLocker[depositor] == 0, "The withdraw is already proposed");

        uint256 baseUnlockTime = info.unlocktime;
        if (baseUnlockTime < block.timestamp) baseUnlockTime = block.timestamp;

        propTimeLocker[depositor] = baseUnlockTime + PROPOSE_WITHDRAW_TIMELOCK;
    }

    function authorisedWithdraw(address depositor) external onlyOwner onlyAfterTimeLock(depositor) {
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
