# RESEARCH — Agent ID Hackathon: riset & rencana deploy

Dokumen kerja internal (Bahasa Indonesia). Semua klaim teknis di bawah punya
sumber; yang tidak terverifikasi dinyatakan apa adanya.
Status per 19 Nov 2026 ±23:55 WIB: riset selesai, kontrak + tes selesai
(30/30 lulus lokal), **belum ada deploy apa pun**.

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
  | **Total** | **1.835.919** (±2,0 jt termasuk base cost tx) |

- Estimasi biaya deploy total: ±2,0 jt gas × 0,05 gwei ≈ **0,0001 BNB
  ≈ $0,06**. Bahkan pada 1 gwei ≈ $1,17; pada 5 gwei (macet) ≈ $5,90.
  Rekomendasi: siapkan **0,01 BNB (±$5,90)** di wallet deployer — lebih dari
  cukup untuk deploy 3 kontrak + verifikasi ulang + beberapa tx uji.

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
- `test/` — 30 tes Foundry (harness cheatcode mandiri, tanpa forge-std):
  **30 lulus, 0 gagal**. Mencakup semua kasus wajib brief + gate demo.
- `web/` — app statis mobile-first: `index.html` (connect wallet, streak,
  check-in, buat/bayar/batalkan permintaan), `profile.html?agent=<alamat>`
  (profil publik read-only via RPC publik: streak, skor, pembayaran lunas +
  volume, status badge Trusted Agent), `config.js` (alamat diisi
  pasca-deploy), `abi.js` (digenerate dari artefak kompilasi).
- Toolchain: Foundry **forge 1.4.4**, solc 0.8.24, optimizer 200 runs,
  EVM paris. Tanpa dependensi npm/submodule apa pun.

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
   (Kunci privat dimasukkan user sendiri di terminalnya; jangan pernah
   lewat chat.)
3. **Verifikasi BscScan** untuk ketiga kontrak:
   `forge verify-contract <ADDRESS> contracts/<File>.sol:<Contract> --chain-id 56 --constructor-args <args terekode> --etherscan-api-key <BSCSCAN_API_KEY>`
   lalu cek halaman kontrak menampilkan source identik repo.
4. **Isi alamat hasil deploy** ke: tabel Deployment di README.md +
   `web/config.js` (`agentStreakAddress`, `agentPayAddress`,
   `scoreGateAddress`), commit, dan buat repo GitHub publik.
5. **Uji asap manual** dengan wallet holder asli (mis. BAW user): 1×
   check-in, 1× buat permintaan kecil, 1× bayar dari wallet kedua,
   buka halaman profil publik — semua tx ditandatangani pemilik wallet
   masing-masing.
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
