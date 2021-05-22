pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @dev A token staking contract that will allow a beneficiary to get a reward in tokens
 *
 */
contract StakingContract {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint;
    
    // ERC20 basic token contract being held
    IERC20 immutable private _token;
    
    // Staking variables, amount and days needed
    uint rewardInterest = 14;                 // Percentage 14%
    uint rewardPeriod = 31536000;             // Number of seconds needed to get the whole percentage = 1 Year
    uint MIN_ALLOWED_AMOUNT = 100000;         // Minumum number of tokens to stake
    
    // Struct for tracking stakeholders
    struct stakeHolder {
        uint joinDate;
        uint stake;
    }
    
    // Stakeholders
    mapping (address => stakeHolder) public StakeHolders;
    
    // Amount of actually staked tokens
    uint public stakedTokens;
    // Total amount of tokens rewarded
    uint public rewardedTokens;
    
    modifier isStakeHolder() {
        require(StakeHolders[msg.sender].stake != 0);
        _;
    }
    
    event Staked(address _address, uint _amount);
    event Withdrawed(address _address, uint _amount);
    
    constructor(address _tokenAddress) {
        _token = IERC20(_tokenAddress);
        stakedTokens = 0;
        rewardedTokens = 0;
    }
    
    function stake(uint _amount) external  {
        require(StakeHolders[msg.sender].stake == 0, "Already Staking");
        require(_amount >= MIN_ALLOWED_AMOUNT);
        require(_token.balanceOf(msg.sender) >= _amount);
        require(_token.transferFrom(msg.sender,address(this),_amount));

        StakeHolders[msg.sender].stake = _amount;
        // solhint-disable-next-line not-rely-on-time
        StakeHolders[msg.sender].joinDate = block.timestamp;
        stakedTokens = stakedTokens.add(_amount);
        emit Staked(msg.sender, _amount);      
    }
    
    function withdraw() isStakeHolder external {
        uint _interest = getInterest();
        uint _toSend = StakeHolders[msg.sender].stake.add(_interest);
        require(_token.balanceOf(address(this)) >= _toSend, "Not enough tokens on the contract");
        require(_token.transfer(msg.sender,_toSend));
        stakedTokens = stakedTokens.sub(StakeHolders[msg.sender].stake);
        rewardedTokens = rewardedTokens.add(_toSend.sub(StakeHolders[msg.sender].stake));
        StakeHolders[msg.sender].stake = 0;
        StakeHolders[msg.sender].joinDate = 0;
        emit Withdrawed(msg.sender, _toSend);      
    }
    
    function getInterest() isStakeHolder public view returns (uint) {
        uint _stake = StakeHolders[msg.sender].stake;
        uint _time = StakeHolders[msg.sender].joinDate;
        uint _now = block.timestamp;
        uint _diff = _now.sub(_time);

        uint numerator = _stake.mul(_diff).mul(rewardInterest);
        uint denominator = rewardPeriod.mul(100);
        
        uint _interest = numerator.div(denominator);
        return _interest;
    }
    
    // function getStakedAmount() public view returns (uint) {
    //     return stakedTokens;
    // }
    
    // function getRewardedAmount() public view returns (uint) {
    //     return rewardedTokens;
    // }
}
