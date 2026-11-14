import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_core/logbook_core.dart';

String _ambil(String kunci) {
  final nilai = dotenv.env[kunci]?.trim();
  if (nilai == null || nilai.isEmpty) {
    throw Exception('Variabel $kunci di .env kosong atau tidak ada');
  }
  return nilai;
}

String _ambilKunciPrivat() {
  final nilai = _ambil('PRIVATE_KEY');
  final ok = RegExp(r'^(0x)?[0-9a-fA-F]{64}$').hasMatch(nilai);
  if (!ok) {
    throw Exception(
      'PRIVATE_KEY formatnya salah: harus 64 karakter hex '
      '(boleh diawali 0x), tanpa spasi atau tanda kutip',
    );
  }
  return nilai;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
    final service = LogbookService(
      rpcUrl: _ambil('RPC_URL'),
      contractAddress: _ambil('CONTRACT_ADDRESS'),
      chainId: int.parse(_ambil('CHAIN_ID')),
      privateKey: _ambilKunciPrivat(),
    );
    runApp(AdminApp(service: service));
  } catch (e, st) {
    runApp(
      LayarGalat(pesan: 'Periksa file .env dan pubspec.yaml.\n\n$e\n\n$st'),
    );
  }
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key, required this.service});

  final LogbookService service;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Logbook Alat - Admin',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Logbook Alat (Admin)'),
            bottom: const TabBar(
              tabs: [Tab(text: 'Alat'), Tab(text: 'Logbook')],
            ),
          ),
          body: Column(
            children: [
              BannerWallet(service: service, peran: 'Admin', cekAdmin: true),
              Expanded(
                child: TabBarView(
                  children: [
                    DaftarAlatView(service: service, bisaTambah: true),
                    DaftarPinjamView(service: service, aksiAdmin: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}