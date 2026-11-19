// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IAgentPay
/// @notice The AgentPay statistics surface consumed by AgentId8004Bridge.
///         Mirrors AgentPay.getStats; the struct is returned as a plain
///         tuple, which is ABI-identical.
interface IAgentPay {
    /// @notice Lifetime payment counters for an address:
    ///         (requestsCreated, paymentsSent, paymentsReceived).
    function getStats(address user)
        external
        view
        returns (uint256 requestsCreated, uint256 paymentsSent, uint256 paymentsReceived);
}
