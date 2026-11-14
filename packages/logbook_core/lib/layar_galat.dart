import 'package:flutter/material.dart';

/// Layar yang tampil kalau app gagal start (misalnya .env salah),
/// supaya app tidak macet di logo Flutter.
class LayarGalat extends StatelessWidget {
  const LayarGalat({super.key, required this.pesan});

  final String pesan;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Gagal memulai aplikasi')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(pesan),
        ),
      ),
    );
  }
}