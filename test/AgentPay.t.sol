// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TestLite} from "./utils/TestLite.sol";
import {AgentPay} from "../contracts/AgentPay.sol";
import {MockAgentId} from "./mocks/MockAgentId.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract AgentPayTest is TestLite {
    MockAgentId internal registry;
    MockERC20 internal usdt;
    AgentPay internal pay;

    address internal agent = address(0xA6E77); // Agent ID holder, the payee
    address internal payer; // funded with tokens in setUp; holds no Agent ID
    address internal carol = address(0xCA801);

    uint256 internal constant AMOUNT = 25 * 1e18; // 25 mUSDT

    event GasUsed(string what, uint256 gas);

    function setUp() public {
        registry = new MockAgentId();
        registry.mint(agent);
        registry.mint(carol);
        usdt = new MockERC20();
        pay = new AgentPay(address(registry), true);

        payer = address(0xBEEF);
        usdt.mint(payer, 1000 * 1e18);
        usdt.mint(carol, 1000 * 1e18);
    }

    function _createFromAgent() internal returns (uint256 id) {
        vm.prank(agent);
        id = pay.createRequest(address(usdt), AMOUNT, "clip editing, 3 videos");
    }

    function testCreateRequest() public {
        uint256 id = _createFromAgent();
        assertEq(id, 0, "first id is 0");
        assertEq(pay.requestCount(), 1, "request count");

        AgentPay.PaymentRequest memory r = pay.getRequest(id);
        assertEq(r.payee, agent, "payee is creator");
        assertEq(r.token, address(usdt), "token recorded");
        assertEq(r.amount, AMOUNT, "amount recorded");
        assertEq(r.payer, address(0), "payer unset");
        assertTrue(r.status == AgentPay.Status.Open, "status open");

        assertEq(pay.getStats(agent).requestsCreated, 1, "creator stat");
        uint256[] memory ids = pay.getPayeeRequestIds(agent);
        assertEq(ids.length, 1, "payee id list length");
        assertEq(ids[0], 0, "payee id list content");
    }

    function testNonHolderCannotCreate() public {
        vm.prank(payer); // payer holds tokens but no Agent ID
        vm.expectRevert();
        pay.createRequest(address(usdt), AMOUNT, "should fail");
    }

    function testZeroAmountReverts() public {
        vm.prank(agent);
        vm.expectRevert();
        pay.createRequest(address(usdt), 0, "zero");
    }

    function testPayRequestSettlesAndBuildsReputation() public {
        uint256 id = _createFromAgent();

        vm.startPrank(payer);
        usdt.approve(address(pay), AMOUNT);
        pay.payRequest(id);
        vm.stopPrank();

        // Funds moved directly payer -> payee; the contract holds nothing.
        assertEq(usdt.balanceOf(agent), AMOUNT, "payee received");
        assertEq(usdt.balanceOf(payer), 1000 * 1e18 - AMOUNT, "payer debited");
        assertEq(usdt.balanceOf(address(pay)), 0, "contract holds nothing");

        AgentPay.PaymentRequest memory r = pay.getRequest(id);
        assertTrue(r.status == AgentPay.Status.Paid, "status paid");
        assertEq(r.payer, payer, "payer recorded");

        assertEq(pay.getStats(payer).paymentsSent, 1, "payer sent count");
        assertEq(pay.getStats(agent).paymentsReceived, 1, "payee received count");
        assertEq(pay.getVolumeSent(payer, address(usdt)), AMOUNT, "volume sent");
        assertEq(pay.getVolumeReceived(agent, address(usdt)), AMOUNT, "volume received");
        assertEq(pay.totalSettled(), 1, "total settled");
    }

    function testPayWithoutAllowanceReverts() public {
        uint256 id = _createFromAgent();
        vm.prank(payer);
        vm.expectRevert();
        pay.payRequest(id);
        // Status must be untouched after the failed payment.
        AgentPay.PaymentRequest memory r = pay.getRequest(id);
        assertTrue(r.status == AgentPay.Status.Open, "still open after failed pay");
    }

    function testPayTwiceReverts() public {
        uint256 id = _createFromAgent();
        vm.startPrank(payer);
        usdt.approve(address(pay), AMOUNT * 2);
        pay.payRequest(id);
        vm.expectRevert();
        pay.payRequest(id);
        vm.stopPrank();
    }

    function testSelfPaymentReverts() public {
        uint256 id = _createFromAgent();
        usdt.mint(agent, AMOUNT);
        vm.startPrank(agent);
        usdt.approve(address(pay), AMOUNT);
        vm.expectRevert();
        pay.payRequest(id);
        vm.stopPrank();
    }

    function testCancelByPayee() public {
        uint256 id = _createFromAgent();
        vm.prank(agent);
        pay.cancelRequest(id);
        AgentPay.PaymentRequest memory r = pay.getRequest(id);
        assertTrue(r.status == AgentPay.Status.Cancelled, "status cancelled");
    }

    function testPayCancelledReverts() public {
        uint256 id = _createFromAgent();
        vm.prank(agent);
        pay.cancelRequest(id);

        vm.startPrank(payer);
        usdt.approve(address(pay), AMOUNT);
        vm.expectRevert();
        pay.payRequest(id);
        vm.stopPrank();
    }

    function testCancelByNonPayeeReverts() public {
        uint256 id = _createFromAgent();
        vm.prank(carol);
        vm.expectRevert();
        pay.cancelRequest(id);
    }

    function testGetNonexistentRequestReverts() public {
        vm.expectRevert();
        pay.getRequest(999);
    }

    function testDeployGas() public {
        uint256 g0 = gasleft();
        AgentPay p = new AgentPay(address(registry), true);
        uint256 used = g0 - gasleft();
        emit GasUsed("AgentPay deploy", used);
        assertTrue(address(p) != address(0), "deployed");
    }
}
