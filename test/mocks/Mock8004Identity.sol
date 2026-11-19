// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Test double for the ERC-8004 Identity Registry, mirroring the
///         deployed v2.0.0 reference implementation's observable
///         behavior for the surface this project consumes:
///         - agent ids are sequential, starting at 0;
///         - register() mints to the caller and records the caller as
///           the agent's verified wallet ("agentWallet");
///         - ownerOf reverts for nonexistent ids;
///         - isAuthorizedOrOwner is simplified to owner-only (the real
///           registry also counts operators and per-token approvals;
///           that only widens the self-feedback ban, so the mock stays
///           faithful for every flow the bridge exercises).
contract Mock8004Identity {
    uint256 private _lastId;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _wallets;
    mapping(uint256 => string) private _uris;

    event Registered(uint256 indexed agentId, string agentURI, address indexed owner);

    function register() external returns (uint256 agentId) {
        return _register("");
    }

    function register(string memory agentURI) external returns (uint256 agentId) {
        return _register(agentURI);
    }

    function _register(string memory agentURI) internal returns (uint256 agentId) {
        agentId = _lastId++;
        _owners[agentId] = msg.sender;
        _balances[msg.sender] += 1;
        _wallets[agentId] = msg.sender;
        _uris[agentId] = agentURI;
        emit Registered(agentId, agentURI, msg.sender);
    }

    function balanceOf(address owner) external view returns (uint256) {
        return _balances[owner];
    }

    function ownerOf(uint256 agentId) external view returns (address) {
        address owner = _owners[agentId];
        require(owner != address(0), "ERC721NonexistentToken");
        return owner;
    }

    function getAgentWallet(uint256 agentId) external view returns (address) {
        require(_owners[agentId] != address(0), "ERC721NonexistentToken");
        return _wallets[agentId];
    }

    function tokenURI(uint256 agentId) external view returns (string memory) {
        require(_owners[agentId] != address(0), "ERC721NonexistentToken");
        return _uris[agentId];
    }

    function isAuthorizedOrOwner(address spender, uint256 agentId) external view returns (bool) {
        return spender == this.ownerOf(agentId);
    }

    function getVersion() external pure returns (string memory) {
        return "2.0.0";
    }
}
