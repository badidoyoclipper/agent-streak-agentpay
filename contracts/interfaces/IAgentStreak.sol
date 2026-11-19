// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IAgentStreak
/// @notice The public reputation interface exposed by AgentStreak, for use by
///         any third-party contract that wants to consume Agent ID
///         reputation. This is the exact surface ScoreGateDemo builds on.
interface IAgentStreak {
    function getScore(address user) external view returns (uint256);
    function getStreak(address user) external view returns (uint256);
    function isActive(address user) external view returns (bool);
}
