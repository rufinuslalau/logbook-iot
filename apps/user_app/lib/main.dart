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
    runApp(UserApp(service: service, projectId: _ambil('REOWN_PROJECT_ID')));
  } catch (e, st) {
    runApp(
      LayarGalat(pesan: 'Periksa file .env dan pubspec.yaml.\n\n$e\n\n$st'),
    );
  }
}

class UserApp extends StatelessWidget {
  const UserApp({super.key, required this.service, required this.projectId});

  final LogbookService service;
  final String projectId;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Logbook Alat - User',
      theme: buatTema(Colors.indigo),
      home: WalletGate(
        service: service,
        projectId: projectId,
        namaApp: 'Logbook Alat (User)',
        skema: 'logbookuser',
        peran: PeranApp.user,
        builder: (context, putuskan) =>
            ShellApp(service: service, admin: false, onPutuskan: putuskan),
      ),
    );
  }
}