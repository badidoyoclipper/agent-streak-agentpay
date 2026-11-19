// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IERC8004Reputation
/// @notice The ERC-8004 Reputation Registry surface this project consumes.
///
/// Verified against the official reference implementation
/// (github.com/erc-8004/erc-8004-contracts, ReputationRegistryUpgradeable,
/// getVersion() == "2.0.0") and against the live BNB Chain mainnet
/// deployment on 2026-11-20: getIdentityRegistry() returns the canonical
/// Identity Registry address below.
///
/// Canonical mainnet address (identical on every mainnet, CREATE2 vanity
/// deployment; from scripts/addresses.ts of the official repo):
///   0x8004BAa17C55a88189AE136b182e5fdA19dE9b63
///
/// Feedback model of the standard, as implemented by the reference
/// contracts (v2.0.0):
/// - Feedback is given BY a client (msg.sender, recorded as the
///   `clientAddress`) ABOUT an agent (`agentId`). There is no
///   pre-authorization or accept-list in the deployed standard: any
///   address may give feedback, with exactly one restriction —
/// - SELF-FEEDBACK IS FORBIDDEN: giveFeedback reverts when the caller is
///   the agent's owner, an operator, or the approved address
///   (isAuthorizedOrOwner on the Identity Registry). It also reverts for
///   a nonexistent agent id.
/// - Values are signed fixed point: |value| <= 1e38, valueDecimals <= 18.
/// - Entries are append-only and 1-indexed per (agentId, clientAddress).
///   Only the original giver can revoke their own entry
///   (revokeFeedback); revoked entries are excluded from summaries.
/// - getSummary AVERAGES the matching non-revoked entries of the given
///   clients and REVERTS when `clientAddresses` is empty — callers must
///   pass at least one client (use getClients to discover them).
interface IERC8004Reputation {
    /// @notice Append a feedback entry about `agentId`, authored by the
    ///         caller. See the interface notes for the authorization rule.
    function giveFeedback(
        uint256 agentId,
        int128 value,
        uint8 valueDecimals,
        string calldata tag1,
        string calldata tag2,
        string calldata endpoint,
        string calldata feedbackURI,
        bytes32 feedbackHash
    ) external;

    /// @notice Revoke one of the caller's own feedback entries.
    function revokeFeedback(uint256 agentId, uint64 feedbackIndex) external;

    /// @notice Number of feedback entries `clientAddress` has given about
    ///         `agentId` (also the index of the latest entry; 0 = none).
    function getLastIndex(uint256 agentId, address clientAddress) external view returns (uint64);

    /// @notice Read one feedback entry.
    /// @return value Signed fixed-point value
    /// @return valueDecimals Decimals of `value`
    /// @return tag1 First tag
    /// @return tag2 Second tag
    /// @return isRevoked Whether the giver revoked this entry
    function readFeedback(uint256 agentId, address clientAddress, uint64 feedbackIndex)
        external
        view
        returns (int128 value, uint8 valueDecimals, string memory tag1, string memory tag2, bool isRevoked);

    /// @notice Aggregate over the given clients' non-revoked entries
    ///         matching the tags (empty string = wildcard). Reverts when
    ///         `clientAddresses` is empty.
    /// @return count Number of matching entries
    /// @return summaryValue Average value, expressed with
    ///         `summaryValueDecimals` decimals
    /// @return summaryValueDecimals The most frequent valueDecimals
    ///         among the matching entries
    function getSummary(uint256 agentId, address[] calldata clientAddresses, string calldata tag1, string calldata tag2)
        external
        view
        returns (uint64 count, int128 summaryValue, uint8 summaryValueDecimals);

    /// @notice All addresses that have ever given feedback about an agent.
    function getClients(uint256 agentId) external view returns (address[] memory);

    /// @notice The Identity Registry this Reputation Registry is bound to.
    function getIdentityRegistry() external view returns (address);

    function getVersion() external view returns (string memory);
}
