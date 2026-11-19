# IDEAS.md — Riset GitHub untuk ide yang lebih baik

Riset dilakukan 19 Nov 2026 malam (WIB), lewat halaman repo GitHub dan sumber publik.
Konvensi: bagian **FAKTA** = isi repo/sumber apa adanya (dengan URL). Bagian **PENILAIAN** = opini analis, bukan fakta.
Build yang sedang berjalan saat riset ini dibuat: AgentStreak (gerbang registry SPACE ID asli,
`balanceOf > 0`, tanpa owner/admin, skor composable) + AgentPay + ScoreGateDemo + web profil.

---

## 1. FAKTA — Ekosistem resmi yang bisa dipakai ulang

### 1.1 Agent ID = SPACE ID (ERC-721), dan build kita sudah memakainya dengan benar
- Pengumuman resmi Binance menyebut kontrak Agent ID di BNB Chain: `0x60b9262456de011f7d15a54cdd8c48baaa8b022f`,
  nama kontrak "SPACE ID Agent ID", simbol AI, ERC-721, non-transferable.
  Sumber: https://www.binance.com/en/square/post/389517345917641
- Pola gerbang yang sama dipakai entri lain yang sudah live (Mint Guardian): "A wallet holds an Agent ID iff
  `balanceOf(wallet) > 0`". Build kita memakai pola persis ini.

### 1.2 binance/binance-skills-hub — marketplace skill resmi Binance
- URL: https://github.com/binance/binance-skills-hub
- Bukti: 1,199 stars, 279 forks, 182 commits (halaman repo, dibaca 19 Nov 2026); commit terakhir 12 Nov 2026
  (via tradingagentstack.com). Skill `binance-agentic-wallet` mendorong CLI `baw`: termasuk perintah
  `wallet agent-id` (cek klaim .ai), pembayaran x402, dan "Agent ID exclusive token launches".
  Tercatat 54,101 installs untuk skill wallet itu (mcpinstall.com). Kontribusi publik diterima via PR
  dengan format SKILL.md.

### 1.3 bnb-chain/bnbagent-sdk — SDK resmi BNB Chain untuk agent on-chain
- URL: https://github.com/bnb-chain/bnbagent-sdk
- Bukti: 66 stars, 36 forks, lisensi MIT, dibuat 5 Feb 2026, 30 releases, aktif (halaman repo, 19 Nov 2026).
- Isi: SDK TypeScript (`@bnbagent/sdk`) + Python (`bnbagent`) untuk **ERC-8004 (identitas agent)** dan
  **ERC-8183 (Agentic Commerce: kernel AgenticCommerce + EvaluatorRouter + OptimisticPolicy — negosiasi,
  terima job, kirim hasil, dibayar via escrow)** plus pembayaran x402 dan abstraksi wallet.

### 1.4 ERC-8004 (Trustless Agents) SUDAH live di BSC mainnet
- Repo: https://github.com/erc-8004/erc-8004-contracts — 240 stars, 116 forks, dibuat 8 Okt 2025 (halaman repo).
- Spesifikasi: https://eips.ethereum.org/EIPS/eip-8004 — ditulis Marco De Rossi (MetaMask), Davide Crapis
  (Ethereum Foundation), Jordan Ellis (Google), Erik Reppel (Coinbase). Tiga registry: Identity (ERC-721),
  Reputation (feedback terstruktur `giveFeedback`), Validation.
- Alamat BSC mainnet (dari README repo resmi, alamat sama di semua chain karena CREATE2):
  IdentityRegistry `0x8004A169FB4a3325136EB29fA0ceB6D2e539a432`,
  ReputationRegistry `0x8004BAa17C55a88189AE136b182e5fdA19dE9b63`.
- Sensus independen 24 Okt 2026 menghitung ±382,289 registrasi ERC-8004 di BNB Smart Chain
  (dev.to/agenticfinancegraph, "Where the ERC-8004 registrations live, chain by chain").

### 1.5 ERC-8183 (Agentic Commerce) — standar job + escrow + evaluator
- Spesifikasi: https://eips.ethereum.org/EIPS/eip-8183 (draft, dibuat 25 Feb 2026; penulis dari EF dAI team
  dan Virtuals). Teks mentah: https://github.com/ethereum/ercs/blob/HEAD/ERCS/erc-8183.md
- Primitif "Job": Client mendanai escrow → Provider mengirim deliverable → Evaluator menandai
  complete/reject → dana lepas/refund. Spesifikasi secara eksplisit dirancang berpadu dengan reputasi
  ERC-8004 ("attestation reason … enables audit and composition with reputation (e.g. ERC-8004)").
- Implementasi referensi Virtuals (ACP) di Base: 82,000+ jobs terbaca on-chain per 25 Okt 2026
  (gloam.trade, "Agents should not do business in public").

### 1.6 Angka pasar dari BAS (agent.bas.io) — celah pasar terukur
- Studi: https://medium.com/@bas_io/binance-agent-id-36b574b74c5a (snapshot 11 Nov 2026)
- 182,040 Agent ID terklaim per 11 Nov 2026; hanya 992 holder (0,54%) yang juga menjalankan agent ERC-8004;
  hanya 2 holder yang pernah memakai ERC-8183, keduanya sebagai client, total $0,03;
  **belum pernah ada holder Agent ID yang dibayar untuk pekerjaan lewat ERC-8183.**
- Kutipan intinya: "Agent ID tells you who is behind a wallet, not what the wallet does."
- BAS sendiri sudah menjalankan direktori semua holder + halaman profil per wallet (pengindeks pasif —
  tidak ada transaksi yang bisa dilakukan dari sana).

### 1.7 x402 / B402 — rel pembayaran agent milik Binance sendiri
- Protokol x402 (Coinbase, kini x402 Foundation): repo https://github.com/coinbase/x402
  (±5,900+ stars per Apr 2026 menurut dokumentasi komunitas) — pembayaran HTTP 402, tanda tangan EIP-712/
  Permit2, tanpa gas bagi pembayar, difasilitasi facilitator.
- Implementasi Binance di BSC bernama **B402**: endpoint facilitator `/papi/v2/b402/{supported,verify,settle}`
  (didokumentasikan di README repo pihak ketiga https://github.com/xinyuzjj/bazz.agent , yang mengintegrasikan
  Agentic Wallet + x402 + MCP). Skill resmi `binance-agentic-wallet` juga mencantumkan pembayaran x402
  sebagai kemampuan bawaan `baw`.

---

## 2. FAKTA — Entri/pesaing yang sudah publik (semua live 18–19 Nov 2026)

### 2.1 AgentWall — TUMPAH TINDIH LANGSUNG dengan AgentStreak
- Situs live: febry10.github.io/agentwall ; pengumuman: https://www.threads.com/@heavenholic33/post/Df56-wUD7mS
  dan video promosi di Facebook (19 Nov 2026).
- Fitur menurut materi promosinya sendiri: **daily check-in untuk streak dan poin**, dinding pesan publik
  khusus holder Agent ID, tips BNB antar-holder (forward instan, tanpa fee, tanpa kustodi),
  "No owner. No admin. Verified & open-source on BscScan." Sedang merekrut "30 Founding Agents" pertama —
  target yang sama dengan gerbang ≥30 alamat kategori Innovation.

### 2.2 AgentAttest — registry vouching khusus holder, sudah live
- Pengumuman: https://www.threads.com/@zuhdihusni/post/Df5spyCjKCN (18 Nov 2026).
- Menurut pengumumannya: registry on-chain di BNB Chain, hanya holder Agent ID yang bisa register dan
  saling vouch, biaya ±$0,005 per register, kontrak terverifikasi BscScan, secara eksplisit mengajak
  komunitas menembus >30 agent. → Ide "attestation antar-agent" dalam bentuk sederhananya sudah diambil.

### 2.3 Mint Guardian — pesaing terkuat sejauh ini (data moat)
- Repo: https://github.com/ls4825783/mint-guardian (dibuat 18 Nov 2026, MIT, 0 stars saat dibaca).
- dApp live https://mint-guardian.netlify.app ; kontrak BSC terverifikasi (Exact Match):
  `0xEF4318fB3fDc9de236E8Fdc9C1Bdd2AA67e272F2`.
- Menurut README-nya: registry keamanan free mint BSC; hanya holder Agent ID yang boleh mengirim laporan
  Safe/Risky/Scam atau meng-endorse laporan; registry di-seed dari 7,500+ free mint nyata yang diverifikasi
  receipt-per-receipt sejak Okt 2026, termasuk mekanisme scam yang didekode on-chain. Owner-nya holder
  `yako.ai`. Ini persis domain free-mint yang selama ini digeluti user kita — dengan keunggulan data
  yang tidak bisa dibuat ulang dalam 19 hari.

### 2.4 Jalur "gated mint" sudah jenuh
- GANG AGENT: mint share khusus holder, 3,822/10,000 termint (Instagram, 18 Nov 2026).
- AgentMint (free mint holder, supply 1,000, tanpa owner), Agentic Gangster (1,111 Genesis Pass),
  kartu kolektibel AGENTID (3,000 supply) — semuanya variasi gerbang yang sama sejak Okt–Nov 2026.
- Launchpad besar juga sudah memakai Agent ID sebagai gerbang: Four.Meme "Binance Agent ID Exclusive"
  dan Flap "ID Agent Curve" (TokenPost, dikutip BAS).

---

## 3. PENILAIAN — 5 ide adopsi teratas

### Ide 1 — Jembatan ERC-8004: buat skor kita kompatibel standar global (Usaha: KECIL–SEDANG) ⭐
Apa: (a) Daftarkan proyek kita sebagai agent di ERC-8004 Identity Registry BSC; (b) pada milestone
tertentu (mis. pembayaran AgentPay lunas, streak 7 hari), kontrak/relayer kita menulis feedback ke
ERC-8004 Reputation Registry BSC (`giveFeedback` dengan tag kita); (c) halaman profil menampilkan
skor ERC-8004 holder bila ada.
Kenapa lebih baik: skor AgentWall, AgentAttest, dan hampir semua entri terkunci di kontrak mereka
sendiri. ERC-8004 adalah standar yang ditulis orang MetaMask/EF/Google/Coinbase dan registry-nya
di-deploy di BSC oleh ekosistem BNB Chain sendiri (SDK resminya bnbagent-sdk). Kompatibilitas ini
mengubah klaim "skor bisa dibaca kontrak lain" menjadi "skor kami bagian dari standar reputasi agent
global" — bahasa yang dikenali juri Innovation. Biaya rendah karena registry-nya sudah live; kita
hanya menulis adapter, bukan registry baru.

### Ide 2 — AgentPay mode "Job" ala ERC-8183: bayar agent untuk bekerja, bukan sekadar transfer (Usaha: SEDANG) ⭐
Apa: Tambahkan mode job ramping ke AgentPay: client menunjuk provider (wajib holder Agent ID),
dana masuk escrow, provider mengirim hash deliverable, client (atau evaluator yang ditunjuk)
complete/reject, dana lepas/refund; penyelesaian job menaikkan reputasi kedua pihak (dan menulis
feedback ERC-8004 bila Ide 1 diambil). Tiru lifecycle ERC-8183 (Open → Funded → Submitted →
Terminal), bukan implementasi penuh.
Kenapa lebih baik: ini satu-satunya celah yang dibuktikan KOSONG oleh data resmi — dari 182,040
holder Agent ID, nol yang pernah dibayar untuk pekerjaan (BAS, 1.6). Semua pesaing berkumpul di
check-in/registry/mint. "Lapisan yang hilang antara identitas Binance dan ekonomi agent" adalah
narasi Innovation terkuat yang tersedia, dan tetap sejalan prinsip user: orang datang karena
teknologinya berguna (dibayar untuk kerja nyata), bukan insentif. Risiko: scope creep — wajib
dibatasi satu kontrak ramping + UI satu halaman; kerjakan SETELAH inti live.

### Ide 3 — Terima pembayaran via B402/x402 di AgentPay (Usaha: SEDANG)
Apa: Payment request AgentPay dapat dibayar agent lain secara programatis lewat facilitator B402
Binance (tanda tangan Permit2, pembayar tanpa gas), di samping jalur transfer ERC-20 biasa.
Kenapa lebih baik: memakai rel pembayaran milik Binance sendiri end-to-end (Agentic Wallet → B402 →
kontrak kita) menunjukkan integrasi stack penyelenggara, dan membuat AgentPay benar-benar
"machine-payable" — beda kelas dari tombol transfer biasa. Risiko: akses endpoint `/papi/v2/b402`
mungkin butuh kredensial developer; verifikasi dulu ketersediaannya sebelum menjanjikan. Jadikan
stretch goal, bukan jalur kritis.

### Ide 4 — Profil publik sebagai "paspor agent" 3-sinyal (Usaha: KECIL)
Apa: Halaman profil per Agent ID yang sudah kita bangun ditambah dua bacaan read-only: status
ERC-8004 (punya agent terdaftar? ringkasan feedback) dan riwayat job AgentPay. Satu tautan yang
menjawab "siapa agent ini dan apa rekam jejaknya".
Kenapa lebih baik: BAS membuktikan ada permintaan untuk direktori/profil holder, tapi BAS pasif.
Profil kita actionable (dari profil bisa langsung check-in, membayar, memberi job) — alasan datang
karena teknologi yang tidak dimiliki pengindeks. Murah: semua read-only dari kontrak yang sudah ada.

### Ide 5 — Publikasikan skill resmi kita ke Binance Skills Hub (Usaha: KECIL)
Apa: Satu folder skill format SKILL.md (pola binance-skills-hub, kontribusi publik via PR) yang
memungkinkan agent mana pun memeriksa skor/streak suatu .ai, membuat payment request, dan
mengingatkan check-in — selalu lewat konfirmasi user di wallet-nya sendiri.
Kenapa lebih baik: distribusi lewat marketplace skill resmi (skill wallet-nya saja 54,101 installs)
adalah kanal tempat agent beneran hidup; ini juga menjawab syarat "dipakai alamat/agent lain"
secara harfiah dan memperkuat cerita Pioneer (interaksi datang dari agent, bukan cuma klik manusia).
Catatan keras: skill tidak boleh pernah melewati konfirmasi user — itu aturan diskualifikasi
hackathon dan aturan BAW kita sendiri.

---

## 4. VONIS (PENILAIAN)

**Tetap hybrid + adopsi — jangan pivot total.**

Alasan:
1. Waktu dan posisi: pesaing terkuat (Mint Guardian, AgentWall, AgentAttest) sudah live sejak
   18–19 Nov. Pivot penuh membuang kontrak+tes+web yang sudah jadi dan memulai dari nol melawan
   orang yang sudah merekrut pengguna.
2. Komponen check-in kita memang bukan lagi pembeda (AgentWall membuktikannya), tetapi fondasi
   kita — gerbang registry asli, kontrak tanpa owner, skor composable + ScoreGateDemo — sudah di
   atas rata-rata entri. Yang kurang bukan fondasi baru, melainkan JEMBATAN STANDAR.
3. Kandidat pivot yang tampak menggoda semuanya sudah terisi atau tidak realistis dalam 19 hari:
   registry keamanan mint (Mint Guardian + data 7,500 mint yang tak bisa dikejar), attestation
   murni (AgentAttest), direktori pasif (BAS), gated mint (jenuh total).

Urutan adopsi yang disarankan:
- **Sekarang, bersamaan dengan deploy inti:** Ide 1 (jembatan ERC-8004) + Ide 4 (profil paspor).
  Keduanya kecil–sedang, tidak mengubah kontrak inti secara berisiko (adapter + read-only),
  dan langsung menaikkan nilai Innovation.
- **Setelah inti live & submit aman:** Ide 2 (mode Job ERC-8183) sebagai kontrak pendamping —
  satu-satunya penambah yang cukup kuat untuk mengubah posisi kita dari "dApp check-in yang rapi"
  menjadi "yang pertama membayar agent Agent ID untuk bekerja", dengan bukti celah dari data BAS.
  Bila waktu memaksa memilih, submit inti yang sudah terverifikasi selalu didahulukan.
- **Stretch:** Ide 3 (B402) setelah ketersediaan endpoint diverifikasi; Ide 5 (skill) kapan pun —
  murah dan bisa dikerjakan paralel tanpa menyentuh kontrak.

Risiko utama yang tersisa bukan teknologi, melainkan Pioneer: AgentWall merekrut 30 alamat
pertama dengan fitur yang mirip. Jembatan standar + profil paspor + (nanti) mode Job adalah
pembeda yang membuat holder memilih check-in dan bertransaksi di tempat kita — sesuai prinsip
user bahwa pengguna harus datang karena teknologinya.
