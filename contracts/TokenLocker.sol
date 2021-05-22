pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract TokenTimelock {
    using SafeERC20 for IERC20;

    // ERC20 basic token contract being held
    IERC20 immutable public token;

    // beneficiary of tokens after they are released
    address immutable public beneficiary;

    // timestamp when token release is enabled
    uint256 immutable public releaseTime;

    constructor (IERC20 token_, address beneficiary_, uint256 releaseTime_) {
        // solhint-disable-next-line not-rely-on-time
        require(releaseTime_ > block.timestamp, "TokenTimelock: release time is before current time");
        token = token_;
        beneficiary = beneficiary_;
        releaseTime = releaseTime_;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public virtual {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= releaseTime, "TokenTimelock: current time is before release time");

        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        token.safeTransfer(beneficiary, amount);
    }

    // /**
    //  * @return the token being held.
    //  */
    // function token() public view virtual returns (IERC20) {
    //     return token;
    // }

    // /**
    //  * @return the beneficiary of the tokens.
    //  */
    // function beneficiary() public view virtual returns (address) {
    //     return beneficiary;
    // }

    // /**
    //  * @return the time when the tokens are released.
    //  */
    // function releaseTime() public view virtual returns (uint256) {
    //     return releaseTime;
    // }
}
