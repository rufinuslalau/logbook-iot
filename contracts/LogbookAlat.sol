// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract LogbookAlat {
    enum Status { Diajukan, Dipinjam, Dikembalikan, Ditolak }

    struct Alat {
        string nama;
        bool tersedia;
    }

    struct Peminjaman {
        uint256 idAlat;
        address peminjam;
        bytes32 nimHash;
        uint256 waktuPinjam;
        uint256 waktuKembali;
        Status status;
    }

    address public admin;
    Alat[] private daftarAlat;
    Peminjaman[] private daftarPinjam;

    event AlatDitambah(uint256 id, string nama);
    event PinjamDiajukan(uint256 id, uint256 idAlat, address peminjam);
    event PinjamDisetujui(uint256 id);
    event PinjamDitolak(uint256 id);
    event AlatDikembalikan(uint256 id);

    modifier hanyaAdmin() {
        require(msg.sender == admin, "Bukan admin");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    // ===== Tulis: admin =====
    function tambahAlat(string calldata nama) external hanyaAdmin {
        require(bytes(nama).length > 0, "Nama tidak boleh kosong");
        daftarAlat.push(Alat(nama, true));
        emit AlatDitambah(daftarAlat.length - 1, nama);
    }

    function setujuiPinjam(uint256 id) external hanyaAdmin {
        require(id < daftarPinjam.length, "Data tidak ada");
        Peminjaman storage p = daftarPinjam[id];
        require(p.status == Status.Diajukan, "Status bukan Diajukan");
        require(daftarAlat[p.idAlat].tersedia, "Alat sedang dipinjam");
        p.status = Status.Dipinjam;
        p.waktuPinjam = block.timestamp;
        daftarAlat[p.idAlat].tersedia = false;
        emit PinjamDisetujui(id);
    }

    function tolakPinjam(uint256 id) external hanyaAdmin {
        require(id < daftarPinjam.length, "Data tidak ada");
        Peminjaman storage p = daftarPinjam[id];
        require(p.status == Status.Diajukan, "Status bukan Diajukan");
        p.status = Status.Ditolak;
        emit PinjamDitolak(id);
    }

    function konfirmasiKembali(uint256 id) external hanyaAdmin {
        require(id < daftarPinjam.length, "Data tidak ada");
        Peminjaman storage p = daftarPinjam[id];
        require(p.status == Status.Dipinjam, "Alat tidak sedang dipinjam");
        p.status = Status.Dikembalikan;
        p.waktuKembali = block.timestamp;
        daftarAlat[p.idAlat].tersedia = true;
        emit AlatDikembalikan(id);
    }

    // ===== Tulis: user =====
    function ajukanPinjam(uint256 idAlat, bytes32 nimHash) external {
        require(idAlat < daftarAlat.length, "Alat tidak ada");
        require(daftarAlat[idAlat].tersedia, "Alat sedang dipinjam");
        daftarPinjam.push(Peminjaman(idAlat, msg.sender, nimHash, 0, 0, Status.Diajukan));
        emit PinjamDiajukan(daftarPinjam.length - 1, idAlat, msg.sender);
    }

    // ===== Baca (view, gratis) =====
    function jumlahAlat() external view returns (uint256) {
        return daftarAlat.length;
    }

    function ambilAlat(uint256 id) external view returns (string memory, bool) {
        require(id < daftarAlat.length, "Alat tidak ada");
        Alat memory a = daftarAlat[id];
        return (a.nama, a.tersedia);
    }

    function jumlahPinjam() external view returns (uint256) {
        return daftarPinjam.length;
    }

    function ambilPinjam(uint256 id)
        external
        view
        returns (uint256, address, bytes32, uint256, uint256, uint8)
    {
        require(id < daftarPinjam.length, "Data tidak ada");
        Peminjaman memory p = daftarPinjam[id];
        return (p.idAlat, p.peminjam, p.nimHash, p.waktuPinjam, p.waktuKembali, uint8(p.status));
    }
}