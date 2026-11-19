// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Minimal, dependency-free test harness: just the Foundry cheatcodes
///         this suite uses, plus assertion helpers. Avoids a forge-std
///         checkout so the repo builds with nothing but the Foundry toolchain.
interface VmLite {
    function warp(uint256 newTimestamp) external;
    function prank(address msgSender) external;
    function startPrank(address msgSender) external;
    function stopPrank() external;
    function expectRevert() external;
}

abstract contract TestLite {
    VmLite internal constant vm = VmLite(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    function assertEq(uint256 a, uint256 b, string memory what) internal pure {
        if (a != b) {
            revert(string.concat("assertEq failed [", what, "]: ", _u2s(a), " != ", _u2s(b)));
        }
    }

    function assertEq(address a, address b, string memory what) internal pure {
        if (a != b) revert(string.concat("assertEq failed [", what, "] (address)"));
    }

    function assertTrue(bool cond, string memory what) internal pure {
        if (!cond) revert(string.concat("assertTrue failed [", what, "]"));
    }

    function assertFalse(bool cond, string memory what) internal pure {
        if (cond) revert(string.concat("assertFalse failed [", what, "]"));
    }

    function _u2s(uint256 v) internal pure returns (string memory) {
        if (v == 0) return "0";
        uint256 len;
        uint256 t = v;
        while (t > 0) {
            len++;
            t /= 10;
        }
        bytes memory out = new bytes(len);
        while (v > 0) {
            out[--len] = bytes1(uint8(48 + (v % 10)));
            v /= 10;
        }
        return string(out);
    }
}
