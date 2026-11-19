// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IAgentIdRegistry
/// @notice Minimal read interface for the official SPACE ID Agent ID contract
///         on BNB Chain (0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F).
///         Per the official Binance Agent ID Hackathon announcement, an
///         address holds an Agent ID iff balanceOf(address) > 0 on this
///         ERC-721 (symbol "AI", non-transferable) contract.
interface IAgentIdRegistry {
    function balanceOf(address owner) external view returns (uint256);
}
