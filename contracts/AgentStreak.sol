// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IAgentIdRegistry} from "./interfaces/IAgentIdRegistry.sol";

/// @title AgentStreak
/// @notice Daily check-in and streak reputation for Binance Agent ID holders.
///
/// Agent ID is a non-transferable, one-per-user on-chain identity (name.ai)
/// issued to Binance Agentic Wallets. Because an Agent ID cannot be bought,
/// sold, or duplicated, activity recorded against the holding address is a
/// sybil-resistant reputation signal. AgentStreak turns that signal into a
/// public, composable primitive: any other contract can read a holder's
/// current streak, longest streak, total check-ins, score, and liveness via
/// the view functions below — no registration, no API key, no off-chain trust.
///
/// Rules:
/// - One check-in per address per UTC day.
/// - Consecutive days build the current streak; missing a day resets it to 1
///   on the next check-in (the longest streak is preserved).
/// - Score: 1 point per check-in, plus a 5-point bonus every time the
///   current streak reaches a multiple of 7 days.
///
/// Safety properties:
/// - Check-in is a plain transaction sent and confirmed by the holder's own
///   wallet. This contract never executes anything on a user's behalf.
/// - The contract holds no user funds and has no owner, no admin functions,
///   no pause, no withdrawal, and no upgrade path. The Agent ID registry
///   address and the gate flag are fixed immutably at deployment.
contract AgentStreak {
    /// @notice The official Agent ID registry (SPACE ID Agent ID, ERC-721).
    IAgentIdRegistry public immutable agentIdRegistry;

    /// @notice When true, only Agent ID holders may check in.
    bool public immutable gateEnabled;

    uint256 public constant STREAK_BONUS_INTERVAL = 7;
    uint256 public constant STREAK_BONUS_POINTS = 5;

    struct StreakInfo {
        uint64 lastCheckInDay; // UTC day number (timestamp / 86400) of last check-in
        uint64 currentStreak; // consecutive days up to and including lastCheckInDay
        uint64 longestStreak;
        uint64 totalCheckIns;
        uint64 points;
    }

    mapping(address => StreakInfo) private _streaks;

    /// @notice Number of distinct addresses that have ever checked in.
    uint256 public totalUsers;

    /// @notice Total check-ins recorded across all users.
    uint256 public totalCheckInsAll;

    event CheckedIn(address indexed user, uint256 day, uint256 currentStreak, uint256 points);

    error ZeroAddress();
    error NotAgentIdHolder();
    error AlreadyCheckedInToday();

    constructor(address registry_, bool gateEnabled_) {
        if (registry_ == address(0)) revert ZeroAddress();
        agentIdRegistry = IAgentIdRegistry(registry_);
        gateEnabled = gateEnabled_;
    }

    // ------------------------------------------------------------------
    // Core action
    // ------------------------------------------------------------------

    /// @notice Record today's check-in for the caller. One per UTC day.
    function checkIn() external {
        if (gateEnabled && !isAgentIdHolder(msg.sender)) revert NotAgentIdHolder();

        uint256 today = _today();
        StreakInfo storage s = _streaks[msg.sender];

        if (s.totalCheckIns > 0 && uint256(s.lastCheckInDay) == today) {
            revert AlreadyCheckedInToday();
        }

        if (s.totalCheckIns == 0) {
            totalUsers += 1;
            s.currentStreak = 1;
        } else if (today == uint256(s.lastCheckInDay) + 1) {
            s.currentStreak += 1;
        } else {
            // A day (or more) was missed: the streak restarts, history is kept.
            s.currentStreak = 1;
        }

        if (s.currentStreak > s.longestStreak) s.longestStreak = s.currentStreak;

        s.totalCheckIns += 1;
        s.lastCheckInDay = uint64(today);

        uint256 gained = 1;
        if (s.currentStreak % STREAK_BONUS_INTERVAL == 0) gained += STREAK_BONUS_POINTS;
        s.points += uint64(gained);

        totalCheckInsAll += 1;
        emit CheckedIn(msg.sender, today, s.currentStreak, s.points);
    }

    // ------------------------------------------------------------------
    // Public reputation views — the identity primitive other dApps read
    // ------------------------------------------------------------------

    /// @notice True if the address currently holds an Agent ID, per the
    ///         official registry check documented by Binance.
    function isAgentIdHolder(address user) public view returns (bool) {
        return agentIdRegistry.balanceOf(user) > 0;
    }

    /// @notice Effective current streak. Returns 0 once a full day has been
    ///         missed, even before the user's next check-in resets it.
    function getStreak(address user) public view returns (uint256) {
        StreakInfo storage s = _streaks[user];
        if (s.totalCheckIns == 0) return 0;
        if (_today() > uint256(s.lastCheckInDay) + 1) return 0;
        return s.currentStreak;
    }

    function getLongestStreak(address user) external view returns (uint256) {
        return _streaks[user].longestStreak;
    }

    function getTotalCheckIns(address user) external view returns (uint256) {
        return _streaks[user].totalCheckIns;
    }

    /// @notice Reputation score: 1 point per check-in + 5-point bonus at
    ///         every 7-day streak milestone.
    function getScore(address user) external view returns (uint256) {
        return _streaks[user].points;
    }

    /// @notice True if the user checked in today or yesterday (streak alive).
    function isActive(address user) public view returns (bool) {
        StreakInfo storage s = _streaks[user];
        return s.totalCheckIns > 0 && _today() <= uint256(s.lastCheckInDay) + 1;
    }

    function hasCheckedInToday(address user) external view returns (bool) {
        StreakInfo storage s = _streaks[user];
        return s.totalCheckIns > 0 && uint256(s.lastCheckInDay) == _today();
    }

    /// @notice Full reputation snapshot in a single call, for other contracts
    ///         and indexers.
    /// @return currentStreak Effective streak (0 if lapsed)
    /// @return longestStreak Best streak ever achieved
    /// @return totalCheckIns Lifetime check-in count
    /// @return score Accumulated reputation score
    /// @return active Whether the streak is still alive
    function getReputation(address user)
        external
        view
        returns (uint256 currentStreak, uint256 longestStreak, uint256 totalCheckIns, uint256 score, bool active)
    {
        StreakInfo storage s = _streaks[user];
        return (getStreak(user), s.longestStreak, s.totalCheckIns, s.points, isActive(user));
    }

    /// @notice Raw stored record for an address.
    function getStreakInfo(address user) external view returns (StreakInfo memory) {
        return _streaks[user];
    }

    /// @notice Current UTC day number used by the check-in logic.
    function today() external view returns (uint256) {
        return _today();
    }

    function _today() internal view returns (uint256) {
        return block.timestamp / 1 days;
    }
}
