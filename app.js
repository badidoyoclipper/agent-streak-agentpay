// Agent Streak + AgentPay — minimal frontend logic.
// Reads config from config.js and ABIs from abi.js (generated from the
// compiled contracts; see RESEARCH.md). All writes go through the connected
// wallet's signer, so every transaction is reviewed and confirmed by the user.
(function () {
  const CFG = window.APP_CONFIG;
  const $ = (id) => document.getElementById(id);
  const configured = Boolean(CFG.agentStreakAddress && CFG.agentPayAddress);

  let provider, signer, account;
  let streak, pay, registry;

  function log(msg) {
    $("log").textContent = msg + "\n" + $("log").textContent;
  }

  function short(a) {
    return a ? a.slice(0, 6) + "…" + a.slice(-4) : "";
  }

  async function ensureChain() {
    const chainId = await window.ethereum.request({ method: "eth_chainId" });
    if (parseInt(chainId, 16) !== CFG.chainId) {
      await window.ethereum.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: "0x" + CFG.chainId.toString(16) }]
      });
    }
  }

  async function connect() {
    if (!window.ethereum) {
      log("No wallet found. Open this page in a browser with a Web3 wallet (e.g. Binance Wallet / MetaMask).");
      return;
    }
    await ensureChain();
    provider = new ethers.BrowserProvider(window.ethereum);
    signer = await provider.getSigner();
    account = await signer.getAddress();
    registry = new ethers.Contract(CFG.agentIdRegistry, window.ABIS.registry, provider);
    if (configured) {
      streak = new ethers.Contract(CFG.agentStreakAddress, window.ABIS.streak, signer);
      pay = new ethers.Contract(CFG.agentPayAddress, window.ABIS.pay, signer);
    }
    $("account").textContent = account;
    $("connectBtn").textContent = "Connected";
    const mine = $("myProfileLink");
    mine.href = "profile.html?agent=" + account;
    mine.style.display = "";
    await refresh();
  }

  async function refresh() {
    if (!account) return;
    const bal = await registry.balanceOf(account);
    const isHolder = bal > 0n;
    $("holderStatus").innerHTML = isHolder
      ? '<span class="ok">✔ This wallet holds an Agent ID</span> (registry balance: ' + bal.toString() + ")"
      : '<span class="bad">✘ This wallet does not hold an Agent ID.</span> Claim one in the Binance App: Wallet → Agent ID banner.';
    $("createReqBtn").disabled = !(configured && isHolder);

    if (!configured) {
      $("checkInHint").textContent = "Contracts are not deployed yet — deployment pending.";
      return;
    }

    const [cur, best, total, score, active] = await streak.getReputation(account);
    $("stCur").textContent = cur.toString();
    $("stBest").textContent = best.toString();
    $("stTotal").textContent = total.toString();
    $("stScore").textContent = score.toString();

    const doneToday = await streak.hasCheckedInToday(account);
    $("checkInBtn").disabled = !isHolder || doneToday;
    $("checkInHint").textContent = !isHolder
      ? "An Agent ID is required to check in."
      : doneToday
        ? "Already checked in today. Come back tomorrow to extend your streak."
        : active
          ? "Your streak is alive — check in to extend it."
          : "Start (or restart) your streak today.";

    const stats = await pay.getStats(account);
    $("paySent").textContent = stats.paymentsSent.toString();
    $("payReceived").textContent = stats.paymentsReceived.toString();
    await loadMyRequests();
  }

  async function loadMyRequests() {
    const ids = await pay.getPayeeRequestIds(account);
    if (ids.length === 0) {
      $("myRequests").textContent = "No requests yet.";
      return;
    }
    const statusName = ["Open", "Paid", "Cancelled"];
    let html = "<table><tr><th>ID</th><th>Amount (raw)</th><th>Memo</th><th>Status</th><th></th></tr>";
    for (const id of ids) {
      const r = await pay.getRequest(id);
      html +=
        "<tr><td>" + id.toString() + "</td><td>" + r.amount.toString() + "</td><td>" +
        escapeHtml(r.memo) + "</td><td>" + statusName[Number(r.status)] + "</td><td>" +
        (Number(r.status) === 0
          ? '<button class="secondary" data-cancel="' + id.toString() + '">Cancel</button>'
          : "") +
        "</td></tr>";
    }
    $("myRequests").innerHTML = html + "</table>";
    document.querySelectorAll("[data-cancel]").forEach((btn) => {
      btn.onclick = async () => {
        const tx = await pay.cancelRequest(BigInt(btn.dataset.cancel));
        log("Cancel sent: " + tx.hash);
        await tx.wait();
        log("Request cancelled.");
        refresh();
      };
    });
  }

  function escapeHtml(s) {
    return s.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
  }

  async function sendTx(label, fn) {
    try {
      const tx = await fn();
      log(label + " sent: " + tx.hash);
      await tx.wait();
      log(label + " confirmed.");
      await refresh();
    } catch (e) {
      log(label + " failed: " + (e.shortMessage || e.message));
    }
  }

  // ---- wiring ------------------------------------------------------------
  $("reqToken").value = CFG.defaultToken;
  $("contractsInfo").innerHTML =
    "Agent ID registry (SPACE ID): <a target=\"_blank\" href=\"" + CFG.explorer + "/address/" + CFG.agentIdRegistry + "\">" + CFG.agentIdRegistry + "</a><br>" +
    (configured
      ? "AgentStreak: <a target=\"_blank\" href=\"" + CFG.explorer + "/address/" + CFG.agentStreakAddress + "\">" + CFG.agentStreakAddress + "</a><br>" +
        "AgentPay: <a target=\"_blank\" href=\"" + CFG.explorer + "/address/" + CFG.agentPayAddress + "\">" + CFG.agentPayAddress + "</a>"
      : "AgentStreak / AgentPay: <i>not deployed yet (addresses will appear here after deployment)</i>");

  $("connectBtn").onclick = connect;

  $("viewProfileBtn").onclick = () => {
    const a = $("profileAddr").value.trim();
    if (a) location.href = "profile.html?agent=" + encodeURIComponent(a);
  };

  $("checkInBtn").onclick = () => sendTx("Check-in", () => streak.checkIn());

  $("createReqBtn").onclick = async () => {
    const tokenAddr = $("reqToken").value.trim();
    const amountHuman = $("reqAmount").value;
    const memo = $("reqMemo").value;
    if (!tokenAddr || !amountHuman) return log("Fill in the token and amount first.");
    const token = new ethers.Contract(tokenAddr, window.ABIS.erc20, provider);
    const decimals = await token.decimals();
    const amount = ethers.parseUnits(amountHuman, decimals);
    await sendTx("Create request", () => pay.createRequest(tokenAddr, amount, memo));
  };

  let loadedRequest = null;
  $("loadReqBtn").onclick = async () => {
    if (!configured || !account) return log("Connect your wallet first.");
    const id = BigInt($("payId").value || "0");
    const r = await pay.getRequest(id);
    loadedRequest = { id, r };
    const statusName = ["Open", "Paid", "Cancelled"];
    $("payDetails").textContent =
      "Payee " + r.payee + " · token " + r.token + " · amount (raw) " + r.amount.toString() +
      " · memo \"" + r.memo + "\" · status " + statusName[Number(r.status)];
    const token = new ethers.Contract(r.token, window.ABIS.erc20, provider);
    const allowance = await token.allowance(account, CFG.agentPayAddress);
    $("approveBtn").disabled = !(Number(r.status) === 0 && allowance < r.amount);
    $("payBtn").disabled = !(Number(r.status) === 0 && allowance >= r.amount);
  };

  $("approveBtn").onclick = async () => {
    if (!loadedRequest) return;
    const token = new ethers.Contract(loadedRequest.r.token, window.ABIS.erc20, signer);
    await sendTx("Approve", () => token.approve(CFG.agentPayAddress, loadedRequest.r.amount));
    $("loadReqBtn").click();
  };

  $("payBtn").onclick = async () => {
    if (!loadedRequest) return;
    await sendTx("Payment", () => pay.payRequest(loadedRequest.id));
  };

  if (window.ethereum) {
    window.ethereum.on("accountsChanged", () => location.reload());
    window.ethereum.on("chainChanged", () => location.reload());
  }
})();
