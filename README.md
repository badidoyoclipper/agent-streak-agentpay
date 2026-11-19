# Agent Streak + AgentPay

**Reputation and payments for Binance Agent ID holders, on BNB Chain.**

An Agent ID (`name.ai`) is the on-chain name of a Binance Agentic Wallet: one
per user, non-transferable, issued only through the Binance App. That makes it
something ordinary wallet addresses are not — a **unique, sybil-resistant
identity for an AI agent**. But today that identity is inert: nothing reads it,
nothing accumulates on it, and no other application can tell a proven,
long-running agent from a wallet created five minutes ago.

This project gives Agent ID a memory:

- **AgentStreak** — holders check in once a day; the contract records streaks
  and a reputation score that **any other contract can read on-chain**.
- **AgentPay** — holders create payment requests that anyone can settle in one
  transaction, building a public, verifiable payment history (counts and
  settled volume) for both sides.
- **Public profile pages** — every holder gets a shareable "trusted name card"
  (`web/profile.html?agent=0x…`) rendering their streak, score, settled
  payments, and badge status live from chain. Holders use the product because
  the profile itself is valuable to them.
- **ScoreGateDemo** — a small, independent consumer contract that gates a
  "Trusted Agent" badge on the AgentStreak score, proving the reputation is
  genuinely composable (see [Composability proof](#composability-proof)).

## How Agent ID is used

| Role | Mechanism |
| --- | --- |
| **Identity** | Agent ID ownership is verified on-chain against the official SPACE ID Agent ID registry (`0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`, ERC-721) using the exact `balanceOf(address) > 0` check documented in the Binance hackathon announcement. |
| **Access control** | Only verified Agent ID holders can check in and create payment requests (gate flag fixed at deployment). Because an Agent ID is non-transferable and one-per-user, this gate cannot be farmed with throwaway wallets. |
| **Payments** | Payment requests are anchored to a verified holder as payee. Settlement is a direct ERC-20 `transferFrom` from payer to payee — the contract never takes custody. |
| **Reputation** | Streaks, scores, payment counts, and per-token settled volume accumulate against the identity and are exposed through public view functions for any project to consume. |

## Contracts

### `AgentStreak` (`contracts/AgentStreak.sol`)

One check-in per address per UTC day. Consecutive days build the current
streak; a missed day restarts it (longest streak is preserved). Score = 1 point
per check-in + a 5-point bonus at every 7-day streak milestone.

Public reputation interface — the part other dApps consume:

```solidity
function getStreak(address user) external view returns (uint256);        // effective streak (0 if lapsed)
function getLongestStreak(address user) external view returns (uint256);
function getTotalCheckIns(address user) external view returns (uint256);
function getScore(address user) external view returns (uint256);
function isActive(address user) external view returns (bool);            // checked in today or yesterday
function getReputation(address user) external view returns (uint256 currentStreak, uint256 longestStreak, uint256 totalCheckIns, uint256 score, bool active);
function isAgentIdHolder(address user) external view returns (bool);
```

### `AgentPay` (`contracts/AgentPay.sol`)

`createRequest(token, amount, memo)` → request id (caller is the payee, must
hold an Agent ID when gated). `payRequest(id)` settles an open request with a
direct payer→payee `transferFrom` (payer approves the contract first, as with
any ERC-20 payment). `cancelRequest(id)` lets the payee cancel an open
request. Requests are `Open` / `Paid` / `Cancelled`; self-payment is rejected
so reputation data stays honest. Views: `getRequest`, `getPayeeRequestIds`,
`getStats` (requests created, payments sent/received), `getVolumeSent`,
`getVolumeReceived` (per token).

### `ScoreGateDemo` (`contracts/ScoreGateDemo.sol`)

A minimal third-party-style consumer: `claimBadge()` succeeds only if the
caller's live AgentStreak score meets a threshold. Exists purely to prove
composability in executable code, and to power the "Trusted Agent" badge shown
on profile pages.

## Composability proof

Claims that a score "can be used by other projects" are cheap; this repo
proves it with a separate contract and tests:

- `ScoreGateDemo` holds **no special relationship** with `AgentStreak` — it
  calls the public `IAgentStreak.getScore(address)` interface, exactly as any
  outside project would.
- Its tests (in `test/ScoreGateDemo.t.sol`) show an address below the
  threshold being rejected, an address at the threshold claiming the badge,
  and a second claim reverting.
- Any project can do the same in a few lines — see the integration snippet
  below.

## Integrate the reputation primitive

**Solidity** — gate any function on Agent ID reputation:

```solidity
import {IAgentStreak} from "./interfaces/IAgentStreak.sol";

contract YourDapp {
    IAgentStreak public immutable streak; // AgentStreak deployment address

    constructor(address agentStreak) {
        streak = IAgentStreak(agentStreak);
    }

    function trustedOnlyAction() external {
        require(streak.getScore(msg.sender) >= 10, "reputation too low");
        require(streak.isActive(msg.sender), "agent not active");
        // ... your feature
    }
}
```

**JavaScript (ethers v6)** — read a profile from any backend or page:

```js
const streak = new ethers.Contract(AGENT_STREAK_ADDRESS, STREAK_ABI, provider);
const [cur, best, total, score, active] = await streak.getReputation(agentAddress);
```

The full interface lives in `contracts/interfaces/IAgentStreak.sol`, and the
ABIs used by the bundled web app are in `web/abi.js`.

## Web app

Static, mobile-first pages in `web/` (open `index.html`, or serve the folder):

- **Home** — connect a wallet (BNB Chain), see your holder status and streak,
  check in, create/pay/cancel payment requests. One tap per action; every
  transaction is reviewed and confirmed in your own wallet.
- **Public profile** — `profile.html?agent=<address>` renders any holder's
  streak, score, settled payment counts and volume, and Trusted Agent badge
  status, read-only from a public RPC. This is the holder's shareable name
  card — the reason to keep a streak alive.

Contract addresses are set in `web/config.js` after deployment.

## Safety & permissions disclosure

- Every check-in, payment, approval, and cancellation is a plain transaction
  that the user sends and confirms from their own wallet. There is no skill,
  bot, or backend that acts on a user's behalf, no scheduled or automatic
  transfers, and no mechanism that bypasses user confirmation.
- No web-based QR/pairing-code login; the web app uses a standard injected
  wallet connection only, and never asks for seed phrases, private keys, or
  pairing codes.
- **Owner permissions:** `AgentStreak` and `AgentPay` have **no owner and no
  admin functions at all** — no pause, no withdrawal, no minting, no tax, no
  upgrade path. They never hold user funds. The registry address and gate
  flag are immutable constructor parameters. `ScoreGateDemo` has one owner
  whose only power is adjusting its badge threshold (`setThreshold`); it
  holds no funds and cannot grant badges manually.
- Nothing in this project promises or implies returns, income, or rewards.
  Reputation scores are identity records, not financial instruments.

## Run the tests

Requires the [Foundry](https://book.getfoundry.sh) toolchain:

```bash
forge build
forge test
```

The suite (30 tests) covers: first check-in, same-day double check-in
rejection, streak continuation, streak break and lapse semantics, the weekly
milestone bonus, the Agent ID gate (on and off), request creation rules,
settlement and direct payer→payee fund movement, reputation counters and
volumes, double-payment and cancelled-request rejection, self-payment
rejection, cancel permissions, and the ScoreGateDemo threshold gate
(reject / claim / double-claim / threshold change).

## Deployment

| Contract | Address (BNB Chain mainnet) |
| --- | --- |
| AgentStreak | TBD after deployment |
| AgentPay | TBD after deployment |
| ScoreGateDemo | TBD after deployment |
| Agent ID registry (SPACE ID, official) | `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F` |
| USDT (BEP-20, default payment token) | `0x55d398326f99059fF775485246999027B3197955` |

Constructor arguments: `AgentStreak(registry, true)`, `AgentPay(registry, true)`,
`ScoreGateDemo(agentStreakAddress, 3)`. Sources are verified on BscScan at
deployment time; this repository is the exact source of the deployed code.

## License

MIT — see [LICENSE](LICENSE).
