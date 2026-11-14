import 'package:web3dart/web3dart.dart';

enum StatusPinjam { diajukan, dipinjam, dikembalikan, ditolak }

extension StatusPinjamLabel on StatusPinjam {
  String get label {
    switch (this) {
      case StatusPinjam.diajukan:
        return 'Diajukan';
      case StatusPinjam.dipinjam:
        return 'Dipinjam';
      case StatusPinjam.dikembalikan:
        return 'Dikembalikan';
      case StatusPinjam.ditolak:
        return 'Ditolak';
    }
  }
}

class Alat {
  const Alat({required this.id, required this.nama, required this.tersedia});

  final int id;
  final String nama;
  final bool tersedia;
}

class Peminjaman {
  const Peminjaman({
    required this.id,
    required this.idAlat,
    required this.peminjam,
    required this.nimHash,
    required this.waktuPinjam,
    required this.waktuKembali,
    required this.status,
  });

  final int id;
  final int idAlat;
  final EthereumAddress peminjam;
  final String nimHash;
  final DateTime? waktuPinjam;
  final DateTime? waktuKembali;
  final StatusPinjam status;
}

String formatWaktu(DateTime? d) {
  if (d == null) return '-';
  String dua(int n) => n.toString().padLeft(2, '0');
  return '${dua(d.day)}/${dua(d.month)}/${d.year} ${dua(d.hour)}:${dua(d.minute)}';
}

String singkatAlamat(String hex) {
  if (hex.length < 12) return hex;
  return '${hex.substring(0, 6)}...${hex.substring(hex.length - 4)}';
}