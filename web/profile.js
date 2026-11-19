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

  main().catch((e) => {
    $("holderLine").innerHTML = '<span class="bad">Failed to load on-chain data: ' + (e.shortMessage || e.message) + "</span>";
  });
})();
