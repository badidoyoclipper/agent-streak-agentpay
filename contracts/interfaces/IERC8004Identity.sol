// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IERC8004Identity
/// @notice The ERC-8004 Identity Registry surface this project consumes.
///
/// Verified against the official reference implementation
/// (github.com/erc-8004/erc-8004-contracts, IdentityRegistryUpgradeable,
/// getVersion() == "2.0.0") and against the live BNB Chain mainnet
/// deployment on 2026-11-20: name() == "AgentIdentity", symbol() == "AGENT".
///
/// Canonical mainnet address (identical on every mainnet, CREATE2 vanity
/// deployment; from scripts/addresses.ts of the official repo):
///   0x8004A169FB4a3325136EB29fA0ceB6D2e539a432
///
/// The registry is an ERC-721 ("AGENT"): each registered agent is a token
/// whose id is assigned sequentially starting at 0. Registration also sets
/// the reserved "agentWallet" metadata entry to the registrant — the
/// agent's verified operational wallet. Note that the registry offers NO
/// enumeration (no tokenOfOwnerByIndex): an address's agent ids can only
/// be discovered off-chain (e.g. via the indexed `Registered` event) or
/// supplied by the agent owner.
interface IERC8004Identity {
    /// @notice ERC-721 balance: number of agents registered to `owner`.
    function balanceOf(address owner) external view returns (uint256);

    /// @notice ERC-721 owner of an agent. Reverts if the agent id does
    ///         not exist (ERC721NonexistentToken).
    function ownerOf(uint256 agentId) external view returns (address);

    /// @notice The verified agent wallet recorded for an agent id.
    function getAgentWallet(uint256 agentId) external view returns (address);

    /// @notice Arbitrary metadata stored under `metadataKey` for an agent.
    function getMetadata(uint256 agentId, string calldata metadataKey) external view returns (bytes memory);

    /// @notice The agent registration document (agent card) URI.
    function tokenURI(uint256 agentId) external view returns (string memory);

    /// @notice True if `spender` is the agent's owner, an operator
    ///         (approved-for-all), or the approved address for this agent.
    ///         The Reputation Registry uses this to forbid self-feedback.
    function isAuthorizedOrOwner(address spender, uint256 agentId) external view returns (bool);

    /// @notice Registers a new agent for the caller and returns its id.
    ///         Only listed here for completeness — registration is always
    ///         performed directly by the agent owner's own wallet, never
    ///         through this project's contracts.
    function register(string calldata agentURI) external returns (uint256 agentId);

    function getVersion() external view returns (string memory);
}
