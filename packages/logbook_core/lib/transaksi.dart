import 'package:flutter/material.dart';

import 'logbook_service.dart';

/// Menjalankan satu transaksi tulis dan menampilkan statusnya di dialog.
/// Mengembalikan true kalau transaksi berhasil.
Future<bool> jalankanTransaksi(
  BuildContext context,
  LogbookService service, {
  required String judul,
  required Future<String> Function() kirim,
}) async {
  final hasil = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DialogTransaksi(
      service: service,
      judul: judul,
      kirim: kirim,
    ),
  );
  return hasil ?? false;
}

enum _Tahap { mengirim, menunggu, berhasil, gagal }

class _DialogTransaksi extends StatefulWidget {
  const _DialogTransaksi({
    required this.service,
    required this.judul,
    required this.kirim,
  });

  final LogbookService service;
  final String judul;
  final Future<String> Function() kirim;

  @override
  State<_DialogTransaksi> createState() => _DialogTransaksiState();
}

class _DialogTransaksiState extends State<_DialogTransaksi> {
  _Tahap _tahap = _Tahap.mengirim;
  String? _hash;
  String? _pesan;

  @override
  void initState() {
    super.initState();
    _jalankan();
  }

  Future<void> _jalankan() async {
    try {
      final hash = await widget.kirim();
      if (!mounted) return;
      setState(() {
        _hash = hash;
        _tahap = _Tahap.menunggu;
      });

      final receipt = await widget.service.tungguReceipt(hash);
      if (!mounted) return;

      if (receipt == null) {
        setState(() {
          _tahap = _Tahap.gagal;
          _pesan = 'Transaksi belum terkonfirmasi setelah 3 menit. '
              'Cek hash-nya di Etherscan.';
        });
        return;
      }

      final ok = receipt.status ?? true;
      setState(() {
        _tahap = ok ? _Tahap.berhasil : _Tahap.gagal;
        if (!ok) _pesan = 'Transaksi ditolak oleh kontrak (reverted).';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _tahap = _Tahap.gagal;
        _pesan = _ramahkan(e.toString());
      });
    }
  }

  String _ramahkan(String galat) {
    if (galat.toLowerCase().contains('insufficient funds')) {
      return 'Saldo Sepolia ETH tidak cukup untuk membayar gas. '
          'Minta dulu dari faucet.\n\n$galat';
    }
    return galat;
  }

  bool get _selesai =>
      _tahap == _Tahap.berhasil || _tahap == _Tahap.gagal;

  Widget _isi() {
    switch (_tahap) {
      case _Tahap.mengirim:
        return const Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Menunggu persetujuan di MetaMask...\n'
                'Buka MetaMask lalu setujui transaksinya.',
                ),
                ),
          ],
        );
      case _Tahap.menunggu:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                SizedBox(width: 16),
                Expanded(child: Text('Memproses, menunggu konfirmasi jaringan...')),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Hash transaksi:', style: TextStyle(fontSize: 12)),
            SelectableText(_hash ?? '', style: const TextStyle(fontSize: 12)),
          ],
        );
      case _Tahap.berhasil:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Berhasil', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Hash transaksi:', style: TextStyle(fontSize: 12)),
            SelectableText(_hash ?? '', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            const Text('Lihat di Etherscan:', style: TextStyle(fontSize: 12)),
            SelectableText(
              'https://sepolia.etherscan.io/tx/$_hash',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      case _Tahap.gagal:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Gagal', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText(_pesan ?? 'Terjadi kesalahan.'),
            if (_hash != null) ...[
              const SizedBox(height: 8),
              const Text('Hash transaksi:', style: TextStyle(fontSize: 12)),
              SelectableText(_hash!, style: const TextStyle(fontSize: 12)),
            ],
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selesai,
      child: AlertDialog(
        title: Text(widget.judul),
        content: SingleChildScrollView(child: _isi()),
        actions: [
          if (_selesai)
            TextButton(
              onPressed: () => Navigator.of(context).pop(_tahap == _Tahap.berhasil),
              child: const Text('Tutup'),
            ),
        ],
      ),
    );
  }
}