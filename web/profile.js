// Public Agent ID profile — read-only. Loads ?agent=<address> and renders
// that holder's on-chain reputation from AgentStreak, AgentPay, and the
// ScoreGateDemo badge contract, straight from a public BNB Chain RPC.
// No wallet connection is needed (or possible) on this page.
(function () {
  const CFG = window.APP_CONFIG;
  const $ = (id) => document.getElementById(id);
  const params = new URLSearchParams(location.search);
  const agent = (params.get("agent") || "").trim();

  $("shareUrl").textContent = location.href;
  $("copyBtn").onclick = () => navigator.clipboard && navigator.clipboard.writeText(location.href);

  async function main() {
    if (!ethers.isAddress(agent)) {
      $("addrTitle").textContent = "No valid agent address";
      $("holderLine").innerHTML =
        '<span class="bad">Add ?agent=0x… with a BNB Chain address to view a profile.</span>';
      return;
    }
    $("addrTitle").textContent = agent;
    document.title = "Agent " + agent.slice(0, 6) + "…" + agent.slice(-4) + " — profile";

    const provider = new ethers.JsonRpcProvider(CFG.rpcUrl);
    const registry = new ethers.Contract(CFG.agentIdRegistry, window.ABIS.registry, provider);

    const bal = await registry.balanceOf(agent);
    $("holderLine").innerHTML =
      (bal > 0n
        ? '<span class="ok">✔ Verified Agent ID holder</span>'
        : '<span class="bad">✘ This address does not hold an Agent ID</span>') +
      ' · <a target="_blank" href="' + CFG.explorer + "/address/" + agent + '">View on BscScan</a>';

    // The ERC-8004 passport depends only on the (already live) global
    // registries, so it renders even before our own contracts deploy.
    await load8004(provider);

    if (!CFG.agentStreakAddress || !CFG.agentPayAddress) {
      $("holderLine").innerHTML +=
        '<br><span class="muted">AgentStreak / AgentPay are not deployed yet — streak and payment data will appear here after deployment.</span>';
      $("badgeLine").innerHTML = '<span class="badge no">Unavailable — deployment pending</span>';
      return;
    }

    const streak = new ethers.Contract(CFG.agentStreakAddress, window.ABIS.streak, provider);
    const pay = new ethers.Contract(CFG.agentPayAddress, window.ABIS.pay, provider);

    const [cur, best, total, score, active] = await streak.getReputation(agent);
    $("pCur").textContent = cur.toString();
    $("pBest").textContent = best.toString();
    $("pTotal").textContent = total.toString();
    $("pScore").textContent = score.toString();
    $("pActive").textContent = active ? "Yes" : "No";

    const stats = await pay.getStats(agent);
    $("pReqCreated").textContent = stats.requestsCreated.toString();
    $("pReceived").textContent = stats.paymentsReceived.toString();
    $("pSent").textContent = stats.paymentsSent.toString();

    // Volume is shown for the default payment token (USDT on BNB Chain).
    const token = new ethers.Contract(CFG.defaultToken, window.ABIS.erc20, provider);
    const [dec, sym, volIn, volOut] = await Promise.all([
      token.decimals(),
      token.symbol(),
      pay.getVolumeReceived(agent, CFG.defaultToken),
      pay.getVolumeSent(agent, CFG.defaultToken)
    ]);
    $("pVolReceived").textContent = ethers.formatUnits(volIn, dec) + " " + sym;
    $("pVolSent").textContent = ethers.formatUnits(volOut, dec) + " " + sym;
    $("volNote").textContent = "Volumes are totals settled through AgentPay in " + sym + " (the default payment token).";

    if (CFG.scoreGateAddress) {
      const gate = new ethers.Contract(CFG.scoreGateAddress, window.ABIS.gate, provider);
      const [has, can] = await Promise.all([gate.hasBadge(agent), gate.canClaim(agent)]);
      $("badgeLine").innerHTML = has
        ? '<span class="badge trusted">🛡️ Trusted Agent — badge claimed</span>'
        : can
          ? '<span class="badge yes">Eligible — badge not claimed yet</span>'
          : '<span class="badge no">Not yet eligible — keep the streak going</span>';
    } else {
      $("badgeLine").innerHTML = '<span class="badge no">Unavailable — demo contract not deployed yet</span>';
    }
  }

  // ---------------------------------------------------------------
  // ERC-8004 passport: registration status, agent id, feedback
  // summary, and the latest snapshots our bridge published.
  // ---------------------------------------------------------------

  async function load8004(provider) {
    const set = (id, txt) => { $(id).textContent = txt; };
    try {
      const identity = new ethers.Contract(CFG.erc8004Identity, window.ABIS.erc8004Identity, provider);
      const reputation = new ethers.Contract(CFG.erc8004Reputation, window.ABIS.erc8004Reputation, provider);

      const count = await identity.balanceOf(agent);
      set("e8Registered", count > 0n ? "Yes (" + count.toString() + " agent" + (count > 1n ? "s" : "") + ")" : "No");
      if (count === 0n) {
        set("e8AgentId", "—");
        $("e8Note").innerHTML += "<br>This address has not registered an ERC-8004 agent yet.";
        return;
      }

      // Discover the agent id: an explicit &id8004=<id> wins; otherwise
      // scan the indexed Registered events (the registry deliberately
      // has no on-chain enumeration).
      let agentId = null;
      const param = params.get("id8004");
      if (param !== null && /^\d+$/.test(param)) {
        agentId = BigInt(param);
      } else {
        agentId = await discoverAgentId(provider, identity);
      }
      if (agentId === null) {
        set("e8AgentId", "not found");
        $("e8Note").innerHTML +=
          "<br>Could not auto-discover this address's ERC-8004 agent ID through the public RPC — append &amp;id8004=&lt;agentId&gt; to the URL.";
        return;
      }
      set("e8AgentId", agentId.toString());

      const wallet = await identity.getAgentWallet(agentId);
      $("e8Wallet").innerHTML =
        'Verified ERC-8004 agent wallet: <a target="_blank" href="' + CFG.explorer + "/address/" + wallet + '">' + wallet + "</a>";

      // Feedback summary across every client that ever rated this agent
      // (getSummary requires a non-empty client list by design).
      const clients = await reputation.getClients(agentId);
      if (clients.length > 0) {
        const [fbCount, avg, dec] = await reputation.getSummary(agentId, clients, "", "");
        set("e8FbCount", fbCount.toString());
        set("e8FbAvg", ethers.formatUnits(avg, dec));
      } else {
        set("e8FbCount", "0");
        set("e8FbAvg", "—");
      }

      // Latest snapshots published by our bridge, once it is deployed.
      if (CFG.agentBridgeAddress) {
        const bridge = new ethers.Contract(CFG.agentBridgeAddress, window.ABIS.bridge, provider);
        const [sVal, sIdx] = await bridge.getPublishedSnapshot(agentId, 0);
        const [pVal, pIdx] = await bridge.getPublishedSnapshot(agentId, 1);
        set("e8SnapStreak", sIdx > 0n ? sVal.toString() : "not published yet");
        set("e8SnapPay", pIdx > 0n ? pVal.toString() : "not published yet");
      } else {
        set("e8SnapStreak", "bridge not deployed yet");
        set("e8SnapPay", "bridge not deployed yet");
      }
    } catch (e) {
      set("e8Registered", "unavailable");
      $("e8Note").innerHTML +=
        "<br>ERC-8004 data could not be loaded from the public RPC (" + (e.shortMessage || e.message) + ").";
    }
  }

  // Best-effort agent-id discovery: walk the Registered event log
  // backwards in chunks. Returns the agentId of the address's most
  // recent registration, or null when it cannot be found this way.
  async function discoverAgentId(provider, identity) {
    try {
      const topic = identity.interface.getEvent("Registered").topicHash;
      const ownerTopic = ethers.zeroPadValue(agent, 32);
      const latest = await provider.getBlockNumber();
      const CHUNK = 100000;
      const MAX_CHUNKS = 40; // ~4M blocks of history, best effort
      for (let i = 0; i < MAX_CHUNKS; i++) {
        const to = latest - i * CHUNK;
        if (to < 0) break;
        const from = Math.max(0, to - CHUNK + 1);
        const logs = await provider.getLogs({
          address: CFG.erc8004Identity,
          topics: [topic, null, ownerTopic],
          fromBlock: from,
          toBlock: to
        });
        if (logs.length > 0) {
          return identity.interface.parseLog(logs[logs.length - 1]).args.agentId;
        }
        if (from === 0) break;
      }
    } catch (e) { /* fall through: caller shows the id8004 hint */ }
    return null;
  }

  main().catch((e) => {
    $("holderLine").innerHTML = '<span class="bad">Failed to load on-chain data: ' + (e.shortMessage || e.message) + "</span>";
  });
})();
