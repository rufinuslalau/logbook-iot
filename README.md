# Logbook Peminjaman Alat Lab IoT

Aplikasi Flutter satu aplikasi untuk admin dan user yang mencatat peminjaman alat Lab IoT di smart contract jaringan **Sepolia** (chain ID `11155111`), dengan koneksi wallet lewat Reown AppKit (MetaMask).

## Cara menjalankan

1. Clone repositori ini dan masuk ke folder aplikasi:

   ```bash
   git clone ISI_URL_REPOSITORI
   cd logbook-iot/apps/user_app
   ```

2. Salin `.env.example` menjadi `.env` (Windows PowerShell: `Copy-Item .env.example .env`), lalu isi:

   ```
   RPC_URL=https://eth-sepolia.g.alchemy.com/v2/API_KEY
   CHAIN_ID=11155111
   CONTRACT_ADDRESS=0x22B8B37DE0aE5404171C0716c682442f19A1e817
   REOWN_PROJECT_ID=PROJECT_ID
   ```

   `RPC_URL` dan `REOWN_PROJECT_ID` diisi dengan milik sendiri (Alchemy/Infura dan dashboard.reown.com). Package name `com.example.user_app` perlu didaftarkan di dashboard Reown (*Mobile Application IDs*).

3. Unduh dependensi dan jalankan aplikasi:

   ```bash
   flutter pub get
   flutter run
   ```

4. Tekan **Hubungkan Wallet** dan pilih MetaMask (jaringan Sepolia). Wallet yang menjadi `admin` di kontrak masuk sebagai Admin, wallet lain masuk sebagai User. Transaksi ditandatangani di MetaMask, aplikasi tidak menyimpan private key.

## Versi paket

| Paket | Versi |
| --- | ---: |
| Flutter | `3.47.0` |
| Dart | `3.13.0` |
| `web3dart` | `2.7.3` |
| `reown_appkit` | `1.7.6` |
| `flutter_dotenv` | `6.0.2` |
| `http` | `1.6.0` |

## Alamat kontrak

- Jaringan : [Ethereum Sepolia](https://sepolia.etherscan.io/)
- Alamat Contract : [0x8f7815824B13FA30EA9F954Bfb037c5634Aec441](https://sepolia.etherscan.io/address/0x8f7815824B13FA30EA9F954Bfb037c5634Aec441) 
- Sumber Smart contract : [contracts/LogbookAlat.sol](https://github.com/rufinuslalau/logbook-iot/blob/main/contracts/LogbookAlat.sol)
- ABI yang digunakan : [packages/logbook_core/lib/abi.dart](https://github.com/rufinuslalau/logbook-iot/blob/main/packages/logbook_core/lib/abi.dart)
