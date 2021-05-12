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
    uint rewardAmount = 14;                 // Percentage
    uint rewardPeriod = 31536000;           // Number of seconds needed to get the whole percentage
    uint MIN_ALLOWED_AMOUNT = 100000;       // Minumum number of tokens to stake
    
    // Struct for tracking stakeholders
    struct stakeHolder {
        uint joinDate;
        uint amount;
    }
    
    // Stakeholders
    mapping (address => stakeHolder) public StakeHolders;
    
    // Amount of actually stacked tokens
    uint private _stackedTokens;
    // Total amount of tokens rewarded
    uint private _rewardedTokens;
    
    modifier isStakeHolder() {
        require(StakeHolders[msg.sender].amount != 0);
        _;
    }
    
    event Stacked(address _address, uint _amount);
    event Withdrawed(address _address, uint _amount);
    
    constructor(address _tokenAddress) {
        _token = IERC20(_tokenAddress);
        _stackedTokens = 0;
        _rewardedTokens = 0;
    }
    
    function stake(uint _amount) external  {
        require(_amount != 0);
        require(_amount >= MIN_ALLOWED_AMOUNT);
        require(_token.balanceOf(msg.sender) >= _amount);
        require(_token.transferFrom(msg.sender,address(this),_amount));
        StakeHolders[msg.sender].amount = _amount;
        // solhint-disable-next-line not-rely-on-time
        StakeHolders[msg.sender].joinDate = block.timestamp;
        _stackedTokens = _stackedTokens.add(_amount);
        emit Stacked(msg.sender, _amount);      
    }
    
    function withdraw() isStakeHolder external returns (bool) {
        uint _toSend = getBalance();
        require(_token.balanceOf(address(this)) >= _toSend, "Not enough tokens on the contract");
        require(_token.transfer(address(this),_toSend));
        _stackedTokens = _stackedTokens.sub(_toSend);
        _rewardedTokens = _rewardedTokens.add(_toSend.sub(StakeHolders[msg.sender].amount));
        StakeHolders[msg.sender].amount = 0;
        StakeHolders[msg.sender].joinDate = 0;
        emit Withdrawed(msg.sender, _amount);      
    }
    
    function getStackedAmount() public view returns (uint) {
        return _stackedTokens;
    }
    
    function getRewardedAmount() public view returns (uint) {
        return _rewardedTokens;
    }
    
    function getBalance() isStakeHolder public view returns (uint) {
        uint _amount = StakeHolders[msg.sender].amount;
        uint _time = StakeHolders[msg.sender].joinDate;
        uint _now = block.timestamp;
        uint _diff = _now.sub(_time);
        require(_diff > 0);
        uint multiplier = rewardAmount.add(100)
        uint _newAmount = _amount.div(rewardPeriod).mul(_diff).mul(multiplier).div(100);
        return _newAmount;
    }
    
}
