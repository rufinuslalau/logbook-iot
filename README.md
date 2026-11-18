# Logbook Peminjaman Alat Lab IoT (Flutter + Blockchain Sepolia)

Proyek Pemrograman Mobile 2, D4 Teknologi Rekayasa Komputer, Jurusan Teknologi Informasi, Prodi Teknologi Rekayasa Komputer, Politeknik Negeri Samarinda.

**Kelompok:** Kelompok_2
**Anggota:** Endang_Sulistiowati(246662023), Rufinus Arnold Lalau(246664004), Bintang Adi Darma(246662012), Andri Fikriy Fahrezi(246662020), Kamelius Avong(246664001), Maria Elyntia Mayang(246664002) 

## Gambaran

Sistem pencatatan peminjaman alat Lab IoT yang datanya disimpan di smart contract (jaringan uji **Sepolia**), bukan di server atau database lokal. Terdiri dari dua aplikasi Flutter:

- **Aplikasi User**: melihat alat, mengajukan peminjaman, dan melihat riwayat peminjaman miliknya.
- **Aplikasi Admin**: menambah alat, menyetujui atau menolak pengajuan, mengonfirmasi pengembalian, dan melihat seluruh logbook.

Wallet dihubungkan lewat **MetaMask (WalletConnect / Reown AppKit)**. Kunci privat tidak pernah ada di aplikasi maupun di repositori. Setiap transaksi tulis ditandatangani di MetaMask. Aplikasi mendeteksi sendiri apakah wallet yang terhubung adalah admin atau user.

## Smart contract

| Item | Nilai |
|---|---|
| Jaringan | Ethereum Sepolia (chain ID 11155111) |
| Alamat kontrak | `0x22B8B37DE0aE5404171C0716c682442f19A1e817` |
| Etherscan | https://sepolia.etherscan.io/address/0x22B8B37DE0aE5404171C0716c682442f19A1e817 |
| Source | `contracts/LogbookAlat.sol` (terverifikasi di Etherscan) |

Wallet admin adalah akun yang men-deploy kontrak (`admin` diisi di constructor).

| Fungsi | Dipanggil oleh | Keterangan |
|---|---|---|
| `tambahAlat(nama)` | Admin | Menambah alat baru (status tersedia) |
| `ajukanPinjam(idAlat, nimHash)` | Siapa saja (user) | Mengajukan pinjam, status Diajukan |
| `setujuiPinjam(id)` | Admin | Status Dipinjam, waktu pinjam dicatat, alat tidak tersedia |
| `tolakPinjam(id)` | Admin | Status Ditolak |
| `konfirmasiKembali(id)` | Admin | Status Dikembalikan, waktu kembali dicatat, alat tersedia lagi |
| `jumlahAlat`, `ambilAlat`, `jumlahPinjam`, `ambilPinjam`, `admin` | Siapa saja | Fungsi baca (view), gratis |

Data yang dicatat on-chain: nama alat, alamat wallet peminjam, **hash NIM** (246664004, bukan NIM asli), waktu pinjam, waktu kembali, dan status. Tidak ada nama lengkap atau NIM asli di blockchain.

Alur peminjaman: Admin tambah alat → User ajukan pinjam → Admin setujui atau tolak → Admin konfirmasi saat alat dikembalikan.

## Struktur repositori

```
logbook-iot/
├─ contracts/LogbookAlat.sol     Smart contract Solidity
├─ packages/logbook_core/        Kode bersama: ABI, service web3dart, koneksi wallet, tampilan
├─ apps/user_app/                Aplikasi User
├─ apps/admin_app/               Aplikasi Admin
└─ README.md
```

## Fitur

**Fitur wajib**
- Kontrak ter-deploy dan terverifikasi di Sepolia.
- Daftar alat dan logbook membaca data dari kontrak (`jumlahAlat`, `ambilAlat`, `jumlahPinjam`, `ambilPinjam`), status ditampilkan dengan warna dan label berbeda.
- Form ajukan pinjam (user) dan tambah alat (admin) yang mengirim transaksi.
- Tombol setujui, tolak, dan konfirmasi kembali (admin) yang mengirim transaksi.
- Indikator status transaksi: menunggu persetujuan wallet, memproses, berhasil (dengan hash transaksi), dan gagal (dengan pesan error).
- Tombol refresh di AppBar dan tarik-untuk-memuat-ulang.
- Alamat kontrak, RPC URL, dan chain ID disimpan di satu berkas konfigurasi (`.env`), tidak tersebar di kode.

**Fitur bonus**
- Koneksi wallet lewat WalletConnect/Reown sehingga kunci privat tidak berada di aplikasi.
- Deteksi otomatis peran wallet (admin atau user) dengan membaca `admin()` dari kontrak.
- Filter status pada riwayat/logbook (Semua, Diajukan, Dipinjam, Dikembalikan, Ditolak).
- Dashboard ringkasan (total alat, tersedia, menunggu persetujuan, sedang digunakan).

## Versi paket

| Paket | Versi |
|---|---|
| Flutter | Flutter 3.47.0 |
| Dart | Dart 3.13.0 |
| web3dart | web3dart: 2.7.3 |
| http | http: ^1.6.0 |
| flutter_dotenv | flutter_dotenv 6.0.2 |
| reown_appkit | reown_appkit 1.7.6 |
| Solidity | 0.8.20+commit.a1b79de6, optimization OFF, EVM version default (osaka) |

## Cara menjalankan

### Prasyarat
- Flutter SDK dan Android Studio (atau HP Android dengan USB debugging)
- MetaMask (mobile) dengan **dua akun**: satu akun admin (akun yang men-deploy kontrak) dan satu akun user, keduanya di jaringan Sepolia dengan saldo Sepolia ETH dari faucet
- RPC endpoint Sepolia dari Alchemy atau Infura (akun gratis)
- Project ID dari https://dashboard.reown.com

### Langkah

1. Clone repositori:
   ```bash
   git clone https://github.com/rufinuslalau/logbook-iot.git
   cd logbook-iot
   ```
2. Buat berkas `.env` di **kedua** aplikasi dengan menyalin `.env.example`:
   ```bash
   cd apps/user_app
   cp .env.example .env
   cd ../admin_app
   cp .env.example .env
   ```
   Di Windows PowerShell gunakan `Copy-Item .env.example .env`.
3. Isi `.env` (nilainya sama untuk kedua aplikasi):
   ```
   RPC_URL=URL_RPC_SEPOLIA
   CHAIN_ID=11155111
   CONTRACT_ADDRESS=0x22B8B37DE0aE5404171C0716c682442f19A1e817
   REOWN_PROJECT_ID=PROJECT_ID_REOWN
   ```
4. Daftarkan package name aplikasi (`com.example.user_app` dan `com.example.admin_app`) di dashboard Reown pada menu *Mobile Application IDs*.
5. Jalankan tiap aplikasi:
   ```bash
   cd apps/user_app
   flutter pub get
   flutter run
   ```
   Ulangi untuk `apps/admin_app`.
6. Di aplikasi, tekan **Hubungkan Wallet**, pilih MetaMask (atau scan QR dari MetaMask di HP), lalu setujui koneksi dengan akun yang sesuai: akun admin untuk Aplikasi Admin, akun user untuk Aplikasi User.

### Build APK

```bash
cd apps/user_app
flutter build apk --release
cd ../admin_app
flutter build apk --release
```

Hasil ada di `build/app/outputs/flutter-apk/app-release.apk` pada masing-masing aplikasi.

## Keamanan

- Hanya jaringan uji Sepolia. Tidak ada transaksi di mainnet dan tidak ada pembelian kripto.
- Wallet khusus tugas, bukan wallet pribadi.
- Kunci privat dan seed phrase **tidak** ada di kode maupun repositori. Transaksi ditandatangani di MetaMask.
- Berkas `.env` masuk `.gitignore`. Yang di-commit hanya `.env.example` tanpa nilai rahasia.
- Data pribadi tidak disimpan on-chain: NIM di-hash sebelum dikirim ke kontrak.

## Pengumpulan

| Luaran | Tautan |
|---|---|
| Link Download Applikasi | https://drive.google.com/file/d/1WxakBBdB_NTMtVyE435QaWb8Hx0AyOI8/view?usp=sharing |
| Video demo | ISI_LINK_VIDEO_DEMO |
| Laporan singkat (PDF) | ISI_LINK_LAPORAN |

## Sumber kode yang diadaptasi

- Kerangka kontrak `ChainTodo` dan pola fungsi `jumlah*` / `ambil*` (view) serta event dari dokumen Tugas Proyek dosen, dikembangkan menjadi kontrak `LogbookAlat` dengan peran admin dan alur persetujuan.
- Video tutorial referensi (Build a Blockchain dApp with Flutter and Dart on Ethereum; Build Your First Blockchain Flutter App) untuk alur Flutter → RPC → smart contract dengan `web3dart`.
- Dokumentasi `web3dart` (pub.dev) untuk pemanggilan fungsi baca kontrak.
- Dokumentasi Reown AppKit untuk Flutter (docs.reown.com) untuk koneksi wallet dan `requestWriteContract`.
- Bantuan AI (Claude) digunakan untuk membantu menyusun dan men-debug kode. Seluruh anggota memahami dan dapat menjelaskan kode yang dikumpulkan.