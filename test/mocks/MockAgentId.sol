// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Test double for the SPACE ID Agent ID registry. An address
///         "holds an Agent ID" iff balanceOf > 0, mirroring the real
///         contract's documented check.
contract MockAgentId {
    mapping(address => uint256) private _balances;

    function mint(address to) external {
        _balances[to] = 1;
    }

    function balanceOf(address owner) external view returns (uint256) {
        return _balances[owner];
    }
}
