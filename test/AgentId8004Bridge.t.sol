// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TestLite} from "./utils/TestLite.sol";
import {AgentStreak} from "../contracts/AgentStreak.sol";
import {AgentPay} from "../contracts/AgentPay.sol";
import {AgentId8004Bridge} from "../contracts/AgentId8004Bridge.sol";
import {MockAgentId} from "./mocks/MockAgentId.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {Mock8004Identity} from "./mocks/Mock8004Identity.sol";
import {Mock8004Reputation} from "./mocks/Mock8004Reputation.sol";

contract AgentId8004BridgeTest is TestLite {
    MockAgentId internal registry; // SPACE ID Agent ID (this project's gate)
    MockERC20 internal usdt;
    AgentStreak internal streak;
    AgentPay internal pay;

    Mock8004Identity internal id8004;
    Mock8004Reputation internal rep8004;
    AgentId8004Bridge internal bridge;

    address internal alice = address(0xA11CE); // Agent ID holder + 8004 agent 0
    address internal bob = address(0xB0B); // Agent ID holder, funded payer
    address internal carol = address(0xCA801); // Agent ID holder, 8004 agent 1, no reputation
    address internal stranger = address(0x57A9); // holds nothing

    // A fixed UTC midnight so day math is exact: 2026-11-20 00:00:00 UTC.
    uint256 internal constant T0 = 1795132800;

    event GasUsed(string what, uint256 gas);

    function setUp() public {
        vm.warp(T0);
        registry = new MockAgentId();
        registry.mint(alice);
        registry.mint(bob);
        registry.mint(carol);

        usdt = new MockERC20();
        usdt.mint(bob, 1000 * 1e18);

        streak = new AgentStreak(address(registry), true);
        pay = new AgentPay(address(registry), true);

        id8004 = new Mock8004Identity();
        rep8004 = new Mock8004Reputation(address(id8004));
        bridge = new AgentId8004Bridge(address(id8004), address(rep8004), address(streak), address(pay));
    }

    // ---------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------

    function _register8004(address user, string memory uri) internal returns (uint256) {
        vm.prank(user);
        return id8004.register(uri);
    }

    function _checkIn(address user, uint256 dayOffset) internal {
        vm.warp(T0 + dayOffset * 1 days);
        vm.prank(user);
        streak.checkIn();
    }

    function _settlePaymentToAlice() internal {
        vm.prank(alice);
        uint256 id = pay.createRequest(address(usdt), 25 * 1e18, "bridge test payment");
        vm.startPrank(bob);
        usdt.approve(address(pay), 25 * 1e18);
        pay.payRequest(id);
        vm.stopPrank();
    }

    function _assertStrEq(string memory a, string memory b, string memory what) internal pure {
        assertTrue(keccak256(bytes(a)) == keccak256(bytes(b)), what);
    }

    function _bridgeClients() internal view returns (address[] memory clients) {
        clients = new address[](1);
        clients[0] = address(bridge);
    }

    // ---------------------------------------------------------------
    // Reads
    // ---------------------------------------------------------------

    function testRegistrationReads() public {
        assertFalse(bridge.isRegistered8004(alice), "alice not registered yet");
        assertEq(bridge.agentCount8004(alice), 0, "count 0 before");

        uint256 agentId = _register8004(alice, "ipfs://agent/alice");
        assertEq(agentId, 0, "first agent id is 0");

        assertTrue(bridge.isRegistered8004(alice), "alice registered");
        assertEq(bridge.agentCount8004(alice), 1, "count 1 after");
        assertFalse(bridge.isRegistered8004(carol), "carol never registered");
        assertFalse(bridge.isRegistered8004(stranger), "stranger never registered");

        assertTrue(bridge.ownsAgent8004(alice, 0), "alice owns agent 0");
        assertFalse(bridge.ownsAgent8004(bob, 0), "bob does not own agent 0");
        // Nonexistent agent ids are handled, not reverted on.
        assertFalse(bridge.ownsAgent8004(alice, 999), "nonexistent agent -> false");

        assertEq(bridge.getAgentWallet8004(0), alice, "verified wallet is the registrant");
        _assertStrEq(bridge.getAgentURI8004(0), "ipfs://agent/alice", "agent URI passthrough");
    }

    // ---------------------------------------------------------------
    // Publishing — streak channel
    // ---------------------------------------------------------------

    function testPublishStreakScore() public {
        _register8004(alice, "ipfs://agent/alice");
        _checkIn(alice, 0);
        _checkIn(alice, 1);
        _checkIn(alice, 2);
        assertEq(streak.getScore(alice), 3, "score is 3 after 3 check-ins");

        // A third party may trigger the publish; the bridge computes the
        // value itself, so the caller cannot influence it.
        vm.prank(bob);
        bridge.publishStreakScore(alice, 0);

        assertEq(rep8004.getLastIndex(0, address(bridge)), 1, "one feedback entry from bridge");
        (int128 value, uint8 decimals, string memory tag1, string memory tag2, bool revoked) =
            rep8004.readFeedback(0, address(bridge), 1);
        assertTrue(value == 3, "feedback value is the live score");
        assertEq(uint256(decimals), 0, "feedback decimals 0");
        _assertStrEq(tag1, "agentstreak", "tag1 is the source system");
        _assertStrEq(tag2, "score", "tag2 is the metric");
        assertFalse(revoked, "entry not revoked");

        (uint256 snapValue, uint64 snapIndex) = bridge.getPublishedSnapshot(0, bridge.CHANNEL_STREAK());
        assertEq(snapValue, 3, "snapshot value recorded");
        assertEq(uint256(snapIndex), 1, "snapshot index recorded");
    }

    function testPublishStreakUnchangedReverts() public {
        _register8004(alice, "");
        _checkIn(alice, 0);
        bridge.publishStreakScore(alice, 0);

        vm.expectRevert();
        bridge.publishStreakScore(alice, 0);
    }

    function testPublishStreakUpdatesAndSummaryAverages() public {
        _register8004(alice, "");
        _checkIn(alice, 0);
        _checkIn(alice, 1);
        _checkIn(alice, 2);
        bridge.publishStreakScore(alice, 0); // publishes 3 at index 1

        _checkIn(alice, 3); // score becomes 4
        bridge.publishStreakScore(alice, 0); // publishes 4 at index 2

        assertEq(rep8004.getLastIndex(0, address(bridge)), 2, "two snapshots published");
        (uint256 snapValue, uint64 snapIndex) = bridge.getPublishedSnapshot(0, bridge.CHANNEL_STREAK());
        assertEq(snapValue, 4, "latest snapshot is 4");
        assertEq(uint256(snapIndex), 2, "latest snapshot index 2");

        // The registry summary averages the bridge's snapshots:
        // (3 + 4) / 2 = 3.5, truncated to 3 at 0 decimals.
        (uint64 count, int128 summary, uint8 decimals) =
            bridge.getSummary8004(0, _bridgeClients(), "agentstreak", "score");
        assertEq(uint256(count), 2, "summary counts both snapshots");
        assertTrue(summary == 3, "summary is the truncated average");
        assertEq(uint256(decimals), 0, "summary decimals 0");
    }

    // ---------------------------------------------------------------
    // Publishing — payments channel and publishAll
    // ---------------------------------------------------------------

    function testPublishPaymentsReceived() public {
        _register8004(alice, "");
        _settlePaymentToAlice();

        bridge.publishPaymentsReceived(alice, 0);

        assertEq(rep8004.getLastIndex(0, address(bridge)), 1, "one feedback entry");
        (int128 value,, string memory tag1, string memory tag2,) = rep8004.readFeedback(0, address(bridge), 1);
        assertTrue(value == 1, "feedback value is payments received");
        _assertStrEq(tag1, "agentpay", "tag1 agentpay");
        _assertStrEq(tag2, "paymentsReceived", "tag2 paymentsReceived");

        (uint256 snapValue, uint64 snapIndex) = bridge.getPublishedSnapshot(0, bridge.CHANNEL_PAYMENTS());
        assertEq(snapValue, 1, "payments snapshot value");
        assertEq(uint256(snapIndex), 1, "payments snapshot index");
    }

    function testPublishAllPublishesBothChannels() public {
        _register8004(alice, "");
        _checkIn(alice, 0); // score 1
        _settlePaymentToAlice(); // paymentsReceived 1

        vm.prank(carol); // any caller
        bridge.publishAll(alice, 0);

        (uint256 sVal, uint64 sIdx) = bridge.getPublishedSnapshot(0, bridge.CHANNEL_STREAK());
        (uint256 pVal, uint64 pIdx) = bridge.getPublishedSnapshot(0, bridge.CHANNEL_PAYMENTS());
        assertEq(sVal, 1, "streak snapshot value");
        assertEq(pVal, 1, "payments snapshot value");
        // The registry indexes per (agent, client) across all tags:
        // streak took index 1, payments index 2.
        assertEq(uint256(sIdx), 1, "streak snapshot index");
        assertEq(uint256(pIdx), 2, "payments snapshot index");

        // Nothing new to say -> publishAll reverts.
        vm.expectRevert();
        bridge.publishAll(alice, 0);
    }

    function testPreviewPublish() public {
        _register8004(alice, "");
        _checkIn(alice, 0);
        _checkIn(alice, 1);

        (uint256 score, uint256 received, bool sStale, bool pStale) = bridge.previewPublish(alice, 0);
        assertEq(score, 2, "preview score");
        assertEq(received, 0, "preview received");
        assertTrue(sStale, "streak channel stale before publish");
        assertFalse(pStale, "payments channel not stale at zero");

        bridge.publishStreakScore(alice, 0);
        (, , sStale, pStale) = bridge.previewPublish(alice, 0);
        assertFalse(sStale, "streak channel current after publish");
        assertFalse(pStale, "payments channel still not stale");
    }

    // ---------------------------------------------------------------
    // Guards
    // ---------------------------------------------------------------

    function testPublishRevertsForNonOwner() public {
        _register8004(alice, "");
        _checkIn(bob, 0); // bob has reputation of his own...

        // ...but agent 0 belongs to alice, so bob cannot be its subject.
        vm.expectRevert();
        bridge.publishStreakScore(bob, 0);
    }

    function testPublishRevertsForNonexistentAgent() public {
        _checkIn(alice, 0);
        vm.expectRevert();
        bridge.publishStreakScore(alice, 42);
    }

    function testPublishRevertsWithoutReputation() public {
        uint256 carolAgent = _register8004(carol, "");
        assertEq(carolAgent, 0, "carol is the first registrant in this test");

        vm.expectRevert();
        bridge.publishStreakScore(carol, carolAgent);

        vm.expectRevert();
        bridge.publishPaymentsReceived(carol, carolAgent);

        vm.expectRevert();
        bridge.publishAll(carol, carolAgent);
    }

    function testSummaryRevertsOnEmptyClients() public {
        _register8004(alice, "");
        // Registry rule (v2.0.0): getSummary requires a non-empty client
        // list. The bridge passes the call through honestly.
        vm.expectRevert();
        bridge.getSummary8004(0, new address[](0), "", "");
    }

    function testRegistryRejectsSelfFeedback() public {
        // Standard rule, exercised at the registry level: an agent's
        // owner can never author feedback about their own agent. The
        // bridge owns no agent in production, so it can never be the
        // blocked author — this test pins the rule itself.
        vm.prank(address(bridge));
        uint256 bridgeAgent = id8004.register();
        assertEq(bridgeAgent, 0, "bridge-owned agent id in this test");

        vm.prank(address(bridge));
        vm.expectRevert();
        rep8004.giveFeedback(bridgeAgent, 5, 0, "agentstreak", "score", "", "", bytes32(0));
    }

    function testDeployGas() public {
        uint256 g0 = gasleft();
        AgentId8004Bridge b =
            new AgentId8004Bridge(address(id8004), address(rep8004), address(streak), address(pay));
        uint256 used = g0 - gasleft();
        emit GasUsed("AgentId8004Bridge deploy", used);
        assertTrue(address(b) != address(0), "deployed");
    }
}
