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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
    final service = LogbookService(
      rpcUrl: _ambil('RPC_URL'),
      contractAddress: _ambil('CONTRACT_ADDRESS'),
      chainId: int.parse(_ambil('CHAIN_ID')),
    );
    runApp(AdminApp(service: service, projectId: _ambil('REOWN_PROJECT_ID')));
  } catch (e, st) {
    runApp(
      LayarGalat(pesan: 'Periksa file .env dan pubspec.yaml.\n\n$e\n\n$st'),
    );
  }
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key, required this.service, required this.projectId});

  final LogbookService service;
  final String projectId;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Logbook Alat - Admin',
      theme: buatTema(Colors.teal),
      home: WalletGate(
        service: service,
        projectId: projectId,
        namaApp: 'Logbook Alat (Admin)',
        skema: 'logbookadmin',
        peran: PeranApp.admin,
        builder: (context, putuskan) =>
            ShellApp(service: service, admin: true, onPutuskan: putuskan),
      ),
    );
  }
}
