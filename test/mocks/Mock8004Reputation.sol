// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IMock8004Identity {
    function isAuthorizedOrOwner(address spender, uint256 agentId) external view returns (bool);
}

/// @notice Test double for the ERC-8004 Reputation Registry, mirroring
///         the deployed v2.0.0 reference implementation:
///         - giveFeedback reverts for valueDecimals > 18, |value| > 1e38,
///           a nonexistent agent, and SELF-FEEDBACK (caller is the
///           agent's owner/operator/approved, via the Identity
///           Registry's isAuthorizedOrOwner);
///         - entries are 1-indexed per (agentId, clientAddress) and
///           append-only; only the giver can revoke their own entry;
///         - getSummary reverts on an empty client list and otherwise
///           averages non-revoked, tag-matching entries with the same
///           WAD-normalization + mode-decimals algorithm as the
///           reference contract (copied semantics, MIT);
///         - readAllFeedback is omitted (unused by this project).
contract Mock8004Reputation {
    struct Feedback {
        int128 value;
        uint8 valueDecimals;
        bool isRevoked;
        string tag1;
        string tag2;
    }

    int128 private constant MAX_ABS_VALUE = 1e38;

    address private immutable _identityRegistry;

    mapping(uint256 => mapping(address => mapping(uint64 => Feedback))) private _feedback;
    mapping(uint256 => mapping(address => uint64)) private _lastIndex;
    mapping(uint256 => address[]) private _clients;
    mapping(uint256 => mapping(address => bool)) private _clientExists;

    event NewFeedback(uint256 indexed agentId, address indexed clientAddress, uint64 feedbackIndex, int128 value);

    constructor(address identityRegistry_) {
        _identityRegistry = identityRegistry_;
    }

    function getIdentityRegistry() external view returns (address) {
        return _identityRegistry;
    }

    function giveFeedback(
        uint256 agentId,
        int128 value,
        uint8 valueDecimals,
        string calldata tag1,
        string calldata tag2,
        string calldata,
        string calldata,
        bytes32
    ) external {
        require(valueDecimals <= 18, "too many decimals");
        require(value >= -MAX_ABS_VALUE && value <= MAX_ABS_VALUE, "value too large");
        // Also reverts (via the identity registry) if the agent doesn't exist.
        require(!IMock8004Identity(_identityRegistry).isAuthorizedOrOwner(msg.sender, agentId), "Self-feedback not allowed");

        uint64 currentIndex = ++_lastIndex[agentId][msg.sender];
        _feedback[agentId][msg.sender][currentIndex] = Feedback({
            value: value,
            valueDecimals: valueDecimals,
            isRevoked: false,
            tag1: tag1,
            tag2: tag2
        });

        if (!_clientExists[agentId][msg.sender]) {
            _clients[agentId].push(msg.sender);
            _clientExists[agentId][msg.sender] = true;
        }

        emit NewFeedback(agentId, msg.sender, currentIndex, value);
    }

    function revokeFeedback(uint256 agentId, uint64 feedbackIndex) external {
        require(feedbackIndex > 0, "index must be > 0");
        require(feedbackIndex <= _lastIndex[agentId][msg.sender], "index out of bounds");
        require(!_feedback[agentId][msg.sender][feedbackIndex].isRevoked, "Already revoked");
        _feedback[agentId][msg.sender][feedbackIndex].isRevoked = true;
    }

    function getLastIndex(uint256 agentId, address clientAddress) external view returns (uint64) {
        return _lastIndex[agentId][clientAddress];
    }

    function readFeedback(uint256 agentId, address clientAddress, uint64 feedbackIndex)
        external
        view
        returns (int128 value, uint8 valueDecimals, string memory tag1, string memory tag2, bool isRevoked)
    {
        require(feedbackIndex > 0, "index must be > 0");
        require(feedbackIndex <= _lastIndex[agentId][clientAddress], "index out of bounds");
        Feedback storage f = _feedback[agentId][clientAddress][feedbackIndex];
        return (f.value, f.valueDecimals, f.tag1, f.tag2, f.isRevoked);
    }

    function getClients(uint256 agentId) external view returns (address[] memory) {
        return _clients[agentId];
    }

    struct SummaryAcc {
        uint64 count;
        int256 sum;
        uint64[19] counts;
    }

    /// @dev Faithful copy of the reference getSummary algorithm
    ///      (accumulator struct only to satisfy the stack limit).
    function getSummary(uint256 agentId, address[] calldata clientAddresses, string calldata tag1, string calldata tag2)
        external
        view
        returns (uint64 count, int128 summaryValue, uint8 summaryValueDecimals)
    {
        require(clientAddresses.length > 0, "clientAddresses required");

        SummaryAcc memory acc;
        bytes32 tag1Hash = keccak256(bytes(tag1));
        bytes32 tag2Hash = keccak256(bytes(tag2));

        for (uint256 i; i < clientAddresses.length; i++) {
            _accumulate(acc, agentId, clientAddresses[i], tag1Hash, tag2Hash);
        }

        count = acc.count;
        if (count == 0) {
            return (0, 0, 0);
        }

        summaryValueDecimals = _modeDecimals(acc.counts);
        int256 avgWad = acc.sum / int256(uint256(count));
        summaryValue = int128(avgWad / int256(10 ** uint256(18 - summaryValueDecimals)));
    }

    function _accumulate(SummaryAcc memory acc, uint256 agentId, address client, bytes32 tag1Hash, bytes32 tag2Hash)
        internal
        view
    {
        bytes32 emptyHash = keccak256(bytes(""));
        uint64 lastIdx = _lastIndex[agentId][client];
        for (uint64 j = 1; j <= lastIdx; j++) {
            Feedback storage fb = _feedback[agentId][client][j];
            if (fb.isRevoked) continue;
            if (emptyHash != tag1Hash && tag1Hash != keccak256(bytes(fb.tag1))) continue;
            if (emptyHash != tag2Hash && tag2Hash != keccak256(bytes(fb.tag2))) continue;

            acc.sum += fb.value * int256(10 ** uint256(18 - fb.valueDecimals));
            acc.counts[fb.valueDecimals]++;
            acc.count++;
        }
    }

    function _modeDecimals(uint64[19] memory counts) internal pure returns (uint8 mode) {
        uint64 best;
        for (uint8 d; d <= 18; d++) {
            if (counts[d] > best) {
                best = counts[d];
                mode = d;
            }
        }
    }

    function getVersion() external pure returns (string memory) {
        return "2.0.0";
    }
}
