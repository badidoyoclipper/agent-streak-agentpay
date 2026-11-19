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

  // TBD after deployment — the pages stay read-only until these are set.
  agentStreakAddress: "",
  agentPayAddress: "",
  scoreGateAddress: "",

  // BEP-20 USDT on BNB Chain (18 decimals), the default payment token.
  defaultToken: "0x55d398326f99059fF775485246999027B3197955",
  explorer: "https://bscscan.com"
};
