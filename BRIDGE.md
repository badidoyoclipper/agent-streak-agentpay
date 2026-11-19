# BRIDGE — Jembatan ERC-8004: keputusan desain & batasan standar

Dokumen kerja internal (Bahasa Indonesia). Ditulis 20 Nov 2026, fase
"adopsi bertahap" (keputusan user 20 Nov 2026 ±00:00 WIB): jembatan
ERC-8004 dibangun sekarang; mode Job ERC-8183 DITUNDA sampai setelah
submit inti aman dan TIDAK dibangun fase ini.
Status: kode + tes selesai lokal (suite penuh 43/43 lulus), belum deploy.

---

## 1. Antarmuka ERC-8004 yang terverifikasi (bukan ingatan)

Sumber kebenaran: repo resmi `erc-8004/erc-8004-contracts` (branch
`master`, dibaca ulang file per file fase ini) + verifikasi live ke BSC
mainnet via RPC publik (eth_call, 20 Nov 2026).

**Alamat kanonis mainnet** (dari `scripts/addresses.ts` repo resmi,
`MAINNET_ADDRESSES` — alamat CREATE2 vanity yang sama di semua mainnet,
termasuk BSC chain 56):

- Identity Registry: `0x8004A169FB4a3325136EB29fA0ceB6D2e539a432`
- Reputation Registry: `0x8004BAa17C55a88189AE136b182e5fdA19dE9b63`

**Verifikasi live (20 Nov 2026):**

- Identity: `getVersion()` → `"2.0.0"`, `name()` → `"AgentIdentity"`,
  `symbol()` → `"AGENT"` ✔
- Reputation: `getVersion()` → `"2.0.0"`, `getIdentityRegistry()` →
  `0x8004A169…39a432` (tertambat ke Identity Registry yang benar) ✔
- Jalur baca profil diuji persis seperti yang akan dipakai web:
  `ownerOf(0)` → `0x8CE2b1348740D27d6075F602Ad679a041407fdEc`;
  `getAgentWallet(0)` → alamat yang sama; `getClients(0)` → 2 klien;
  `getSummary(0, clients, "", "")` → count 2, rata-rata 100, desimal 0 ✔
- Saldo ERC-8004 alamat BAW user (`0x811f…Fc3fD`): **0** — user belum
  mendaftarkan agent ERC-8004; itu langkah fase deploy (lihat §5).

**Fungsi persis yang dipakai** (ABI diambil dari `abis/*.json` repo
resmi):

- Identity (ERC-721 "AGENT", UUPS proxy): `balanceOf(address)`,
  `ownerOf(uint256)`, `getAgentWallet(uint256)`,
  `getMetadata(uint256,string)`, `tokenURI(uint256)`,
  `isAuthorizedOrOwner(address,uint256)`,
  `register(string)` → agentId sekuensial mulai dari 0.
- Reputation: `giveFeedback(uint256 agentId, int128 value,
  uint8 valueDecimals, string tag1, string tag2, string endpoint,
  string feedbackURI, bytes32 feedbackHash)`,
  `revokeFeedback(uint256,uint64)`,
  `getLastIndex(uint256,address)` → uint64,
  `readFeedback(uint256,address,uint64)` → (value, valueDecimals,
  tag1, tag2, isRevoked),
  `getSummary(uint256,address[],string,string)` → (count, rata-rata,
  desimal modus), `getClients(uint256)`, `getIdentityRegistry()`.

File antarmuka kita: `contracts/interfaces/IERC8004Identity.sol` dan
`IERC8004Reputation.sol` (komentar di dalamnya memuat temuan ini juga).

## 2. Batasan standar yang ditemukan (dari source kontrak referensi v2.0.0)

Ini bagian terpenting fase ini — aturan main feedback ERC-8004
ternyata spesifik:

1. **Tidak ada mekanisme pre-otorisasi / accept-list di versi yang
   terdeploy.** Dugaan awal ("klien harus diotorisasi dulu oleh pemilik
   agent") TIDAK berlaku di kontrak v2.0.0: `giveFeedback` boleh
   dipanggil siapa pun. Satu-satunya gerbang:
2. **Self-feedback dilarang keras.** `giveFeedback` revert bila
   `msg.sender` adalah pemilik agent, operator (approved-for-all),
   atau alamat yang di-approve untuk agent itu
   (`isAuthorizedOrOwner` di Identity Registry). Juga revert bila
   agentId tidak ada (lewat `ownerOf` di cek yang sama).
3. **Penulis feedback = `msg.sender`, tercatat sebagai
   `clientAddress`.** Entri terindeks 1-based per (agentId, client),
   append-only. Hanya penulis asli yang bisa `revokeFeedback` entri
   miliknya; entri yang direvoke dikeluarkan dari ringkasan.
4. **Nilai bertanda fixed-point:** |value| ≤ 1e38, valueDecimals ≤ 18.
5. **`getSummary` adalah RATA-RATA** dari entri non-revoke milik
   daftar klien yang diberikan, dinormalisasi ke 18 desimal lalu
   diskalakan ke desimal yang paling sering muncul (modus). Dan ia
   **REVERT bila `clientAddresses` kosong** — pemanggil wajib memberi
   minimal satu klien (pakai `getClients` untuk menemukannya). String
   tag kosong = wildcard.
6. **Identity Registry TIDAK punya enumerasi** (bukan ERC721Enumerable:
   tidak ada `tokenOfOwnerByIndex`/`totalSupply`). Memetakan alamat →
   agentId tidak bisa dilakukan murni on-chain; jalurnya adalah event
   `Registered(uint256 indexed agentId, string agentURI,
   address indexed owner)` (owner terindeks → bisa difilter off-chain)
   atau agentId diberikan langsung oleh pemiliknya.
7. `register()` menetapkan metadata khusus `agentWallet` = pendaftar;
   pemilik bisa menggantinya lewat `setAgentWallet` dengan tanda tangan
   EIP-712 dari wallet baru. Transfer NFT agent mengosongkan
   `agentWallet`.

Konsekuensi desain dari (5): karena summary me-rata-rata semua entri,
bridge TIDAK menulis feedback per kejadian (yang akan mengencerkan
makna), melainkan **snapshot kumulatif** — nilai terbaru adalah
kebenaran mutakhir, dan konsumen yang butuh nilai mutakhir membaca
entri terakhir bridge (indeks tersimpan di bridge), bukan rata-rata
mentah. Ini didokumentasikan terbuka di README agar tidak ada yang
salah membaca angka summary.

## 3. Desain jembatan (`contracts/AgentId8004Bridge.sol`)

Kontrak terpisah; kontrak inti (AgentStreak/AgentPay/ScoreGateDemo)
TIDAK diubah sama sekali — bridge hanya MEMBACA mereka lewat interface
(`IAgentStreak.getScore`, `IAgentPay.getStats`).

**Baca (view, tanpa status):**

- `isRegistered8004(user)` / `agentCount8004(user)` — dari
  `balanceOf` Identity Registry.
- `ownsAgent8004(user, agentId)` — `ownerOf` dibungkus try/catch:
  agentId yang tidak ada menghasilkan `false`, bukan revert, supaya
  UI bisa mem-probe dengan aman.
- `getAgentWallet8004(agentId)`, `getAgentURI8004(agentId)` —
  passthrough.
- `getSummary8004(agentId, clients, tag1, tag2)` — passthrough apa
  adanya (termasuk perilaku revert klien-kosong milik registry;
  diuji dan didokumentasikan, tidak disembunyikan).
- `getPublishedSnapshot(agentId, channel)` — snapshot terakhir yang
  ditulis bridge: (nilai, indeks feedback). Indeks 0 = belum pernah.
- `previewPublish(user, agentId)` — nilai yang akan ditulis sekarang
  + flag stale per kanal; untuk status tombol "sync" di UI.

**Tulis (publish):**

- Dua kanal: kanal 0 streak → value = `AgentStreak.getScore(user)`,
  tag `agentstreak`/`score`; kanal 1 pembayaran → value =
  `paymentsReceived` dari `AgentPay.getStats(user)`, tag
  `agentpay`/`paymentsReceived`. Keduanya valueDecimals 0.
- `publishStreakScore(user, agentId)`, `publishPaymentsReceived(user,
  agentId)` (mode ketat: revert bila nilai 0 → `NoReputation`, atau
  tidak berubah → `AlreadyCurrent`), dan `publishAll(user, agentId)`
  (mode longgar per kanal: kanal kosong/tidak berubah dilewati;
  revert `NothingToPublish` hanya bila keduanya tidak bisa terbit).
- **Ikat identitas diverifikasi saat tulis:** setiap publish memanggil
  `ownerOf(agentId)` dan revert `AgentNotOwned` kecuali pemiliknya
  persis `user`. Nilai dihitung bridge dari kontrak sumber — pemanggil
  tidak bisa menyuntik, memilih, atau menaikkan nilai. Karena itu
  publish boleh dipanggil SIAPA PUN (keeper, teman, user lain):
  yang dijamin bukan pemanggilnya, melainkan datanya.
- **Anti-spam bawaan:** kanal hanya diterbitkan ulang bila nilainya
  berubah sejak snapshot terakhir bridge (tersimpan per agentId).
  Biaya gas publish ulang yang sia-sia dan pengenceran summary
  terhindar secara konstruksi.
- `feedbackHash = keccak256(abi.encode(tag1, tag2, agentId, user,
  value))` — komitmen ke data persis yang disahkan, bisa dicocokkan
  siapa pun ke status on-chain AgentStreak/AgentPay saat itu.
  `endpoint`/`feedbackURI` dikosongkan: buktinya on-chain, bukan file
  off-chain.
- Event `ReputationPublished(agentId, user, channel, value,
  feedbackIndex)` setiap terbit.

**Kenapa desain ini sah menurut standar (§2):** penulis feedback
adalah bridge (client), subjeknya agent milik orang lain — pola
persis yang dimaksud standar (klien menilai agent). Larangan
self-feedback tidak mungkin dilanggar secara struktural: bridge tidak
memiliki agent apa pun, dan subjek wajib pemilik agent yang dinilai.
(Tes `testRegistryRejectsSelfFeedback` mengunci aturan registri ini
di level mock: pemilik yang mencoba menilai agent-nya sendiri
ditolak — alasan bridge tidak pernah dirancang menilai agent miliknya
sendiri.)

**Yang sengaja TIDAK dibuat:**

- **Tidak ada jalur revoke di bridge.** Standar hanya mengizinkan
  penulis mencabut entrinya; memberi pihak lain tombol pencabutan
  atas riwayat atestasi akan merusak nilai riwayat itu. Entri lama
  digantikan snapshot yang lebih baru berdasarkan indeks.
- **Tidak ada registrasi agent lewat bridge.** `register()` selalu
  dari wallet pemilik langsung (lihat §5) — bridge tidak pernah
  menjadi perantara identitas siapa pun.
- **Tidak ada owner/admin/pause/upgrade di bridge; tidak memegang
  dana.** Empat alamat yang diajak bicara adalah immutable konstruktor.
- Volume pembayaran per token tidak diterbitkan sebagai kanal
  (nilainya tergantung token; hitungan `paymentsReceived` adalah
  sinyal lintas-token yang jujur). Kandidat pengembangan berikutnya,
  bukan sekarang.

## 4. Web — profil paspor 3-sinyal

`web/profile.html` + `profile.js` kini punya kartu "ERC-8004
passport": status terdaftar + jumlah agent, agentId, wallet agent
terverifikasi, jumlah entri feedback + rata-ratanya (dari
`getClients` → `getSummary`), dan snapshot terakhir bridge per kanal.

- Alamat registri di `web/config.js` (`erc8004Identity`,
  `erc8004Reputation`) sebagai konstanta mainnet terverifikasi;
  `agentBridgeAddress` menyusul pasca-deploy seperti alamat lain.
- Penemuan agentId: parameter URL `&id8004=<id>` didahulukan; bila
  tidak ada, halaman memindai event `Registered` mundur per potongan
  100 ribu blok (maks ±4 juta blok) lewat RPC publik — best-effort,
  dan kegagalannya tampil sebagai petunjuk memakai parameter, bukan
  halaman rusak. Bagian ERC-8004 dirender independen dari status
  deploy kontrak inti (registri global memang sudah live).
- ABI web ditambah dari artefak resmi: `erc8004Identity`,
  `erc8004Reputation` (subset dari ABI repo resmi) dan `bridge`
  (dari artefak kompilasi kita).

## 5. Langkah deploy tambahan (BELUM dijalankan — fase deploy)

Di luar rencana deploy inti di RESEARCH.md §5:

1. Deploy bridge setelah AgentStreak + AgentPay:
   `forge create contracts/AgentId8004Bridge.sol:AgentId8004Bridge
   --rpc-url https://bsc-rpc.publicnode.com --private-key <DEPLOYER_KEY>
   --constructor-args 0x8004A169FB4a3325136EB29fA0ceB6D2e539a432
   0x8004BAa17C55a88189AE136b182e5fdA19dE9b63 <AGENTSTREAK_ADDRESS>
   <AGENTPAY_ADDRESS>` lalu `forge verify-contract` seperti kontrak
   lain, dan isi `agentBridgeAddress` di `web/config.js` + tabel
   Deployment README.
2. **Daftarkan proyek sebagai agent ERC-8004** (satu tx dari wallet
   deployer, atau dari BAW user bila user memilih identitas itu):
   panggil `register(string agentURI)` pada Identity Registry
   `0x8004A169…39a432` dengan agentURI menunjuk dokumen agent proyek
   (halaman web/repo publik). Wallet pendaftar menjadi pemilik agent
   + `agentWallet` awal. Simpan agentId yang dikembalikan untuk
   README/profil proyek. Catatan: ini pendaftaran identitas proyek —
   BUKAN lewat bridge, dan tidak memengaruhi alur holder.
3. Uji asap tambahan: satu holder (yang juga punya agent ERC-8004)
   melakukan `publishAll` pertamanya dari web/wallet-nya; cek entri
   muncul di `readFeedback(agentId, <bridge>, idx)` dan di profil
   publiknya.

**Gas tambahan terukur** (pola ukur yang sama: event GasUsed di tes):
deploy AgentId8004Bridge = **1.164.961 gas**. Pada gas price riset
0,05 gwei ≈ 0,00006 BNB (≈ $0,03); registrasi agent ERC-8004 satu tx
`register(string)` kelas ±150–250 ribu gas (≈ $0,01 pada harga riset)
— angka registrasi ini estimasi kelas, bukan terukur lokal, karena
registri adalah kontrak eksternal. Total tambahan terhadap rencana
awal tetap jauh di bawah cadangan 0,01 BNB yang sudah disiapkan.

## 6. Hasil tes fase ini

Suite penuh: **43 lulus, 0 gagal** (30 lama tidak berubah + 13 baru
di `test/AgentId8004Bridge.t.sol`, dengan mock
`test/mocks/Mock8004Identity.sol` dan `Mock8004Reputation.sol` yang
meniru semantik registri v2.0.0 termasuk larangan self-feedback dan
algoritma getSummary-nya).

Cakupan baru: baca status registrasi & kepemilikan (termasuk agentId
tidak ada → tertangani), wallet/URI passthrough, publish kanal streak
(nilai + tag + indeks + snapshot), publish ulang tanpa perubahan →
revert, publish lanjutan setelah check-in baru + rata-rata summary
(3 dan 4 → count 2, nilai 3), publish kanal pembayaran, publishAll
dua kanal sekaligus (indeks bersama 1 & 2) + revert saat tidak ada
yang baru, previewPublish, publish untuk non-pemilik → revert,
agentId tidak ada → revert, subjek tanpa reputasi → revert,
getSummary klien kosong → revert (aturan registri), larangan
self-feedback di registri, dan gas deploy bridge.
