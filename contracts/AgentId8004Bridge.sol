// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IAgentStreak} from "./interfaces/IAgentStreak.sol";
import {IAgentPay} from "./interfaces/IAgentPay.sol";
import {IERC8004Identity} from "./interfaces/IERC8004Identity.sol";
import {IERC8004Reputation} from "./interfaces/IERC8004Reputation.sol";

/// @title AgentId8004Bridge
/// @notice Bridges this project's Agent ID reputation into ERC-8004, the
///         global standard for trustless agent identity and reputation.
///
/// AgentStreak and AgentPay accumulate a rich, sybil-resistant track
/// record against a Binance Agent ID: daily-activity streaks and settled
/// payments. On their own, that data is only readable through this
/// project's contracts. This bridge makes the same record legible to the
/// whole agent ecosystem:
///
/// - READS: anyone can check, through one contract, whether an address
///   is registered as an ERC-8004 agent, whether it owns a given agent
///   id, what its verified agent wallet is, and what feedback that agent
///   has accumulated in the ERC-8004 Reputation Registry.
/// - WRITES: anyone can ask the bridge to publish a reputation snapshot
///   it derives — on-chain, from AgentStreak/AgentPay themselves — into
///   the ERC-8004 Reputation Registry as standard feedback. Two channels
///   are published: the holder's streak score (tag1 "agentstreak",
///   tag2 "score") and their settled payments received (tag1 "agentpay",
///   tag2 "paymentsReceived").
///
/// How this respects the ERC-8004 feedback rules (v2.0.0, verified
/// against the official reference contracts): feedback is authored by
/// the caller — here, this bridge, recorded on-chain as the feedback
/// client — about an agent owned by someone else. The standard forbids
/// self-feedback (owner/operator/approved), and the bridge structurally
/// cannot violate that: it owns no agent, and it only publishes about
/// an agent id whose owner it has just verified equals the subject
/// address. The subject's identity binding is therefore proven at write
/// time, and the values are computed by the bridge from the source
/// contracts — a caller cannot inject, inflate, or choose them.
///
/// Snapshots are append-only in the registry, as the standard intends.
/// To keep them meaningful and cheap, the bridge republishes a channel
/// only when its derived value has changed, and remembers the latest
/// value and feedback index it wrote per agent, so consumers can read
/// the freshest snapshot directly (readFeedback at the stored index)
/// instead of averaging history.
///
/// Safety properties:
/// - No owner, no admin functions, no pause, no withdrawal, no upgrade
///   path. The contract holds no funds and moves none. All four contract
///   addresses it talks to are immutable constructor parameters.
/// - Publishing is a plain transaction the caller sends and confirms
///   from their own wallet. Nothing here executes on a user's behalf.
/// - The bridge deliberately exposes no revoke path: per the standard
///   only the feedback giver can revoke, and an attestation history
///   that third parties could erase would be worthless. Entries stand;
///   fresher snapshots supersede older ones by index.
contract AgentId8004Bridge {
    /// @notice ERC-8004 Identity Registry (BNB Chain mainnet:
    ///         0x8004A169FB4a3325136EB29fA0ceB6D2e539a432).
    IERC8004Identity public immutable identityRegistry;

    /// @notice ERC-8004 Reputation Registry (BNB Chain mainnet:
    ///         0x8004BAa17C55a88189AE136b182e5fdA19dE9b63).
    IERC8004Reputation public immutable reputationRegistry;

    /// @notice Source of streak reputation (this project's AgentStreak).
    IAgentStreak public immutable agentStreak;

    /// @notice Source of payment reputation (this project's AgentPay).
    IAgentPay public immutable agentPay;

    /// @notice Feedback channel ids used across this contract.
    uint8 public constant CHANNEL_STREAK = 0;
    uint8 public constant CHANNEL_PAYMENTS = 1;

    // ERC-8004 feedback tags for the two channels. tag1 names the source
    // system, tag2 the metric, so any consumer can filter precisely.
    string internal constant STREAK_TAG1 = "agentstreak";
    string internal constant STREAK_TAG2 = "score";
    string internal constant PAY_TAG1 = "agentpay";
    string internal constant PAY_TAG2 = "paymentsReceived";

    struct Snapshot {
        uint256 value; // latest value this bridge published for the channel
        uint64 feedbackIndex; // its index in the Reputation Registry (0 = none yet)
    }

    mapping(uint256 => Snapshot) private _streakSnapshots; // agentId => snapshot
    mapping(uint256 => Snapshot) private _paymentSnapshots; // agentId => snapshot

    event ReputationPublished(uint256 indexed agentId, address indexed user, uint8 indexed channel, uint256 value, uint64 feedbackIndex);

    error ZeroAddress();
    error InvalidChannel(uint8 channel);
    error AgentNotOwned(uint256 agentId, address user);
    error NoReputation(uint8 channel);
    error AlreadyCurrent(uint8 channel);
    error NothingToPublish();
    error ValueTooLarge(uint256 value);

    constructor(address identityRegistry_, address reputationRegistry_, address agentStreak_, address agentPay_) {
        if (identityRegistry_ == address(0) || reputationRegistry_ == address(0)) revert ZeroAddress();
        if (agentStreak_ == address(0) || agentPay_ == address(0)) revert ZeroAddress();
        identityRegistry = IERC8004Identity(identityRegistry_);
        reputationRegistry = IERC8004Reputation(reputationRegistry_);
        agentStreak = IAgentStreak(agentStreak_);
        agentPay = IAgentPay(agentPay_);
    }

    // ------------------------------------------------------------------
    // Reads — ERC-8004 registration status and feedback
    // ------------------------------------------------------------------

    /// @notice True if the address owns at least one ERC-8004 agent.
    function isRegistered8004(address user) public view returns (bool) {
        return identityRegistry.balanceOf(user) > 0;
    }

    /// @notice Number of ERC-8004 agents the address owns.
    function agentCount8004(address user) external view returns (uint256) {
        return identityRegistry.balanceOf(user);
    }

    /// @notice True if `user` is the current owner of `agentId`.
    ///         Returns false (never reverts) for nonexistent agent ids,
    ///         so UIs can probe freely.
    function ownsAgent8004(address user, uint256 agentId) public view returns (bool) {
        try identityRegistry.ownerOf(agentId) returns (address owner) {
            return owner == user;
        } catch {
            return false;
        }
    }

    /// @notice The verified agent wallet recorded for an agent id.
    function getAgentWallet8004(uint256 agentId) external view returns (address) {
        return identityRegistry.getAgentWallet(agentId);
    }

    /// @notice The agent registration document (agent card) URI.
    function getAgentURI8004(uint256 agentId) external view returns (string memory) {
        return identityRegistry.tokenURI(agentId);
    }

    /// @notice Pass-through to the Reputation Registry's aggregate.
    ///         NOTE: the registry reverts when `clientAddresses` is
    ///         empty; pass getClients(agentId) or a known client such as
    ///         this bridge's address.
    function getSummary8004(uint256 agentId, address[] calldata clientAddresses, string calldata tag1, string calldata tag2)
        external
        view
        returns (uint64 count, int128 summaryValue, uint8 summaryValueDecimals)
    {
        return reputationRegistry.getSummary(agentId, clientAddresses, tag1, tag2);
    }

    /// @notice The freshest snapshot this bridge published for an agent
    ///         and channel: (value, feedbackIndex). feedbackIndex == 0
    ///         means nothing has been published yet.
    function getPublishedSnapshot(uint256 agentId, uint8 channel) external view returns (uint256 value, uint64 feedbackIndex) {
        if (channel == CHANNEL_STREAK) {
            Snapshot storage s = _streakSnapshots[agentId];
            return (s.value, s.feedbackIndex);
        }
        if (channel == CHANNEL_PAYMENTS) {
            Snapshot storage s = _paymentSnapshots[agentId];
            return (s.value, s.feedbackIndex);
        }
        revert InvalidChannel(channel);
    }

    /// @notice The values a publish would write right now, and whether
    ///         each channel is stale (has an unpublished change).
    /// @return streakScore Live AgentStreak score of `user`
    /// @return paymentsReceived Live settled payments received by `user`
    /// @return streakStale True if the streak channel has a new value to publish
    /// @return paymentsStale True if the payments channel has a new value to publish
    function previewPublish(address user, uint256 agentId)
        external
        view
        returns (uint256 streakScore, uint256 paymentsReceived, bool streakStale, bool paymentsStale)
    {
        streakScore = agentStreak.getScore(user);
        (, , paymentsReceived) = agentPay.getStats(user);
        streakStale = _isStale(_streakSnapshots[agentId], streakScore);
        paymentsStale = _isStale(_paymentSnapshots[agentId], paymentsReceived);
    }

    // ------------------------------------------------------------------
    // Writes — publish locally-derived reputation into ERC-8004
    // ------------------------------------------------------------------

    /// @notice Publish the subject's current AgentStreak score as
    ///         ERC-8004 feedback about their agent.
    /// @param user The reputation subject. Must own `agentId`.
    /// @param agentId The subject's ERC-8004 agent id.
    function publishStreakScore(address user, uint256 agentId) external {
        _requireOwnership(user, agentId);
        _publish(agentId, user, CHANNEL_STREAK, agentStreak.getScore(user), true);
    }

    /// @notice Publish the subject's current settled-payments-received
    ///         count as ERC-8004 feedback about their agent.
    /// @param user The reputation subject. Must own `agentId`.
    /// @param agentId The subject's ERC-8004 agent id.
    function publishPaymentsReceived(address user, uint256 agentId) external {
        _requireOwnership(user, agentId);
        (, , uint256 received) = agentPay.getStats(user);
        _publish(agentId, user, CHANNEL_PAYMENTS, received, true);
    }

    /// @notice Publish every channel that has a fresh value, in one
    ///         transaction. Channels with nothing new are skipped;
    ///         reverts only when neither channel can publish.
    function publishAll(address user, uint256 agentId) external {
        _requireOwnership(user, agentId);
        bool a = _publish(agentId, user, CHANNEL_STREAK, agentStreak.getScore(user), false);
        (, , uint256 received) = agentPay.getStats(user);
        bool b = _publish(agentId, user, CHANNEL_PAYMENTS, received, false);
        if (!a && !b) revert NothingToPublish();
    }

    // ------------------------------------------------------------------
    // Internals
    // ------------------------------------------------------------------

    function _isStale(Snapshot storage snap, uint256 value) internal view returns (bool) {
        return value > 0 && (snap.feedbackIndex == 0 || snap.value != value);
    }

    /// @dev Verifies the subject owns the agent. A nonexistent agent id
    ///      surfaces as AgentNotOwned, not as the registry's raw revert.
    function _requireOwnership(address user, uint256 agentId) internal view {
        address owner;
        try identityRegistry.ownerOf(agentId) returns (address o) {
            owner = o;
        } catch {
            revert AgentNotOwned(agentId, user);
        }
        if (owner != user) revert AgentNotOwned(agentId, user);
    }

    /// @dev Writes one feedback entry through the Reputation Registry
    ///      and records it as the channel's latest snapshot. In strict
    ///      mode a no-op reverts (NoReputation / AlreadyCurrent); in
    ///      lenient mode it is skipped and false is returned.
    function _publish(uint256 agentId, address user, uint8 channel, uint256 value, bool strict)
        internal
        returns (bool published)
    {
        Snapshot storage snap = channel == CHANNEL_STREAK ? _streakSnapshots[agentId] : _paymentSnapshots[agentId];

        if (value == 0) {
            if (strict) revert NoReputation(channel);
            return false;
        }
        if (snap.feedbackIndex != 0 && snap.value == value) {
            if (strict) revert AlreadyCurrent(channel);
            return false;
        }
        if (value > uint256(int256(type(int128).max))) revert ValueTooLarge(value);

        (string memory tag1, string memory tag2) =
            channel == CHANNEL_STREAK ? (STREAK_TAG1, STREAK_TAG2) : (PAY_TAG1, PAY_TAG2);

        // feedbackHash commits to the exact attested data (channel tags,
        // agent, subject, value) so any reader can match the entry to
        // the on-chain state it was derived from. endpoint/feedbackURI
        // stay empty: the evidence lives on-chain in AgentStreak and
        // AgentPay, not in an off-chain file.
        bytes32 feedbackHash = keccak256(abi.encode(tag1, tag2, agentId, user, value));

        reputationRegistry.giveFeedback(agentId, int128(int256(value)), 0, tag1, tag2, "", "", feedbackHash);

        uint64 index = reputationRegistry.getLastIndex(agentId, address(this));
        snap.value = value;
        snap.feedbackIndex = index;

        emit ReputationPublished(agentId, user, channel, value, index);
        return true;
    }
}
