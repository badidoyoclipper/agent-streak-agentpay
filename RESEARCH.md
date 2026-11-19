# RESEARCH — Agent ID Hackathon: riset & rencana deploy

Dokumen kerja internal (Bahasa Indonesia). Semua klaim teknis di bawah punya
sumber; yang tidak terverifikasi dinyatakan apa adanya.
Status per 19 Nov 2026 ±23:55 WIB: riset selesai, kontrak + tes selesai
(30/30 lulus lokal), **belum ada deploy apa pun**.
Update 20 Nov 2026: fase adopsi bertahap — jembatan ERC-8004 selesai
(kontrak + web profil paspor + tes; suite penuh 43/43 lulus lokal),
mode Job ERC-8183 DITUNDA atas keputusan user. Detail jembatan:
BRIDGE.md. Tetap **belum ada deploy apa pun**.

---

## 1. Cara resmi memverifikasi holder Agent ID secara on-chain — TERVERIFIKASI

Pengumuman resmi hackathon di Binance memuat bagian "Developer Resources"
yang menjawab ini secara eksplisit:

- **Kontrak Agent ID (BNB Chain mainnet): `0x60b9262456de011f7d15a54cdd8c48baaa8b022f`**
  — nama kontrak "SPACE ID Agent ID", simbol `AI`, standar ERC-721,
  non-transferable.
- **Metode cek resmi**: panggil `balanceOf(address)` pada kontrak itu;
  nilai > 0 berarti alamat tersebut memegang Agent ID.
- Claim Agent ID hanya bisa dari aplikasi Binance (Wallet → banner Agent ID).

Sumber: pengumuman resmi Binance, "Agent ID Hackathon: Build Decentralized
Applications (dApps) Around Agent ID to Win 60,000 USDC Worth of Rewards"
(18 Nov 2026) — https://www.binance.com/en/support/announcement/detail/95f5dbe0ea674a48a739b59e046648bf
(bagian Agent ID / Developer Resources).

**Verifikasi mandiri lewat RPC publik BSC** (eth_call ke
https://bsc-rpc.publicnode.com, 19 Nov 2026):

- `name()` pada 0x60B9…022F → `"SPACE ID Agent ID"` ✔
- `symbol()` → `"AI"` ✔
- `balanceOf(0x811f1793D3604a6a17d950f308877bF5187Fc3fD)` (alamat EVM BAW
  milik user, pemegang `badidoyo.ai`) → **1** ✔ — metode resmi ini terbukti
  bekerja langsung terhadap holder nyata.

**Korroborasi independen**: alamat registry yang sama dipakai proyek-proyek
Agent ID yang sudah live untuk gating on-chain — Horror Protocol
(horrorprotocol.surge.sh), CATAI (skillsllm.com/skill/catai-skill),
Pocket Ai (pocket.agenticwallet.workers.dev), agentbnbai.com. Pola mereka
identik: kontrak memanggil `balanceOf` registry dan menolak non-holder.

**Catatan kejujuran riset**:

- Satu proyek (RuninAI, runinai.com/llms.txt) menyebut alamat berbeda
  `0x135E3F94813198F345f09Eaa79AAe2C936aadED1` sebagai "registry yang
  diverifikasi kontraknya". Alamat resmi dari Binance adalah 0x60B9…022F;
  proyek ini memakai yang resmi dari Binance. (0x135E… kemungkinan komponen
  SPACE ID lain; tidak dipakai dan tidak diklaim apa pun tentangnya.)
- Resolusi nama `.ai` → alamat (dan sebaliknya) TIDAK didokumentasikan
  Binance sebagai bacaan on-chain publik untuk dApp, dan memang tidak
  dibutuhkan desain ini: gerbang memakai `balanceOf`, pembayaran memakai
  alamat. Sesuai garis merah pengumuman, produk ini juga TIDAK menyediakan
  fitur "mencari wallet orang lain berdasarkan nama".
- Tidak ada FAQ hackathon terpisah yang terhubung dari pengumuman; seluruh
  aturan (termasuk garis merah keamanan dan kriteria penilaian) ada di
  pengumuman itu sendiri.

### Aturan hackathon yang memengaruhi desain (dari pengumuman resmi)

- Submit 18 Nov – 9 Des 2026 08:00 UTC; kontrak wajib di BNB Chain,
  terverifikasi + open source di BscScan; satu tim satu proyek; **tiap
  proyek hanya bisa menerima satu award**.
- Pioneer: ranking data on-chain — jumlah alamat holder Agent ID yang
  berinteraksi, volume/jumlah transaksi; hanya alamat submitted yang
  dihitung dan hanya interaksi dari alamat holder Agent ID.
- Innovation: syarat produk live + ≥30 alamat Agent ID berinteraksi selama
  periode submit. Kriteria juri: Kedalaman Aplikasi Agent ID 30%,
  Kepraktisan & Kelayakan 25%, Kelengkapan Produk 25%, Inovasi 20%.
- Garis merah (pelanggaran = diskualifikasi langsung): login QR Agentic
  Wallet di situs pihak ketiga; skill/prompt yang melewati konfirmasi
  transaksi user; transfer aset tanpa otorisasi (termasuk transfer otomatis
  terjadwal / approval tak terbatas yang disembunyikan); kontrak wajib open
  source dengan izin owner yang diungkap; impersonasi brand Binance/BNB;
  mengumpulkan kredensial sensitif; menjanjikan return ("passive income",
  "automatic money-making"); produk trading wajib menampilkan peringatan
  risiko; Agent ID tidak boleh dikemas sebagai alat mengintip wallet orang
  via nama; manipulasi volume / registrasi akun massal untuk interaksi =
  diskualifikasi.
- Desain proyek ini mematuhi semuanya secara konstruksi: semua aksi adalah
  tx biasa yang dikonfirmasi holder sendiri; kontrak utama tanpa owner dan
  tanpa custody dana; tidak ada janji return di UI/dokumen; tidak ada fitur
  lookup nama→wallet.

## 1b. ERC-8004 (Trustless Agents) — TERVERIFIKASI dari repo resmi + live

Ringkasan; uraian lengkap + keputusan desain di BRIDGE.md.

- **Alamat kanonis mainnet** (repo resmi `erc-8004/erc-8004-contracts`,
  `scripts/addresses.ts` → `MAINNET_ADDRESSES`; alamat CREATE2 yang sama
  di semua mainnet termasuk BSC): Identity
  `0x8004A169FB4a3325136EB29fA0ceB6D2e539a432`, Reputation
  `0x8004BAa17C55a88189AE136b182e5fdA19dE9b63`.
- **Verifikasi live 20 Nov 2026** (eth_call ke RPC publik BSC):
  Identity `getVersion()` → "2.0.0", `name()` → "AgentIdentity",
  `symbol()` → "AGENT"; Reputation `getVersion()` → "2.0.0" dan
  `getIdentityRegistry()` → alamat Identity di atas. Jalur baca profil
  diuji ujung-ke-ujung pada agent 0 (ownerOf, getAgentWallet,
  getClients → 2 klien, getSummary → count 2 / rata-rata 100).
- **Aturan feedback v2.0.0 yang menentukan desain** (dari source
  `ReputationRegistryUpgradeable.sol` resmi, bukan asumsi): TIDAK ada
  pre-otorisasi penulis; satu-satunya larangan = **self-feedback**
  (pemilik/operator/approved agent tidak boleh menilai agent-nya
  sendiri); penulis tercatat sebagai client; entri append-only
  1-indexed; `getSummary` = rata-rata dan **revert bila daftar klien
  kosong**; Identity Registry **tanpa enumerasi** (alamat → agentId
  hanya via event `Registered` yang owner-nya terindeks, atau dari
  pemiliknya langsung).
- Saldo ERC-8004 alamat BAW user saat cek: **0** (belum registrasi;
  langkah fase deploy, §5 butir 8).
- Konsekuensi yang sudah dibangun: `contracts/AgentId8004Bridge.sol`
  menerbitkan snapshot reputasi lokal (skor streak + jumlah pembayaran
  lunas) sebagai feedback ERC-8004 dengan ikatan kepemilikan
  terverifikasi saat tulis; profil web menjadi paspor 3-sinyal.

## 2. Token pembayaran di BSC

- **USDT BEP-20 resmi: `0x55d398326f99059fF775485246999027B3197955`**,
  18 desimal di BSC. Terverifikasi mandiri via RPC (19 Nov 2026):
  `symbol()` → `"USDT"`, `decimals()` → 18 ✔.
- AgentPay sendiri token-agnostik (menerima ERC-20 apa pun); USDT di atas
  hanya default di web app.

## 3. Biaya gas BSC (terukur, bukan perkiraan karangan)

- Gas price BSC saat riset (eth_gasPrice via RPC publik, 19 Nov 2026):
  **0,05 gwei** (0x2faf080 = 50.000.000 wei).
- Harga BNB saat riset: **$587,17** (CoinGecko simple price API, 19 Nov 2026).
- Gas deploy **diukur dari test lokal** (event GasUsed, forge test):

  | Kontrak | Gas deploy (konstruktor) |
  | --- | --- |
  | AgentStreak | 568.259 |
  | AgentPay | 952.436 |
  | ScoreGateDemo | 315.224 |
  | AgentId8004Bridge | 1.164.961 |
  | **Total** | **3.000.880** (±3,2 jt termasuk base cost tx) |

- Estimasi biaya deploy total: ±3,2 jt gas × 0,05 gwei ≈ **0,00016 BNB
  ≈ $0,09**. Bahkan pada 1 gwei ≈ $1,88; pada 5 gwei (macet) ≈ $9,40.
  Rekomendasi: siapkan **0,01 BNB (±$5,90)** di wallet deployer — cukup
  untuk deploy 4 kontrak + verifikasi ulang + beberapa tx uji pada
  harga gas normal; bila gas sedang di kisaran 5 gwei, tambah cadangan
  ±0,01 BNB lagi.
- Biaya tambahan fase jembatan di luar deploy: registrasi agent
  ERC-8004 proyek = 1 tx `register(string)` (estimasi kelas
  ±150–250 ribu gas, ≈ $0,01 pada harga riset; estimasi, bukan terukur
  lokal karena registri adalah kontrak eksternal) + tx publish pertama
  per holder (ditanggung holder yang mem-publish, kelas ±100 ribu gas).

## 4. Yang sudah dibangun (fase ini)

- `contracts/AgentStreak.sol` — check-in harian (1×/hari UTC), streak
  berjalan/terpanjang, total check-in, skor (1/check-in + bonus 5 tiap
  kelipatan 7 hari), view reputasi publik (`getStreak`, `getLongestStreak`,
  `getTotalCheckIns`, `getScore`, `isActive`, `hasCheckedInToday`,
  `getReputation`, `isAgentIdHolder`). Gerbang holder via registry resmi,
  aktif/nonaktif ditentukan saat konstruktor (deploy produksi: aktif).
- `contracts/AgentPay.sol` — permintaan pembayaran (payee = pembuat =
  holder terverifikasi; token ERC-20 apa pun; memo ≤140 char), pelunasan
  `transferFrom` langsung payer→payee (kontrak tidak pernah memegang dana),
  status Open/Paid/Cancelled, batal hanya oleh payee, bayar-sendiri ditolak,
  reputasi pembayaran dua arah (jumlah + volume per token).
- `contracts/ScoreGateDemo.sol` — kontrak demo pihak-ketiga: klaim badge
  "Trusted Agent" hanya bila `IAgentStreak.getScore(user) ≥ threshold`;
  satu-satunya kuasa owner demo = mengubah threshold (diungkap di README).
- `contracts/interfaces/` — `IAgentIdRegistry`, `IERC20Minimal`,
  `IAgentStreak` (interface reputasi publik untuk integrator lain).
- `test/` — 30 tes Foundry pada fase ini (harness cheatcode mandiri,
  tanpa forge-std): **30 lulus, 0 gagal**. Mencakup semua kasus wajib
  brief + gate demo. (Total suite setelah fase jembatan: 43 — lihat
  blok update di bawah.)
- `web/` — app statis mobile-first: `index.html` (connect wallet, streak,
  check-in, buat/bayar/batalkan permintaan), `profile.html?agent=<alamat>`
  (profil publik read-only via RPC publik: streak, skor, pembayaran lunas +
  volume, status badge Trusted Agent), `config.js` (alamat diisi
  pasca-deploy), `abi.js` (digenerate dari artefak kompilasi).
- Toolchain: Foundry **forge 1.4.4**, solc 0.8.24, optimizer 200 runs,
  EVM paris. Tanpa dependensi npm/submodule apa pun.

Update fase jembatan ERC-8004 (20 Nov 2026):

- `contracts/AgentId8004Bridge.sol` — kontrak terpisah (inti tidak
  diubah): baca status registrasi/kepemilikan ERC-8004 + agregat
  feedback; tulis snapshot reputasi lokal (skor streak, jumlah
  pembayaran lunas) sebagai feedback ERC-8004 dengan verifikasi
  kepemilikan agentId saat tulis dan anti-terbit-ulang-tanpa-perubahan.
- `contracts/interfaces/IERC8004Identity.sol`,
  `IERC8004Reputation.sol`, `IAgentPay.sol` — antarmuka terverifikasi
  dari repo resmi ERC-8004 + permukaan statistik AgentPay.
- `test/` — total **43 tes, 43 lulus**: 13 tes bridge baru dengan mock
  registri ERC-8004 (`test/mocks/Mock8004Identity.sol`,
  `Mock8004Reputation.sol`) yang meniru semantik v2.0.0.
- `web/` — profil menjadi paspor 3-sinyal: kartu ERC-8004 (status
  registrasi, agentId via parameter `&id8004=` atau pindai event
  `Registered`, wallet agent, ringkasan feedback, snapshot bridge);
  `config.js` memuat alamat registri ERC-8004 terverifikasi +
  `agentBridgeAddress` (diisi pasca-deploy); `abi.js` ditambah kunci
  `bridge`, `erc8004Identity`, `erc8004Reputation`.
- `BRIDGE.md` — keputusan desain + batasan standar + langkah deploy
  tambahan jembatan.

## 5. Rencana deploy (BELUM dijalankan — menunggu keputusan user)

1. **Wallet deployer yang disarankan**: wallet EVM biasa yang dikontrol
   user (bukan BAW — BAW punya batasan Developer Mode dan aturan main
   terpisah; deployer tidak perlu memegang Agent ID karena gerbang hanya
   berlaku untuk aksi pengguna, bukan deploy). Isi ±0,01 BNB untuk gas.
   Alternatif yang juga valid: alamat BAW user bila user menginginkannya
   sebagai deployer tercatat — keputusan user.
2. **Urutan deploy** (dari folder repo, setelah `forge build` bersih):
   - `forge create contracts/AgentStreak.sol:AgentStreak --rpc-url https://bsc-rpc.publicnode.com --private-key <DEPLOYER_KEY> --constructor-args 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F true`
   - `forge create contracts/AgentPay.sol:AgentPay ... --constructor-args 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F true`
   - `forge create contracts/ScoreGateDemo.sol:ScoreGateDemo ... --constructor-args <AGENTSTREAK_ADDRESS> 3`
   - `forge create contracts/AgentId8004Bridge.sol:AgentId8004Bridge ... --constructor-args 0x8004A169FB4a3325136EB29fA0ceB6D2e539a432 0x8004BAa17C55a88189AE136b182e5fdA19dE9b63 <AGENTSTREAK_ADDRESS> <AGENTPAY_ADDRESS>`
   (Kunci privat dimasukkan user sendiri di terminalnya; jangan pernah
   lewat chat.)
3. **Verifikasi BscScan** untuk keempat kontrak:
   `forge verify-contract <ADDRESS> contracts/<File>.sol:<Contract> --chain-id 56 --constructor-args <args terekode> --etherscan-api-key <BSCSCAN_API_KEY>`
   lalu cek halaman kontrak menampilkan source identik repo.
4. **Isi alamat hasil deploy** ke: tabel Deployment di README.md +
   `web/config.js` (`agentStreakAddress`, `agentPayAddress`,
   `scoreGateAddress`, `agentBridgeAddress`), commit, dan buat repo
   GitHub publik.
5. **Uji asap manual** dengan wallet holder asli (mis. BAW user): 1×
   check-in, 1× buat permintaan kecil, 1× bayar dari wallet kedua,
   buka halaman profil publik — semua tx ditandatangani pemilik wallet
   masing-masing.
5b. **Daftarkan proyek sebagai agent ERC-8004** (langkah fase
   jembatan; detail di BRIDGE.md §5): dari wallet deployer (atau BAW
   user bila user memilih identitas itu), panggil
   `register(string agentURI)` pada Identity Registry ERC-8004
   `0x8004A169FB4a3325136EB29fA0ceB6D2e539a432` dengan agentURI =
   tautan halaman web/repo publik proyek; catat agentId yang
   dikembalikan ke README + profil proyek. BUKAN lewat bridge.
   Uji asap jembatan: satu holder yang juga pemilik agent ERC-8004
   memanggil `publishAll` dari wallet-nya; verifikasi entri di
   `readFeedback(agentId, <BRIDGE_ADDRESS>, indeks)` dan tampil di
   kartu ERC-8004 profil publiknya.
6. **Submit formulir Binance** (tautan "Submit Project Now" di pengumuman —
   survei app.binance.com): nama proyek, website (repo/halaman web),
   alamat kontrak, deskripsi pemakaian Agent ID (akses + pembayaran +
   identitas + komposabilitas). **Klik submit terakhir oleh user** sesuai
   aturan main yang berlaku.
7. Setelah submit: rekrutmen holder asli (rencana terpisah di side chat
   'Agent ID Hackathon') — target ≥30 alamat holder untuk syarat
   Innovation, idealnya 50–100; semua interaksi organik dari wallet
   masing-masing holder.

## 6. Blocker / catatan

- Tidak ada blocker teknis. Satu-satunya yang menunggu: keputusan user
  soal wallet deployer + penyediaan ±0,01 BNB gas + eksekusi deploy
  (di luar batas keras fase ini).
- `foundryup` resmi macet di mesin ini (unduhan menggantung); forge 1.4.4
  dipasang dari tarball rilis GitHub resmi dan terverifikasi jalan.
