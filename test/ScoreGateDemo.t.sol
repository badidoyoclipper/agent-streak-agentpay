// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TestLite} from "./utils/TestLite.sol";
import {AgentStreak} from "../contracts/AgentStreak.sol";
import {ScoreGateDemo} from "../contracts/ScoreGateDemo.sol";
import {MockAgentId} from "./mocks/MockAgentId.sol";

contract ScoreGateDemoTest is TestLite {
    MockAgentId internal registry;
    AgentStreak internal streak;
    ScoreGateDemo internal gate;

    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    uint256 internal constant T0 = 1795132800; // 2026-11-20 00:00:00 UTC
    uint256 internal constant THRESHOLD = 3;

    event GasUsed(string what, uint256 gas);

    function setUp() public {
        vm.warp(T0);
        registry = new MockAgentId();
        registry.mint(alice);
        registry.mint(bob);
        streak = new AgentStreak(address(registry), true);
        gate = new ScoreGateDemo(address(streak), THRESHOLD);
    }

    function _checkInDays(address user, uint256 days_) internal {
        for (uint256 d = 0; d < days_; d++) {
            vm.warp(T0 + d * 1 days);
            vm.prank(user);
            streak.checkIn();
        }
    }

    function testLowScoreRejected() public {
        // No check-ins at all: score 0 < 3.
        assertFalse(gate.canClaim(alice), "cannot claim at score 0");
        vm.prank(alice);
        vm.expectRevert();
        gate.claimBadge();

        // One check-in: score 1, still below threshold.
        vm.prank(alice);
        streak.checkIn();
        assertEq(streak.getScore(alice), 1, "score 1 after one check-in");
        assertFalse(gate.canClaim(alice), "cannot claim at score 1");
        vm.prank(alice);
        vm.expectRevert();
        gate.claimBadge();
    }

    function testSufficientScoreCanClaim() public {
        _checkInDays(alice, 3); // scores 1, 2, 3 -> meets threshold exactly
        assertEq(streak.getScore(alice), 3, "score 3 after three days");
        assertTrue(gate.canClaim(alice), "can claim at threshold");

        vm.prank(alice);
        gate.claimBadge();

        assertTrue(gate.hasBadge(alice), "badge recorded");
        assertEq(gate.badgeCount(), 1, "badge count 1");
    }

    function testDoubleClaimReverts() public {
        _checkInDays(alice, 3);
        vm.startPrank(alice);
        gate.claimBadge();
        vm.expectRevert();
        gate.claimBadge();
        vm.stopPrank();
        assertEq(gate.badgeCount(), 1, "still exactly one badge");
    }

    function testUsersAreIndependent() public {
        _checkInDays(alice, 3);
        vm.prank(alice);
        gate.claimBadge();

        // Bob never checked in: still locked out even though a badge exists.
        assertFalse(gate.hasBadge(bob), "bob has no badge");
        vm.prank(bob);
        vm.expectRevert();
        gate.claimBadge();
    }

    function testOwnerCanRaiseThreshold() public {
        _checkInDays(alice, 7); // score 7 + 5 bonus = 12
        assertEq(streak.getScore(alice), 12, "score 12 after 7 days");
        assertTrue(gate.canClaim(alice), "claimable at threshold 3");

        gate.setThreshold(13); // test contract is the owner
        assertFalse(gate.canClaim(alice), "locked out at threshold 13");
        vm.prank(alice);
        vm.expectRevert();
        gate.claimBadge();

        gate.setThreshold(12);
        assertTrue(gate.canClaim(alice), "claimable again at threshold 12");
    }

    function testNonOwnerCannotSetThreshold() public {
        vm.prank(alice);
        vm.expectRevert();
        gate.setThreshold(1);
    }

    function testDeployGas() public {
        uint256 g0 = gasleft();
        ScoreGateDemo g = new ScoreGateDemo(address(streak), THRESHOLD);
        uint256 used = g0 - gasleft();
        emit GasUsed("ScoreGateDemo deploy", used);
        assertTrue(address(g) != address(0), "deployed");
    }
}
