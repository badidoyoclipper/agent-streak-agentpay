// Agent Streak + AgentPay — frontend configuration.
// Fill in the two contract addresses after deployment (see RESEARCH.md).
// Everything else is a public, verifiable mainnet constant.
window.APP_CONFIG = {
  chainId: 56,
  chainName: "BNB Smart Chain",
  rpcUrl: "https://bsc-rpc.publicnode.com",

  // Official SPACE ID Agent ID registry (ERC-721, symbol "AI") on BNB Chain.
  // Source: Binance Agent ID Hackathon announcement, "Developer Resources".
  agentIdRegistry: "0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F",

  // ERC-8004 registries (global agent identity/reputation standard) on
  // BNB Chain mainnet. Canonical CREATE2 addresses, identical on every
  // mainnet; source: github.com/erc-8004/erc-8004-contracts
  // (scripts/addresses.ts), verified on-chain 2026-11-20 (getVersion
  // "2.0.0" on both; the Reputation Registry points at this Identity
  // Registry).
  erc8004Identity: "0x8004A169FB4a3325136EB29fA0ceB6D2e539a432",
  erc8004Reputation: "0x8004BAa17C55a88189AE136b182e5fdA19dE9b63",

  // TBD after deployment — the pages stay read-only until these are set.
  agentStreakAddress: "",
  agentPayAddress: "",
  scoreGateAddress: "",
  agentBridgeAddress: "",

  // BEP-20 USDT on BNB Chain (18 decimals), the default payment token.
  defaultToken: "0x55d398326f99059fF775485246999027B3197955",
  explorer: "https://bscscan.com"
};
