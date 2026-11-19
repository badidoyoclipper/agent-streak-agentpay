// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TestLite} from "./utils/TestLite.sol";
import {AgentStreak} from "../contracts/AgentStreak.sol";
import {MockAgentId} from "./mocks/MockAgentId.sol";

contract AgentStreakTest is TestLite {
    MockAgentId internal registry;
    AgentStreak internal streak; // gate enabled
    AgentStreak internal openStreak; // gate disabled

    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);
    address internal stranger = address(0x57A9);

    // A fixed UTC midnight so day math is exact: 2026-11-20 00:00:00 UTC.
    uint256 internal constant T0 = 1795132800;

    event GasUsed(string what, uint256 gas);

    function setUp() public {
        vm.warp(T0);
        registry = new MockAgentId();
        registry.mint(alice);
        registry.mint(bob);
        streak = new AgentStreak(address(registry), true);
        openStreak = new AgentStreak(address(registry), false);
    }

    function testFirstCheckIn() public {
        vm.prank(alice);
        streak.checkIn();

        assertEq(streak.getStreak(alice), 1, "streak after first check-in");
        assertEq(streak.getLongestStreak(alice), 1, "longest after first");
        assertEq(streak.getTotalCheckIns(alice), 1, "total after first");
        assertEq(streak.getScore(alice), 1, "score after first");
        assertTrue(streak.isActive(alice), "active after first");
        assertTrue(streak.hasCheckedInToday(alice), "checked in today");
        assertEq(streak.totalUsers(), 1, "totalUsers");
        assertEq(streak.totalCheckInsAll(), 1, "totalCheckInsAll");
    }

    function testDoubleCheckInSameDayReverts() public {
        vm.startPrank(alice);
        streak.checkIn();
        vm.expectRevert();
        streak.checkIn();
        vm.stopPrank();
    }

    function testNonHolderCannotCheckInWhenGated() public {
        vm.prank(stranger);
        vm.expectRevert();
        streak.checkIn();
    }

    function testNonHolderCanCheckInWhenGateDisabled() public {
        vm.prank(stranger);
        openStreak.checkIn();
        assertEq(openStreak.getTotalCheckIns(stranger), 1, "open gate total");
    }

    function testIsAgentIdHolder() public {
        assertTrue(streak.isAgentIdHolder(alice), "alice holds");
        assertFalse(streak.isAgentIdHolder(stranger), "stranger does not hold");
    }

    function testStreakContinuesNextDay() public {
        vm.prank(alice);
        streak.checkIn();

        vm.warp(T0 + 1 days);
        vm.prank(alice);
        streak.checkIn();

        assertEq(streak.getStreak(alice), 2, "streak day 2");
        assertEq(streak.getLongestStreak(alice), 2, "longest day 2");
        assertEq(streak.getTotalCheckIns(alice), 2, "total day 2");
        assertEq(streak.getScore(alice), 2, "score day 2");
    }

    function testStreakBreaksAfterGap() public {
        vm.prank(alice);
        streak.checkIn();

        vm.warp(T0 + 1 days);
        vm.prank(alice);
        streak.checkIn();
        assertEq(streak.getStreak(alice), 2, "streak before gap");

        // Skip a full day: streak must read as lapsed before the next check-in.
        vm.warp(T0 + 3 days);
        assertEq(streak.getStreak(alice), 0, "streak lapsed after gap");
        assertFalse(streak.isActive(alice), "inactive after gap");

        vm.prank(alice);
        streak.checkIn();
        assertEq(streak.getStreak(alice), 1, "streak restarts at 1");
        assertEq(streak.getLongestStreak(alice), 2, "longest preserved");
        assertEq(streak.getTotalCheckIns(alice), 3, "total keeps counting");
    }

    function testWeeklyMilestoneBonus() public {
        for (uint256 d = 0; d < 7; d++) {
            vm.warp(T0 + d * 1 days);
            vm.prank(alice);
            streak.checkIn();
        }
        assertEq(streak.getStreak(alice), 7, "7-day streak");
        // 7 check-ins * 1 point + 5-point milestone bonus at day 7.
        assertEq(streak.getScore(alice), 12, "score with weekly bonus");
    }

    function testUsersAreIndependent() public {
        vm.prank(alice);
        streak.checkIn();
        vm.prank(bob);
        streak.checkIn();
        assertEq(streak.totalUsers(), 2, "two users");

        vm.warp(T0 + 1 days);
        vm.prank(bob);
        streak.checkIn();
        assertEq(streak.getStreak(bob), 2, "bob streak 2");
        assertEq(streak.getStreak(alice), 1, "alice streak still 1 (checked yesterday)");
    }

    function testReputationTuple() public {
        vm.prank(alice);
        streak.checkIn();
        (uint256 cur, uint256 longest, uint256 total, uint256 score, bool active) = streak.getReputation(alice);
        assertEq(cur, 1, "tuple current");
        assertEq(longest, 1, "tuple longest");
        assertEq(total, 1, "tuple total");
        assertEq(score, 1, "tuple score");
        assertTrue(active, "tuple active");
    }

    function testDeployGas() public {
        uint256 g0 = gasleft();
        AgentStreak s = new AgentStreak(address(registry), true);
        uint256 used = g0 - gasleft();
        emit GasUsed("AgentStreak deploy", used);
        assertTrue(address(s) != address(0), "deployed");
    }
}
