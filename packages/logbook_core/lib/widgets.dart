import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';

import 'logbook_service.dart';
import 'models.dart';
import 'transaksi.dart';

/// Banner atas: peran, alamat wallet, saldo, dan (opsional) cek admin.
class BannerWallet extends StatefulWidget {
  const BannerWallet({
    super.key,
    required this.service,
    required this.peran,
    this.cekAdmin = false,
  });

  final LogbookService service;
  final String peran;
  final bool cekAdmin;

  @override
  State<BannerWallet> createState() => _BannerWalletState();
}

class _BannerWalletState extends State<BannerWallet> {
  late Future<String> _future;

  @override
  void initState() {
    super.initState();
    _future = _muat();
  }

  Future<String> _muat() async {
    final saldo = await widget.service.saldo();
    final eth = saldo.getValueInUnit(EtherUnit.ether).toStringAsFixed(4);
    final alamat = singkatAlamat(widget.service.myAddress.hexEip55);
    var teks = '${widget.peran} • $alamat • $eth ETH';
    if (widget.cekAdmin) {
      final admin = await widget.service.sayaAdalahAdmin();
      teks += admin ? ' • Admin ✓' : ' • BUKAN admin ✗';
    }
    return teks;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FutureBuilder<String>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return Text(
              'Gagal terhubung: ${snap.error}',
              style: const TextStyle(color: Colors.red),
            );
          }
          if (!snap.hasData) return const Text('Menghubungkan ke Sepolia...');
          return Text(snap.data!);
        },
      ),
    );
  }
}

class _PesanScroll extends StatelessWidget {
  const _PesanScroll(this.teks);

  final String teks;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [Text(teks, textAlign: TextAlign.center)],
    );
  }
}

Future<String?> _mintaTeks(
  BuildContext context, {
  required String judul,
  required String label,
  String? bantuan,
}) {
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(judul),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bantuan != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(bantuan, style: const TextStyle(fontSize: 12)),
            ),
          TextField(
            controller: c,
            autofocus: true,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            final t = c.text.trim();
            if (t.isNotEmpty) Navigator.pop(ctx, t);
          },
          child: const Text('Lanjut'),
        ),
      ],
    ),
  );
}

/// Daftar alat. bisaPinjam = tombol Pinjam (app user),
/// bisaTambah = tombol Tambah alat (app admin).
class DaftarAlatView extends StatefulWidget {
  const DaftarAlatView({
    super.key,
    required this.service,
    this.bisaPinjam = false,
    this.bisaTambah = false,
  });

  final LogbookService service;
  final bool bisaPinjam;
  final bool bisaTambah;

  @override
  State<DaftarAlatView> createState() => _DaftarAlatViewState();
}

class _DaftarAlatViewState extends State<DaftarAlatView> {
  late Future<List<Alat>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.ambilSemuaAlat();
  }

  Future<void> _refresh() async {
    final baru = widget.service.ambilSemuaAlat();
    setState(() {
      _future = baru;
    });
    try {
      await baru;
    } catch (_) {}
  }

  Future<void> _pinjam(Alat a) async {
    final nim = await _mintaTeks(
      context,
      judul: 'Pinjam ${a.nama}',
      label: 'NIM',
      bantuan: 'NIM di-hash sebelum dikirim ke blockchain, '
          'jadi tidak tersimpan dalam bentuk aslinya.',
    );
    if (nim == null || !mounted) return;

    final ok = await jalankanTransaksi(
      context,
      widget.service,
      judul: 'Mengajukan pinjam ${a.nama}',
      kirim: () => widget.service.ajukanPinjam(a.id, nim),
    );
    if (!ok) return;
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengajuan terkirim. Menunggu persetujuan admin.')),
    );
  }

  Future<void> _tambah() async {
    final nama = await _mintaTeks(
      context,
      judul: 'Tambah alat',
      label: 'Nama alat',
    );
    if (nama == null || !mounted) return;

    final ok = await jalankanTransaksi(
      context,
      widget.service,
      judul: 'Menambah alat',
      kirim: () => widget.service.tambahAlat(nama),
    );
    if (ok) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: widget.bisaTambah
          ? FloatingActionButton.extended(
              onPressed: _tambah,
              icon: const Icon(Icons.add),
              label: const Text('Tambah alat'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Alat>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return _PesanScroll('Gagal memuat data:\n${snap.error}');
            }
            final data = snap.data!;
            if (data.isEmpty) {
              return const _PesanScroll(
                'Belum ada alat.\nTarik ke bawah untuk memuat ulang.',
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: data.length,
              itemBuilder: (context, i) {
                final a = data[i];
                return ListTile(
                  leading: Icon(
                    a.tersedia ? Icons.check_circle : Icons.block,
                    color: a.tersedia ? Colors.green : Colors.red,
                  ),
                  title: Text(a.nama),
                  subtitle: Text(
                    a.tersedia ? 'Tersedia' : 'Sedang dipinjam',
                  ),
                  trailing: (widget.bisaPinjam && a.tersedia)
                      ? FilledButton.tonal(
                          onPressed: () => _pinjam(a),
                          child: const Text('Pinjam'),
                        )
                      : Text('#${a.id}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _DataPinjam {
  _DataPinjam(this.alat, this.pinjam);

  final List<Alat> alat;
  final List<Peminjaman> pinjam;
}

Color _warnaStatus(StatusPinjam s) {
  switch (s) {
    case StatusPinjam.diajukan:
      return Colors.orange;
    case StatusPinjam.dipinjam:
      return Colors.blue;
    case StatusPinjam.dikembalikan:
      return Colors.green;
    case StatusPinjam.ditolak:
      return Colors.red;
  }
}

/// Logbook peminjaman. hanyaMilikSaya = true untuk app user,
/// aksiAdmin = true untuk menampilkan tombol setujui/tolak/kembali.
class DaftarPinjamView extends StatefulWidget {
  const DaftarPinjamView({
    super.key,
    required this.service,
    this.hanyaMilikSaya = false,
    this.aksiAdmin = false,
  });

  final LogbookService service;
  final bool hanyaMilikSaya;
  final bool aksiAdmin;

  @override
  State<DaftarPinjamView> createState() => _DaftarPinjamViewState();
}

class _DaftarPinjamViewState extends State<DaftarPinjamView> {
  late Future<_DataPinjam> _future;
  StatusPinjam? _filter;

  @override
  void initState() {
    super.initState();
    _future = _muat();
  }

  Future<_DataPinjam> _muat() async {
    final alat = await widget.service.ambilSemuaAlat();
    final semua = await widget.service.ambilSemuaPinjam();
    var pinjam = semua;
    if (widget.hanyaMilikSaya) {
      final saya = widget.service.myAddress.hex.toLowerCase();
      pinjam = semua
          .where((p) => p.peminjam.hex.toLowerCase() == saya)
          .toList();
    }
    return _DataPinjam(alat, pinjam.reversed.toList()); // terbaru di atas
  }

  Future<void> _refresh() async {
    final baru = _muat();
    setState(() {
      _future = baru;
    });
    try {
      await baru;
    } catch (_) {}
  }

  Future<void> _aksi(String judul, Future<String> Function() kirim) async {
    final ok = await jalankanTransaksi(
      context,
      widget.service,
      judul: judul,
      kirim: kirim,
    );
    if (ok) await _refresh();
  }

  Widget? _tombolAdmin(Peminjaman p) {
    if (!widget.aksiAdmin) return null;
    switch (p.status) {
      case StatusPinjam.diajukan:
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => _aksi(
                'Menolak pengajuan #${p.id}',
                () => widget.service.tolakPinjam(p.id),
              ),
              child: const Text('Tolak'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => _aksi(
                'Menyetujui pengajuan #${p.id}',
                () => widget.service.setujuiPinjam(p.id),
              ),
              child: const Text('Setujui'),
            ),
          ],
        );
      case StatusPinjam.dipinjam:
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton(
              onPressed: () => _aksi(
                'Konfirmasi pengembalian #${p.id}',
                () => widget.service.konfirmasiKembali(p.id),
              ),
              child: const Text('Konfirmasi kembali'),
            ),
          ],
        );
      case StatusPinjam.dikembalikan:
      case StatusPinjam.ditolak:
        return null;
    }
  }

  Widget _barisFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Semua'),
              selected: _filter == null,
              onSelected: (_) => setState(() => _filter = null),
            ),
          ),
          for (final s in StatusPinjam.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(s.label),
                selected: _filter == s,
                onSelected: (_) => setState(() => _filter = s),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _barisFilter(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: FutureBuilder<_DataPinjam>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return _PesanScroll('Gagal memuat data:\n${snap.error}');
                }
                final data = snap.data!;
                final tampil = _filter == null
                    ? data.pinjam
                    : data.pinjam.where((p) => p.status == _filter).toList();
                if (tampil.isEmpty) {
                  return const _PesanScroll(
                    'Tidak ada data peminjaman.\n'
                    'Tarik ke bawah untuk memuat ulang.',
                  );
                }
                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: tampil.length,
                  itemBuilder: (context, i) {
                    final p = tampil[i];
                    final namaAlat = data.alat
                        .firstWhere(
                          (a) => a.id == p.idAlat,
                          orElse: () => Alat(
                            id: p.idAlat,
                            nama: 'Alat #${p.idAlat}',
                            tersedia: false,
                          ),
                        )
                        .nama;
                    final tombol = _tombolAdmin(p);
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text('$namaAlat  (#${p.id})'),
                            subtitle: Text(
                              'Peminjam: ${singkatAlamat(p.peminjam.hexEip55)}\n'
                              'Pinjam: ${formatWaktu(p.waktuPinjam)}\n'
                              'Kembali: ${formatWaktu(p.waktuKembali)}',
                            ),
                            isThreeLine: true,
                            trailing: Text(
                              p.status.label,
                              style: TextStyle(
                                color: _warnaStatus(p.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (tombol != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: tombol,
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}