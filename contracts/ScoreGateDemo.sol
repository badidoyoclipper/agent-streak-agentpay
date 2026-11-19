// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IAgentStreak} from "./interfaces/IAgentStreak.sol";

/// @title ScoreGateDemo
/// @notice A deliberately small third-party consumer of AgentStreak.
///
/// This contract exists to prove, in executable code, that the reputation
/// recorded by AgentStreak is genuinely composable: a completely separate
/// project can read a wallet's Agent ID reputation score through
/// AgentStreak's public interface and gate its own features on it — no
/// partnership, no API key, no off-chain oracle.
///
/// The gated feature here is a demo "Trusted Agent" badge: any address whose
/// AgentStreak score meets the threshold can claim it, exactly once. The
/// badge is just a record in this contract (not a token) — the point is the
/// gate, not the prize.
///
/// Permissions (disclosed per hackathon rules): this demo contract has one
/// owner, set at deployment, whose only power is adjusting the score
/// threshold via setThreshold(). The owner cannot move funds (the contract
/// holds none), cannot grant badges manually, and cannot change the
/// AgentStreak address, which is immutable.
contract ScoreGateDemo {
    /// @notice The AgentStreak contract whose scores gate the badge.
    IAgentStreak public immutable agentStreak;

    /// @notice The only privileged address; may adjust `threshold` only.
    address public owner;

    /// @notice Minimum AgentStreak score required to claim the badge.
    uint256 public threshold;

    mapping(address => bool) private _hasBadge;

    /// @notice Total badges claimed.
    uint256 public badgeCount;

    event BadgeClaimed(address indexed user, uint256 scoreAtClaim);
    event ThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);

    error ZeroAddress();
    error NotOwner();
    error ScoreTooLow(uint256 score, uint256 required);
    error AlreadyClaimed();

    constructor(address agentStreak_, uint256 threshold_) {
        if (agentStreak_ == address(0)) revert ZeroAddress();
        agentStreak = IAgentStreak(agentStreak_);
        threshold = threshold_;
        owner = msg.sender;
    }

    /// @notice Adjust the minimum score. Owner only; the demo's single
    ///         disclosed admin power.
    function setThreshold(uint256 newThreshold) external {
        if (msg.sender != owner) revert NotOwner();
        emit ThresholdUpdated(threshold, newThreshold);
        threshold = newThreshold;
    }

    /// @notice True if the address's live AgentStreak score meets the
    ///         threshold right now.
    function canClaim(address user) public view returns (bool) {
        return agentStreak.getScore(user) >= threshold;
    }

    /// @notice Claim the "Trusted Agent" demo badge. Reverts if the caller's
    ///         AgentStreak score is below the threshold, or if the caller
    ///         has already claimed.
    function claimBadge() external {
        if (_hasBadge[msg.sender]) revert AlreadyClaimed();
        uint256 score = agentStreak.getScore(msg.sender);
        if (score < threshold) revert ScoreTooLow(score, threshold);

        _hasBadge[msg.sender] = true;
        badgeCount += 1;
        emit BadgeClaimed(msg.sender, score);
    }

    function hasBadge(address user) external view returns (bool) {
        return _hasBadge[user];
    }
}
