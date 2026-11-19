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
- **ERC-8004 bridge** — the same record is also published into
  [ERC-8004](https://eips.ethereum.org/EIPS/eip-8004), the global standard
  for trustless agent identity and reputation, so it stops being a score
  inside one project's contracts and becomes part of the shared agent
  reputation layer (see [ERC-8004 bridge](#erc-8004-bridge)). The profile
  page renders all three signals — Agent ID, local record, ERC-8004 —
  as one agent passport.

## How Agent ID is used

| Role | Mechanism |
| --- | --- |
| **Identity** | Agent ID ownership is verified on-chain against the official SPACE ID Agent ID registry (`0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`, ERC-721) using the exact `balanceOf(address) > 0` check documented in the Binance hackathon announcement. |
| **Access control** | Only verified Agent ID holders can check in and create payment requests (gate flag fixed at deployment). Because an Agent ID is non-transferable and one-per-user, this gate cannot be farmed with throwaway wallets. |
| **Payments** | Payment requests are anchored to a verified holder as payee. Settlement is a direct ERC-20 `transferFrom` from payer to payee — the contract never takes custody. |
| **Reputation** | Streaks, scores, payment counts, and per-token settled volume accumulate against the identity and are exposed through public view functions for any project to consume. |
| **Global standard** | `AgentId8004Bridge` mirrors the record into the ERC-8004 Identity/Reputation Registries live on BNB Chain: holders who also run an ERC-8004 agent get their streak score and settled-payment count published as standard ERC-8004 feedback, readable by every project in that ecosystem. |

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

### `AgentId8004Bridge` (`contracts/AgentId8004Bridge.sol`)

A separate, additive contract — the core contracts above are untouched, the
bridge only reads them. It connects this project's reputation to the live
ERC-8004 registries on BNB Chain (Identity
`0x8004A169FB4a3325136EB29fA0ceB6D2e539a432`, Reputation
`0x8004BAa17C55a88189AE136b182e5fdA19dE9b63`; interfaces verified against the
official `erc-8004/erc-8004-contracts` reference implementation, v2.0.0).

- **Reads:** whether an address is registered as an ERC-8004 agent and how
  many agents it owns, whether it owns a given agent id (nonexistent ids
  return `false`, never revert), the agent's verified wallet and card URI,
  and feedback aggregates from the Reputation Registry.
- **Writes:** `publishStreakScore` / `publishPaymentsReceived` /
  `publishAll` append the holder's locally-derived record to the Reputation
  Registry as standard feedback (tags `agentstreak`/`score` and
  `agentpay`/`paymentsReceived`). Before writing, the bridge verifies
  on-chain that the subject owns the agent id; the values are computed by
  the bridge from AgentStreak/AgentPay, so no caller can inject or inflate
  them, and anyone may trigger a publish. A channel is republished only
  when its value changed, and the bridge remembers the latest value and
  feedback index per agent so consumers can read the freshest snapshot
  directly.

## ERC-8004 bridge

ERC-8004 ("Trustless Agents", authored by contributors from MetaMask, the
Ethereum Foundation, Google, and Coinbase) defines shared Identity,
Reputation, and Validation registries for AI agents. Its registries are
deployed on BNB Chain mainnet, yet almost no Binance Agent ID holder uses
them — the identity Binance issues and the identity the global agent
ecosystem reads are two disconnected worlds. This bridge is the adapter
between them.

How publishing stays inside the standard's rules (v2.0.0, read from the
reference contracts, not assumed):

- Feedback is authored by its caller, recorded as the feedback *client*.
  Here the author is the bridge, attesting to data it reads from the
  source contracts; the subject is an agent owned by someone else —
  exactly the client-reviews-agent pattern the registry is built for.
- The standard **forbids self-feedback**: the agent's owner, operators,
  and approved addresses can never author feedback about their own agent.
  The bridge structurally cannot violate this — it owns no agent, and it
  only writes about an agent whose ownership it just verified.
- Entries are append-only; only the original author can revoke. The
  bridge deliberately exposes no revoke path — an attestation history
  that third parties could erase would be worthless. Fresher snapshots
  supersede older ones by index.
- The registry's `getSummary` **averages** a client's entries, so the
  bridge publishes cumulative snapshots (current score / current count),
  not per-event deltas, and republishes only on change. The authoritative
  "current" value is the bridge's latest entry — its index is stored
  on-chain in the bridge itself (`getPublishedSnapshot`).

One registry quirk integrators should know: `getSummary` reverts when
given an empty client list — pass `getClients(agentId)` or a known client
such as this bridge. The bridge passes calls through honestly rather than
hiding the behavior.

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
- **Agent passport** — the same profile also renders the holder's ERC-8004
  signal: registration status, agent id (auto-discovered from the
  registry's `Registered` events, or pinned with `&id8004=<id>`), verified
  agent wallet, feedback count and average across all clients, and the
  latest snapshots our bridge published. Three signals, one link: Agent ID
  proves who the agent is, the local record proves what it did here, and
  ERC-8004 makes the record readable everywhere.

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
  holds no funds and cannot grant badges manually. `AgentId8004Bridge`
  likewise has no owner and no admin functions, holds and moves no funds,
  and its four contract addresses are immutable; publishing reputation
  through it is a plain caller-confirmed transaction, and the values it
  writes are computed on-chain from AgentStreak/AgentPay — they cannot be
  supplied or altered by the caller.
- Nothing in this project promises or implies returns, income, or rewards.
  Reputation scores are identity records, not financial instruments.

## Run the tests

Requires the [Foundry](https://book.getfoundry.sh) toolchain:

```bash
forge build
forge test
```

The suite (43 tests) covers: first check-in, same-day double check-in
rejection, streak continuation, streak break and lapse semantics, the weekly
milestone bonus, the Agent ID gate (on and off), request creation rules,
settlement and direct payer→payee fund movement, reputation counters and
volumes, double-payment and cancelled-request rejection, self-payment
rejection, cancel permissions, the ScoreGateDemo threshold gate
(reject / claim / double-claim / threshold change), and the ERC-8004 bridge:
registration and ownership reads (including nonexistent agents), feedback
publishing for both channels with value/tag/index verification,
republish-only-on-change, summary averaging across snapshots, ownership and
no-reputation guards, the registry's empty-client summary rule, and its
self-feedback ban. The ERC-8004 registries are exercised through test mocks
that mirror the reference contracts' semantics (v2.0.0).

## Deployment

| Contract | Address (BNB Chain mainnet) |
| --- | --- |
| AgentStreak | `0xde372AA9C315814361771c2Ff21157d5fABBD9eB` |
| AgentPay | `0x672Bff3C451551A36bD645543ea9c78e9BD42f85` |
| ScoreGateDemo | `0x0e6eD55c61d1A8ae40950E98CD52a9C7509DDc03` |
| AgentId8004Bridge | `0x24857DAe4A574C6BBFa935fda1d7E1fC1865AE5c` |
| Agent ID registry (SPACE ID, official) | `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F` |
| ERC-8004 Identity Registry (official) | `0x8004A169FB4a3325136EB29fA0ceB6D2e539a432` |
| ERC-8004 Reputation Registry (official) | `0x8004BAa17C55a88189AE136b182e5fdA19dE9b63` |
| USDT (BEP-20, default payment token) | `0x55d398326f99059fF775485246999027B3197955` |

Constructor arguments: `AgentStreak(registry, true)`, `AgentPay(registry, true)`,
`ScoreGateDemo(agentStreakAddress, 3)`,
`AgentId8004Bridge(erc8004Identity, erc8004Reputation, agentStreakAddress, agentPayAddress)`.
Deployed 2026-11-20 from deployer `0xe489636a981FA6024Ea22B923b40Af61B5f37565`.
All four sources are verified on Sourcify with an exact match (creation and
runtime), which BscScan also displays; this repository is the exact source
of the deployed code. The project itself is registered as an ERC-8004 agent
— see `agent-registration.json`.

## License

MIT — see [LICENSE](LICENSE).
