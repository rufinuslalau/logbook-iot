import 'package:flutter/material.dart';

ThemeData buatTema(Color warna) {
  final skema = ColorScheme.fromSeed(seedColor: warna);
  return ThemeData(
    useMaterial3: true,
    colorScheme: skema,
    scaffoldBackgroundColor: const Color(0xFFF5F6FA),
    appBarTheme: AppBarTheme(
      backgroundColor: skema.primary,
      foregroundColor: Colors.white,
      scrolledUnderElevation: 0,
    ),
  );
}

/// Memilih ikon sesuai nama alat.
IconData ikonAlat(String nama) {
  final n = nama.toLowerCase();
  if (n.contains('esp') || n.contains('arduino')) return Icons.memory;
  if (n.contains('sensor')) return Icons.sensors;
  if (n.contains('raspberry')) return Icons.developer_board;
  if (n.contains('kabel') || n.contains('jumper')) return Icons.cable;
  if (n.contains('lcd') || n.contains('oled') || n.contains('display')) {
    return Icons.tv;
  }
  return Icons.build_circle_outlined;
}