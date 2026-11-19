// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IAgentIdRegistry} from "./interfaces/IAgentIdRegistry.sol";
import {IERC20Minimal} from "./interfaces/IERC20Minimal.sol";

/// @title AgentPay
/// @notice Payment requests between Agent ID holders on BNB Chain.
///
/// An Agent ID holder (an AI agent's wallet, identified by its name.ai)
/// creates a payment request: token, amount, short memo. Any payer can then
/// settle the request in one transaction. Funds move directly from payer to
/// payee via ERC-20 transferFrom — this contract never takes custody, never
/// holds a balance, and cannot redirect a payment. Every settlement builds a
/// public, on-chain payment reputation for both sides: how many payments an
/// address has sent and received, and its settled volume per token.
///
/// Why Agent ID matters here: requests can only be created by verified
/// Agent ID holders (checked against the official SPACE ID Agent ID registry
/// documented by Binance), so a payment link is anchored to a unique,
/// non-transferable agent identity instead of an anonymous address.
///
/// Safety properties:
/// - Creating, paying, and cancelling are plain transactions that each user
///   sends and confirms from their own wallet. Nothing executes on anyone's
///   behalf; there are no scheduled or automatic transfers.
/// - The payer must explicitly approve this contract for the exact token in
///   their own wallet before paying (standard ERC-20 allowance flow).
/// - No owner, no admin functions, no pause, no withdrawal, no upgrade path.
///   The registry address and gate flag are fixed immutably at deployment.
/// - A payee cannot pay their own request (keeps reputation data honest).
contract AgentPay {
    /// @notice The official Agent ID registry (SPACE ID Agent ID, ERC-721).
    IAgentIdRegistry public immutable agentIdRegistry;

    /// @notice When true, only Agent ID holders may create payment requests.
    bool public immutable gateEnabled;

    uint256 public constant MAX_MEMO_LENGTH = 140;

    enum Status {
        Open,
        Paid,
        Cancelled
    }

    struct PaymentRequest {
        address payee; // creator of the request; receives the funds
        address token; // ERC-20 token to be paid in
        uint256 amount; // amount in the token's smallest unit
        string memo;
        address payer; // address(0) until settled
        Status status;
        uint64 createdAt;
        uint64 paidAt;
    }

    struct PaymentStats {
        uint256 requestsCreated;
        uint256 paymentsSent;
        uint256 paymentsReceived;
    }

    PaymentRequest[] private _requests;
    mapping(address => PaymentStats) private _stats;
    mapping(address => mapping(address => uint256)) private _volumeSent; // user => token => amount
    mapping(address => mapping(address => uint256)) private _volumeReceived; // user => token => amount
    mapping(address => uint256[]) private _payeeRequestIds;

    /// @notice Total requests ever settled.
    uint256 public totalSettled;

    event PaymentRequested(uint256 indexed id, address indexed payee, address indexed token, uint256 amount, string memo);
    event PaymentSettled(uint256 indexed id, address indexed payer, address indexed payee, address token, uint256 amount);
    event PaymentCancelled(uint256 indexed id, address indexed payee);

    error ZeroAddress();
    error NotAgentIdHolder();
    error InvalidAmount();
    error MemoTooLong();
    error RequestNotFound();
    error RequestNotOpen();
    error SelfPayment();
    error NotPayee();
    error TransferFailed();

    constructor(address registry_, bool gateEnabled_) {
        if (registry_ == address(0)) revert ZeroAddress();
        agentIdRegistry = IAgentIdRegistry(registry_);
        gateEnabled = gateEnabled_;
    }

    // ------------------------------------------------------------------
    // Core actions
    // ------------------------------------------------------------------

    /// @notice Create a payment request. The caller is the payee and, when
    ///         the gate is enabled, must hold an Agent ID.
    /// @return id The new request id.
    function createRequest(address token, uint256 amount, string calldata memo) external returns (uint256 id) {
        if (gateEnabled && !isAgentIdHolder(msg.sender)) revert NotAgentIdHolder();
        if (token == address(0)) revert ZeroAddress();
        if (amount == 0) revert InvalidAmount();
        if (bytes(memo).length > MAX_MEMO_LENGTH) revert MemoTooLong();

        id = _requests.length;
        _requests.push(
            PaymentRequest({
                payee: msg.sender,
                token: token,
                amount: amount,
                memo: memo,
                payer: address(0),
                status: Status.Open,
                createdAt: uint64(block.timestamp),
                paidAt: 0
            })
        );
        _payeeRequestIds[msg.sender].push(id);
        _stats[msg.sender].requestsCreated += 1;

        emit PaymentRequested(id, msg.sender, token, amount, memo);
    }

    /// @notice Settle an open request. Pulls exactly the requested amount of
    ///         the request's token from the caller to the payee. The caller
    ///         must have approved this contract for at least that amount.
    function payRequest(uint256 id) external {
        PaymentRequest storage r = _request(id);
        if (r.status != Status.Open) revert RequestNotOpen();
        if (msg.sender == r.payee) revert SelfPayment();

        // Effects before interaction.
        r.status = Status.Paid;
        r.payer = msg.sender;
        r.paidAt = uint64(block.timestamp);

        _stats[msg.sender].paymentsSent += 1;
        _stats[r.payee].paymentsReceived += 1;
        _volumeSent[msg.sender][r.token] += r.amount;
        _volumeReceived[r.payee][r.token] += r.amount;
        totalSettled += 1;

        _safeTransferFrom(r.token, msg.sender, r.payee, r.amount);

        emit PaymentSettled(id, msg.sender, r.payee, r.token, r.amount);
    }

    /// @notice Cancel an open request. Only the payee who created it.
    function cancelRequest(uint256 id) external {
        PaymentRequest storage r = _request(id);
        if (msg.sender != r.payee) revert NotPayee();
        if (r.status != Status.Open) revert RequestNotOpen();

        r.status = Status.Cancelled;
        emit PaymentCancelled(id, msg.sender);
    }

    // ------------------------------------------------------------------
    // Views
    // ------------------------------------------------------------------

    /// @notice True if the address currently holds an Agent ID, per the
    ///         official registry check documented by Binance.
    function isAgentIdHolder(address user) public view returns (bool) {
        return agentIdRegistry.balanceOf(user) > 0;
    }

    function requestCount() external view returns (uint256) {
        return _requests.length;
    }

    function getRequest(uint256 id) external view returns (PaymentRequest memory) {
        return _request(id);
    }

    /// @notice All request ids created by a payee, oldest first.
    function getPayeeRequestIds(address payee) external view returns (uint256[] memory) {
        return _payeeRequestIds[payee];
    }

    function getStats(address user) external view returns (PaymentStats memory) {
        return _stats[user];
    }

    function getVolumeSent(address user, address token) external view returns (uint256) {
        return _volumeSent[user][token];
    }

    function getVolumeReceived(address user, address token) external view returns (uint256) {
        return _volumeReceived[user][token];
    }

    // ------------------------------------------------------------------
    // Internals
    // ------------------------------------------------------------------

    function _request(uint256 id) internal view returns (PaymentRequest storage) {
        if (id >= _requests.length) revert RequestNotFound();
        return _requests[id];
    }

    /// @dev transferFrom that also tolerates ERC-20 tokens which return no
    ///      boolean (legacy style). Reverts on any failure, which rolls back
    ///      the state changes made in payRequest.
    function _safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        (bool ok, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20Minimal.transferFrom.selector, from, to, amount));
        if (!ok || (data.length > 0 && !abi.decode(data, (bool)))) revert TransferFailed();
    }
}
