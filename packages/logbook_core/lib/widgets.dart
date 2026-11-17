import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';

import 'logbook_service.dart';
import 'models.dart';
import 'tema.dart';
import 'transaksi.dart';

// ---------- komponen kecil ----------
class _Pesan extends StatelessWidget {
  const _Pesan(this.ikon, this.teks);

  final IconData ikon;
  final String teks;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(40),
      children: [
        Icon(ikon, size: 56, color: Colors.black26),
        const SizedBox(height: 12),
        Text(
          teks,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
      ],
    );
  }
}

class _Pil extends StatelessWidget {
  const _Pil(this.teks, this.warna);

  final String teks;
  final MaterialColor warna;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: warna.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        teks,
        style: TextStyle(
          color: warna.shade800,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Kartu extends StatelessWidget {
  const _Kartu({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0x14000000)),
      ),
      child: child,
    );
  }
}

class _Baris extends StatelessWidget {
  const _Baris(this.ikon, this.teks);

  final IconData ikon;
  final String teks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(ikon, size: 16, color: Colors.black45),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              teks,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _stat(IconData ikon, String label, String nilai, MaterialColor warna) {
  return _Kartu(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: warna.shade50,
            child: Icon(ikon, size: 18, color: warna),
          ),
          Text(
            nilai,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    ),
  );
}

MaterialColor _warnaStatus(StatusPinjam s) {
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

// ---------- kerangka aplikasi: 3 halaman + menu bawah ----------
class _Data {
  _Data(this.alat, this.pinjam, this.saldo);

  final List<Alat> alat;
  final List<Peminjaman> pinjam; // terbaru di atas
  final EtherAmount saldo;
}

/// admin = false untuk app user, true untuk app admin.
class ShellApp extends StatefulWidget {
  const ShellApp({
    super.key,
    required this.service,
    required this.admin,
    required this.onPutuskan,
  });

  final LogbookService service;
  final bool admin;
  final VoidCallback onPutuskan;

  @override
  State<ShellApp> createState() => _ShellAppState();
}

class _ShellAppState extends State<ShellApp> {
  late Future<_Data> _data = _muat();
  int _tab = 0;
  StatusPinjam? _filter;

  LogbookService get _s => widget.service;

  Future<_Data> _muat() async {
    final r = await Future.wait<Object>([
      _s.ambilSemuaAlat(),
      _s.ambilSemuaPinjam(),
      _s.saldo(),
    ]);
    return _Data(
      r[0] as List<Alat>,
      (r[1] as List<Peminjaman>).reversed.toList(),
      r[2] as EtherAmount,
    );
  }

  Future<void> _segarkan() async {
    final baru = _muat();
    setState(() {
      _data = baru;
    });
    try {
      await baru;
    } catch (_) {}
  }

  /// Menjalankan transaksi tulis (dengan dialog status), lalu memuat ulang data.
  Future<void> _tulis(String judul, Future<String> Function() kirim) async {
    final ok = await jalankanTransaksi(context, _s, judul: judul, kirim: kirim);
    if (ok) await _segarkan();
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
    await _tulis('Mengajukan pinjam ${a.nama}', () => _s.ajukanPinjam(a.id, nim));
  }

  Future<void> _tambahAlat() async {
    final nama = await _mintaTeks(
      context,
      judul: 'Tambah alat',
      label: 'Nama alat',
    );
    if (nama == null || !mounted) return;
    await _tulis('Menambah alat', () => _s.tambahAlat(nama));
  }

  // ----- halaman 1: dashboard -----
  Widget _dashboard(_Data d) {
    final c = Theme.of(context).colorScheme;
    final saya = _s.myAddress.hex.toLowerCase();
    final p = widget.admin
        ? d.pinjam
        : d.pinjam.where((x) => x.peminjam.hex.toLowerCase() == saya).toList();
    String hitung(StatusPinjam s) => '${p.where((x) => x.status == s).length}';
    final eth = d.saldo.getValueInUnit(EtherUnit.ether).toStringAsFixed(4);
    const putih = TextStyle(color: Colors.white);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 20),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c.primary, c.tertiary],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned(
                right: -16,
                bottom: -24,
                child: Icon(Icons.memory, size: 140, color: Colors.white12),
              ),
              const Positioned(
                right: 80,
                top: 8,
                child: Icon(Icons.sensors, size: 56, color: Colors.white12),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.admin ? 'Wallet Admin' : 'Wallet User',
                        style: putih.copyWith(color: Colors.white70),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Putuskan wallet',
                        onPressed: widget.onPutuskan,
                        icon: const Icon(Icons.link_off, color: Colors.white),
                      ),
                    ],
                  ),
                  Text(
                    singkatAlamat(_s.myAddress.hexEip55),
                    style: putih.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$eth ETH • Sepolia', style: putih),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Ringkasan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _stat(Icons.inventory_2, 'Total alat', '${d.alat.length}', Colors.indigo),
            _stat(
              Icons.check_circle,
              'Tersedia',
              '${d.alat.where((a) => a.tersedia).length}',
              Colors.green,
            ),
            _stat(
              Icons.hourglass_top,
              'Menunggu persetujuan',
              hitung(StatusPinjam.diajukan),
              Colors.orange,
            ),
            _stat(
              Icons.handyman,
              'Sedang digunakan',
              hitung(StatusPinjam.dipinjam),
              Colors.blue,
            ),
          ],
        ),
      ],
    );
  }

  // ----- halaman 2: daftar alat (user: Pinjam, admin: Kelola alat) -----
  Widget _alat(_Data d) {
    if (d.alat.isEmpty) {
      return const _Pesan(
        Icons.inventory_2_outlined,
        'Belum ada alat.\nTarik ke bawah untuk memuat ulang.',
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: [
        for (final a in d.alat)
          _Kartu(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              leading: CircleAvatar(
                backgroundColor: (a.tersedia ? Colors.green : Colors.red).shade50,
                child: Icon(
                  ikonAlat(a.nama),
                  color: a.tersedia ? Colors.green : Colors.red,
                ),
              ),
              title: Text(
                a.nama,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(a.tersedia ? 'Tersedia' : 'Sedang dipinjam'),
              trailing: (!widget.admin && a.tersedia)
                  ? FilledButton(
                      onPressed: () => _pinjam(a),
                      child: const Text('Pinjam'),
                    )
                  : Text(
                      '#${a.id}',
                      style: const TextStyle(color: Colors.black38),
                    ),
            ),
          ),
      ],
    );
  }

  // ----- halaman 3: riwayat (user) / logbook (admin) -----
  Widget? _tombolAdmin(Peminjaman p) {
    if (!widget.admin) return null;
    switch (p.status) {
      case StatusPinjam.diajukan:
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () => _tulis(
                'Menolak pengajuan #${p.id}',
                () => _s.tolakPinjam(p.id),
              ),
              child: const Text('Tolak'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => _tulis(
                'Menyetujui pengajuan #${p.id}',
                () => _s.setujuiPinjam(p.id),
              ),
              child: const Text('Setujui'),
            ),
          ],
        );
      case StatusPinjam.dipinjam:
        return Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: () => _tulis(
              'Konfirmasi pengembalian #${p.id}',
              () => _s.konfirmasiKembali(p.id),
            ),
            child: const Text('Konfirmasi kembali'),
          ),
        );
      case StatusPinjam.dikembalikan:
      case StatusPinjam.ditolak:
        return null;
    }
  }

  Widget _kartuPinjam(Peminjaman p, _Data d) {
    final nama = d.alat
            .where((a) => a.id == p.idAlat)
            .map((a) => a.nama)
            .firstOrNull ??
        'Alat #${p.idAlat}';
    final warna = _warnaStatus(p.status);
    final tombol = _tombolAdmin(p);
    return _Kartu(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: warna.shade50,
                  child: Icon(ikonAlat(nama), size: 18, color: warna),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$nama  #${p.id}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _Pil(p.status.label, warna),
              ],
            ),
            const SizedBox(height: 6),
            _Baris(Icons.person_outline, singkatAlamat(p.peminjam.hexEip55)),
            _Baris(Icons.logout, 'Pinjam: ${formatWaktu(p.waktuPinjam)}'),
            _Baris(Icons.login, 'Kembali: ${formatWaktu(p.waktuKembali)}'),
            if (tombol != null) ...[const SizedBox(height: 12), tombol],
          ],
        ),
      ),
    );
  }

  Widget _riwayat(_Data d) {
    final saya = _s.myAddress.hex.toLowerCase();
    var daftar = widget.admin
        ? d.pinjam
        : d.pinjam.where((p) => p.peminjam.hex.toLowerCase() == saya).toList();
    if (_filter != null) {
      daftar = daftar.where((p) => p.status == _filter).toList();
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final s in [null, ...StatusPinjam.values])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(s?.label ?? 'Semua'),
                    selected: _filter == s,
                    onSelected: (_) => setState(() => _filter = s),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (daftar.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Tidak ada data peminjaman.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ),
        for (final p in daftar) _kartuPinjam(p, d),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.admin
        ? ['Dashboard', 'Alat', 'Logbook']
        : ['Dashboard', 'Pinjam', 'Riwayat'];
    return Scaffold(
      appBar: AppBar(
        title: Text('${label[_tab]}${widget.admin ? ' • Admin' : ''}'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _segarkan,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_Data>(
        future: _data,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final Widget halaman;
          if (snap.hasError) {
            halaman = _Pesan(Icons.cloud_off, 'Gagal memuat data:\n${snap.error}');
          } else {
            final d = snap.data!;
            halaman = switch (_tab) {
              0 => _dashboard(d),
              1 => _alat(d),
              _ => _riwayat(d),
            };
          }
          return RefreshIndicator(onRefresh: _segarkan, child: halaman);
        },
      ),
      floatingActionButton: (widget.admin && _tab == 1)
          ? FloatingActionButton.extended(
              onPressed: _tambahAlat,
              icon: const Icon(Icons.add),
              label: const Text('Tambah alat'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: label[0],
          ),
          NavigationDestination(
            icon: const Icon(Icons.handyman_outlined),
            selectedIcon: const Icon(Icons.handyman),
            label: label[1],
          ),
          NavigationDestination(
            icon: const Icon(Icons.history),
            label: label[2],
          ),
        ],
      ),
    );
  }
}