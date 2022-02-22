pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev A token staking contract that will allow a beneficiary to get a reward in tokens
 *
 */
contract StakingContract is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint;
    
    // ERC20 basic token contract being held
    IERC20 immutable private _token;
    
    // Staking variables, amount and days needed
    uint public rewardInterest = 14;                // Percentage 14%
    uint public rewardPeriod = 31536000;            // Number of seconds needed to get the whole percentage = 1 Year
    uint public MIN_ALLOWED_AMOUNT = 100000;        // Minumum number of tokens to stake
    bool public closed;                             // is the staking closed? 
    address[] public StakeHoldersList;              // List of all stakeholders
    
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


    /*** MODIFIERS *******************************************************************************/
    
    /**
        @dev    Checks if the msg.sender is staking tokens
     */
    modifier isStakeHolder() {
        require(StakeHolders[msg.sender].stake != 0);
        _;
    }

    /*** EVENTS **********************************************************************************/

    event Staked(address _address, uint _amount);
    event Withdrawed(address _address, uint _amount);
    event StakingisClosed(bool _closed);
    event CleanedUp(address _recipient, uint _amount);
    

    /*** CONSTRUCTOR *****************************************************************************/
    
    constructor(address _tokenAddress) {
        _token = IERC20(_tokenAddress);
        stakedTokens = 0;
        rewardedTokens = 0;
        closed = false;
    }
    
    /*** METHODS *********************************************************************************/


    /**
        Stake tokens
        @notice     conditions are:
        @notice         - staking must be open
        @notice         - must be stakeholder
        @notice         - must stake at least MIN_ALLOWED_AMOUNT tokens
        @notice         - can't stake more than he owns
        @notice         - transfer must be successful
     */
    function stake(uint _amount) external  {
        // if closed cannot accept new stakes 
        require( ! closed, "Sorry, staking is closed");
        // One address can stake only once
        require(StakeHolders[msg.sender].stake == 0, "Already Staking");
        // Do we have anought tokens ?
        require(_amount >= MIN_ALLOWED_AMOUNT);
        require(_token.balanceOf(msg.sender) >= _amount);

        // Get user tokens (must be allowed first)
        require(_token.transferFrom(msg.sender,address(this),_amount));

        // Update internal counters
        StakeHolders[msg.sender].stake = _amount;
        StakeHoldersList.push(msg.sender);
        // solhint-disable-next-line not-rely-on-time
        StakeHolders[msg.sender].joinDate = block.timestamp;
        stakedTokens = stakedTokens.add(_amount);
        emit Staked(msg.sender, _amount);      
    }
    

    /**
        Withdraw stake
        gets back the staked tokens and the matured interests if any
        If staking is closed will not get interests

        @notice     Only stakeholders can call this
     */
    function withdraw() isStakeHolder external {
        // How much to send back?
        // A closed staking allow only to get stake back
        // A non-closed staking state adds matured interest
        uint _toSend  = StakeHolders[msg.sender].stake;
        uint _interest = 0;
        if (closed == false) {
            _interest = getInterest();
            _toSend   = _toSend.add(_interest);
        }

        // Do we have anoughgt tokens in the contract?
        require(_token.balanceOf(address(this)) >= _toSend, "Not enough tokens on the contract");

        // Update internal counters
        stakedTokens = stakedTokens.sub(StakeHolders[msg.sender].stake);
        rewardedTokens = rewardedTokens.add(_interest);

        // Give tokens to the staker
        returnTokens(msg.sender,_toSend);      
    }
    

    /**
        Forcefully return funds to a stakeholder
     */
    function returnTokens(address _hodler, uint _toSend) internal {
        // Give tokens to the staker
        require(_token.transfer(_hodler,_toSend));
        // Update internal counters
        StakeHolders[_hodler].stake = 0;
        StakeHolders[_hodler].joinDate = 0;
        emit Withdrawed(_hodler, _toSend);   
    }

    /**
        @dev    Internal function to compute the interests matured
     */
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


    /**
        Sets the staking as closed. In a closed state:
        - won't accept new stakes
        - those who staked can only get back theyr stake without interest
    
        @notice    Only owner can set the staking closed/open
     */

    function closeStaking(bool _close) public onlyOwner {
        // Set the staking as open/closed
        closed = _close;

        uint hodlers = StakeHoldersList.length;
        for (uint i=0; i<hodlers; i++) {
            if (StakeHolders[StakeHoldersList[i]].stake > 0) {
                stakedTokens = stakedTokens.sub(StakeHolders[StakeHoldersList[i]].stake);
                returnTokens(StakeHoldersList[i], StakeHolders[StakeHoldersList[i]].stake);
            }
        }

        // Get back remaining tokens
        cleanUpRemainings();
        emit StakingisClosed (_close);
    }


    /**
        Once the staking is closed and all stakeholders withdrawed their
        stakes, allow owner to get back all remaining tokens handled by 
        the staking contract

        @notice     staking must be closed
        @notice     stakedTokens must be zero
     */    
    function cleanUpRemainings() internal onlyOwner {
        // Staking must be closed first
        require (closed, "Contract is not closed");
        // Owner can cleanup only last
        require (stakedTokens == 0, "Someone still has his token in stake");

        // Send all remaining tokens to owner = msg.sender
        uint remainings = _token.balanceOf(address(this));
        require(_token.transfer(msg.sender,remainings));

        emit CleanedUp(msg.sender, remainings);
    }
}
