import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart'
    hide EthereumAddress, Transaction, DeployedContract;
import 'package:web3dart/web3dart.dart';

import 'logbook_service.dart';

enum PeranApp { admin, user }

/// Menampilkan layar sambung wallet, mendeteksi peran (admin/user),
/// lalu menampilkan isi aplikasi lewat [builder].
class WalletGate extends StatefulWidget {
  const WalletGate({
    super.key,
    required this.service,
    required this.projectId,
    required this.namaApp,
    required this.skema,
    required this.peran,
    required this.builder,
  });

  final LogbookService service;
  final String projectId;
  final String namaApp;
  final String skema; // harus sama dengan scheme di AndroidManifest
  final PeranApp peran;
  final Widget Function(BuildContext context, VoidCallback putuskan) builder;

  @override
  State<WalletGate> createState() => _WalletGateState();
}

class _WalletGateState extends State<WalletGate> {
  ReownAppKitModal? _modal;
  bool _siap = false;
  bool? _adalahAdmin;
  String? _galat;

  @override
  void initState() {
    super.initState();
    _mulai();
  }

  Future<void> _mulai() async {
    try {
      final idRantai = widget.service.chainId.toString();
      var sepolia = ReownAppKitModalNetworks.getNetworkInfo('eip155', idRantai);
      if (sepolia == null) {
        sepolia = ReownAppKitModalNetworkInfo(
          name: 'Sepolia',
          chainId: idRantai,
          currency: 'ETH',
          rpcUrl: 'https://rpc.sepolia.org',
          explorerUrl: 'https://sepolia.etherscan.io',
          isTestNetwork: true,
        );
        ReownAppKitModalNetworks.addSupportedNetworks('eip155', [sepolia]);
      }

      final modal = ReownAppKitModal(
        context: context,
        projectId: widget.projectId,
        metadata: PairingMetadata(
          name: widget.namaApp,
          description: 'Logbook peminjaman alat Lab IoT berbasis blockchain',
          url: 'https://example.com',
          icons: ['https://avatars.githubusercontent.com/u/37784886'],
          redirect: Redirect(native: '${widget.skema}://'),
        ),
      );
      _modal = modal;
      modal.onModalConnect.subscribe((_) => _sinkron());
      modal.onModalUpdate.subscribe((_) => _sinkron());
      modal.onModalDisconnect.subscribe((_) => _sinkron());

      await modal.init();
      await modal.selectChain(sepolia);
      if (!mounted) return;
      setState(() => _siap = true);
      await _sinkron();
    } catch (e) {
      if (mounted) setState(() => _galat = '$e');
    }
  }

  /// Menyamakan service dengan sesi wallet saat ini.
  Future<void> _sinkron() async {
    final m = _modal;
    if (m == null || !mounted) return;
    final s = widget.service;
    final alamat = m.isConnected ? m.session?.getAddress('eip155') : null;

    if (alamat == null) {
      s.akun = null;
      s.penulis = null;
      setState(() => _adalahAdmin = null);
      return;
    }

    final akunBaru = EthereumAddress.fromHex(alamat);
    if (s.akun?.hex == akunBaru.hex && _adalahAdmin != null) return;

    s.akun = akunBaru;
    s.penulis = (fn, args) => m.requestWriteContract(
          topic: m.session!.topic,
          chainId: 'eip155:${s.chainId}',
          deployedContract: s.kontrak,
          functionName: fn,
          transaction: Transaction(from: s.akun),
          parameters: args,
        );

    try {
      final admin = await s.sayaAdalahAdmin();
      if (mounted) setState(() => _adalahAdmin = admin);
    } catch (e) {
      if (mounted) setState(() => _galat = 'Gagal memeriksa peran wallet: $e');
    }
  }

  Future<void> _putuskan() async {
    try {
      await _modal?.disconnect();
    } catch (_) {}
    await _sinkron();
  }

  @override
  Widget build(BuildContext context) {
    final m = _modal;
    final s = widget.service;
    final namaPeran = widget.peran == PeranApp.admin ? 'Admin' : 'User';

    if (_galat != null) {
      return _LayarPesan(
        ikon: Icons.error_outline,
        judul: 'Terjadi masalah',
        pesan: _galat!,
      );
    }
    if (m == null || !_siap) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!m.isConnected || s.akun == null) {
      return _LayarPesan(
        ikon: Icons.account_balance_wallet_outlined,
        judul: 'Logbook Alat Lab IoT\n($namaPeran)',
        pesan: 'Hubungkan wallet MetaMask untuk melanjutkan.\n'
            'Kunci privat tetap di MetaMask, tidak disimpan di aplikasi ini.',
        tombol: _TombolPutih('Hubungkan Wallet', Icons.link, () => m.openModalView()),
      );
    }

    final admin = _adalahAdmin;
    if (admin == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (widget.peran == PeranApp.admin && !admin) {
      return _LayarPesan(
        ikon: Icons.block,
        judul: 'Bukan wallet admin',
        pesan: 'Wallet ini bukan admin kontrak.\n'
            'Hubungkan wallet admin, atau gunakan Aplikasi User.',
        tombol: _TombolPutih('Ganti wallet', Icons.link_off, () => _putuskan()),
      );
    }
    if (widget.peran == PeranApp.user && admin) {
      return _LayarPesan(
        ikon: Icons.admin_panel_settings_outlined,
        judul: 'Ini wallet admin',
        pesan: 'Wallet admin dipakai di Aplikasi Admin.\n'
            'Hubungkan wallet user untuk meminjam alat.',
        tombol: _TombolPutih('Ganti wallet', Icons.link_off, () => _putuskan()),
      );
    }

    return widget.builder(context, () => _putuskan());
  }
}

class _LayarPesan extends StatelessWidget {
  const _LayarPesan({
    required this.ikon,
    required this.judul,
    required this.pesan,
    this.tombol,
  });

  final IconData ikon;
  final String judul;
  final String pesan;
  final Widget? tombol;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c.primary, c.tertiary],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(ikon, size: 64, color: Colors.white),
                ),
                  const SizedBox(height: 24),
                  Text(
                    judul,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    pesan,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                  ),
                  if (tombol != null) ...[const SizedBox(height: 32), tombol!],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TombolPutih extends StatelessWidget {
  const _TombolPutih(this.teks, this.ikon, this.onTap);

  final String teks;
  final IconData ikon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
      onPressed: onTap,
      icon: Icon(ikon),
      label: Text(teks),
    );
  }
}