import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

import 'abi.dart';
import 'models.dart';

class LogbookService {
  LogbookService({
    required String rpcUrl,
    required String contractAddress,
    required this.chainId,
    required String privateKey,
  })  : _client = Web3Client(rpcUrl, http.Client()),
        _credentials = EthPrivateKey.fromHex(privateKey),
        _contract = DeployedContract(
          ContractAbi.fromJson(logbookAbi, 'LogbookAlat'),
          EthereumAddress.fromHex(contractAddress),
        );

  final Web3Client _client;
  final EthPrivateKey _credentials;
  final DeployedContract _contract;
  final int chainId;

  EthereumAddress get myAddress => _credentials.address;

  void dispose() => _client.dispose();

  // ---------- helper dasar ----------
  Future<List<dynamic>> _baca(String fn, [List<dynamic> args = const []]) {
    return _client.call(
      contract: _contract,
      function: _contract.function(fn),
      params: args,
    );
  }

  Future<String> _tulis(String fn, List<dynamic> args) {
    return _client.sendTransaction(
      _credentials,
      Transaction.callContract(
        contract: _contract,
        function: _contract.function(fn),
        parameters: args,
      ),
      chainId: chainId, // wajib 11155111 (Sepolia), default web3dart = 1
    );
  }

  DateTime? _waktu(BigInt detik) {
    if (detik == BigInt.zero) return null;
    return DateTime.fromMillisecondsSinceEpoch(detik.toInt() * 1000);
  }

  // ---------- info wallet ----------
  Future<EtherAmount> saldo() => _client.getBalance(myAddress);

  Future<EthereumAddress> alamatAdmin() async {
    final r = await _baca('admin');
    return r.first as EthereumAddress;
  }

  Future<bool> sayaAdalahAdmin() async {
    final admin = await alamatAdmin();
    return admin.hex.toLowerCase() == myAddress.hex.toLowerCase();
  }

  // ---------- baca (view, gratis) ----------
  Future<int> jumlahAlat() async {
    final r = await _baca('jumlahAlat');
    return (r.first as BigInt).toInt();
  }

  Future<Alat> ambilAlat(int id) async {
    final r = await _baca('ambilAlat', [BigInt.from(id)]);
    return Alat(id: id, nama: r[0] as String, tersedia: r[1] as bool);
  }

  Future<List<Alat>> ambilSemuaAlat() async {
    final n = await jumlahAlat();
    return Future.wait(List.generate(n, (i) => ambilAlat(i)));
  }

  Future<int> jumlahPinjam() async {
    final r = await _baca('jumlahPinjam');
    return (r.first as BigInt).toInt();
  }

  Future<Peminjaman> ambilPinjam(int id) async {
    final r = await _baca('ambilPinjam', [BigInt.from(id)]);
    return Peminjaman(
      id: id,
      idAlat: (r[0] as BigInt).toInt(),
      peminjam: r[1] as EthereumAddress,
      nimHash: bytesToHex(r[2] as Uint8List, include0x: true),
      waktuPinjam: _waktu(r[3] as BigInt),
      waktuKembali: _waktu(r[4] as BigInt),
      status: StatusPinjam.values[(r[5] as BigInt).toInt()],
    );
  }

  Future<List<Peminjaman>> ambilSemuaPinjam() async {
    final n = await jumlahPinjam();
    return Future.wait(List.generate(n, (i) => ambilPinjam(i)));
  }

  // ---------- tulis (dipakai di Minggu 4) ----------
  Future<String> tambahAlat(String nama) => _tulis('tambahAlat', [nama]);

  Future<String> ajukanPinjam(int idAlat, String nim) => _tulis('ajukanPinjam', [
        BigInt.from(idAlat),
        keccak256(Uint8List.fromList(utf8.encode(nim))),
      ]);

  Future<String> setujuiPinjam(int id) =>
      _tulis('setujuiPinjam', [BigInt.from(id)]);

  Future<String> tolakPinjam(int id) =>
      _tulis('tolakPinjam', [BigInt.from(id)]);

  Future<String> konfirmasiKembali(int id) =>
      _tulis('konfirmasiKembali', [BigInt.from(id)]);

  // ---------- status transaksi ----------
  Future<TransactionReceipt?> tungguReceipt(
    String hash, {
    int maksPercobaan = 60,
  }) async {
    for (var i = 0; i < maksPercobaan; i++) {
      final r = await _client.getTransactionReceipt(hash);
      if (r != null) return r;
      await Future.delayed(const Duration(seconds: 3));
    }
    return null;
  }
}