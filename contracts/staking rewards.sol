// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract StakingRewards {
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;

    address public owner;

    uint public duration;
    uint public finishAt;
    // Minimum of last updated time and reward finish time
    uint public updatedAt;
    uint public rewardRate;
    // Sum of (reward rate * dt * 1e18 / total supply)
    uint public rewardPerTokenStored;

    mapping(address => uint) public userRewardPerTokenPaid; // reward stored per user
    mapping(address => uint) public rewards; // rewards to be claimed per user

    uint public totalSupply;  
    mapping(address => uint) public balanceOf;  // shares per user

    constructor(address _stakingToken, address _rewardToken) {
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardToken);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();  //updating the rewardpertokenstored & updatedat
        updatedAt = lastTimeRewardApplicable();

      //updating userrewardpertokenpaid
        if (_account != address(0)) {   
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }

        _;
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return _min(finishAt, block.timestamp);
    }

    function earned(address _account) public view returns (uint) {
        return((balanceOf[_account] *(rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) + rewards[_account];
    }

    function rewardPerToken() public view returns (uint) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored +(rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) / totalSupply;
    }

    function getReward() external updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0; //before transferring we are setting the rewards earned by user to 0
            rewardsToken.transfer(msg.sender, reward);
        }
    }

    function setRewardsDuration(uint _duration) external onlyOwner {
        require(finishAt < block.timestamp, "reward duration not finished");
        duration = _duration;
    }

//since the owner is not earning any rewards so we will pass address(0) in modifier so the above part of update reward doesnot execute
    function notifyRewardAmount(uint _amount) external onlyOwner updateReward(address(0)) {
        if (block.timestamp >= finishAt) {
            rewardRate = _amount / duration;
        } else {
            uint remainingRewards = (finishAt - block.timestamp) * rewardRate;  //if time has not finished yet
            rewardRate = (_amount + remainingRewards) / duration;
        }

        require(rewardRate > 0, "reward rate = 0");
        //there should be enough reward tokens inside of this contract
        require(rewardRate * duration <= rewardsToken.balanceOf(address(this)),"reward amount > balance");

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }

    function stake(uint _amount) external updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
    }

    function withdraw(uint _amount) external updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }


    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;  //if x<=y returns x or else return y 
    }
}





// contract StakingRewards{

//     IERC20 public immutable stakingtoken;
//     IERC20 public immutable rewardstoken;

//     uint public totalsupply;
//     uint public startedat;
//     uint public updatedat;
//     uint public rewardrate;
//     uint public rewardpertokenstored;
//     address public owner;

//     mapping(address=>uint) public userrewardspertoken;
//     mapping(address=>uint) public rewards;
//     mapping (address=>uint) public balanceof;

//     constructor(address _stakingtoken,address _rewardtoken)  {
//         stakingtoken=IERC20(_stakingtoken);
//         rewardstoken=IERC20 (_rewardtoken);
//         owner==msg.sender;
//     }

//     modifier onlyOwner{
//        owner==msg.sender;
//         _;
//     }

//     function rewardpertoken() external{}
//     function getreward() external {}
//     function notifyrewardamount() external {}
//     function stake() external {}
//     function withdraw() external {}

// }



