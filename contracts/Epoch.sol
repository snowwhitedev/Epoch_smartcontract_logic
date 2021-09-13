//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Epoch is ReentrancyGuard {
    struct UserRequest {
        uint256 amount;
        address from;
        uint256 when;
    }

    struct UserRequestInfo {
        uint256 pendingAmount;
        uint256 lastRequestedTime;
    }

    uint256 public immutable EPOCH_STARTED_AT;
    uint256 public epochDuration = 7 days;

    // user => User deposit request info
    mapping(address => UserRequestInfo) public depositQueue;
    uint256 public totalRealAccumulated;
    uint256 public totalPendingDepositedAmount;
    uint256 private lastDepositedTime;
    mapping(address => uint) realAccumulated; // real availale balance of user

    // user => user withdraw request info
    mapping(address => UserRequestInfo) public withdrawQueue;
    uint256 public totalPendingWithdrawAmount;
    uint256 private lastWithdrawTime;

    constructor() {
        EPOCH_STARTED_AT = block.timestamp;
    }

    function epochNumber(uint _timestamp) public view returns(uint) {
        require(_timestamp > EPOCH_STARTED_AT, "UnoRe: Invalid time");
        return (_timestamp - EPOCH_STARTED_AT) / epochDuration;
    }

    function requestDeposit(uint _amount) public nonReentrant {
        updateTotalDeposit();
        updateUserDeposit(msg.sender);
        
        totalPendingDepositedAmount += _amount;
        lastDepositedTime = block.timestamp;
    }

    function updateTotalDeposit() public {
        uint lastEpochNumber = epochNumber(lastDepositedTime);
        uint currentEpochNumer = epochNumber(block.timestamp);

        if (currentEpochNumer - lastEpochNumber > 0) {
            totalRealAccumulated += totalPendingDepositedAmount;
            totalPendingDepositedAmount = 0;
        }
    }

    function updateUserDeposit(address _user) public {
        UserRequestInfo storage _userDepInfo = depositQueue[_user];
        
        uint lastEpochNumber = epochNumber(_userDepInfo.lastRequestedTime);
        uint currentEpochNumber = epochNumber(block.timestamp);

        if (currentEpochNumber - lastEpochNumber > 0 && _userDepInfo.pendingAmount > 0) {
            // To protect reentrancy
            uint _pending = _userDepInfo.pendingAmount;
            _userDepInfo.pendingAmount = 0;
            realAccumulated[_user] += _pending;
        }

        // TODO Event here
    }

    function requestWithdraw(uint _amount) public nonReentrant {
        require(_amount <= realAccumulated[msg.sender], "Exceed balance");
        updateTotalWithdraw();

        totalRealAccumulated -= _amount;
        realAccumulated[msg.sender] -= _amount;
    }

    function updateTotalWithdraw() public {
        uint lastEpochNumber = epochNumber(lastWithdrawTime);
        uint currentEpochNumer = epochNumber(block.timestamp);

        if (currentEpochNumer - lastEpochNumber > 0) {
            
        }
    }

    function updateUserWithdraw() public {

    }
}
