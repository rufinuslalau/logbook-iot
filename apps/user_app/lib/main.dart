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
    runApp(UserApp(service: service));
  } catch (e, st) {
    runApp(
      LayarGalat(pesan: 'Periksa file .env dan pubspec.yaml.\n\n$e\n\n$st'),
    );
  }
}

class UserApp extends StatelessWidget {
  const UserApp({super.key, required this.service});

  final LogbookService service;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Logbook Alat - User',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Logbook Alat (User)'),
            bottom: const TabBar(
              tabs: [Tab(text: 'Alat'), Tab(text: 'Riwayat Saya')],
            ),
          ),
          body: Column(
            children: [
              BannerWallet(service: service, peran: 'User'),
              Expanded(
                child: TabBarView(
                  children: [
                    DaftarAlatView(service: service, bisaPinjam: true),
                    DaftarPinjamView(service: service, hanyaMilikSaya: true),
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