# Dokumen Produk — Aplikasi Sadaya

**Sistem Informasi Koperasi KSU Cahaya Dhamma Phala**

| | |
|---|---|
| **Versi** | `0.9.9` (build 26) |
| **Teknologi** | Flutter · Supabase · PostgreSQL |
| **Struktur** | Clean Architecture (feature-first) |
| **Pengembang** | **0xfndlabs** — Elfan Dwi Saputra |
| **Platform** | Android · iOS · Windows (desktop) |

> "Koperasi yang tertata dimulai dari satu buku besar yang jujur."

Dokumen ini menjelaskan produk yang dihasilkan dari program kerja KKN: aplikasi **Sadaya**. Berisi deskripsi produk, teknologi yang digunakan, arsitektur dan cara kerja, rincian modul, aturan bisnis yang tertanam, keamanan, serta laporan yang dihasilkan.

---

## 1. Deskripsi Produk

**Sadaya** adalah sistem informasi koperasi berbasis web/mobile (aplikasi lintas platform yang berjalan di desktop Windows dan perangkat bergerak) yang digunakan pengurus koperasi untuk mencatat seluruh transaksi dan menyusun laporan keuangan secara otomatis.

Keunggulan utama:

- **Satu basis data terpadu** — kas, bank, simpanan, pinjaman, dana, SHU, aset, pajak, dan unit usaha tersimpan dalam satu buku besar.
- **Auto-posting jurnal (double-entry)** — setiap transaksi otomatis membentuk jurnal debit-kredit yang seimbang; buku besar, jurnal, dan neraca selalu tersusun real-time.
- **Aturan bisnis di sisi server** — validasi saldo, distribusi bunga, dan pengamanan data dijalankan di basis data (atomik), bukan hanya di antarmuka.
- **Ramah pengguna** — antarmuka berbahasa Indonesia, tata letak responsif desktop maupun mobile, formulir dengan format rupiah otomatis.

### Sorotan (Highlights)

| Capaian | Keterangan |
|---|---|
| 🧾 **16 modul** | Kas, Bank, Pajak, Simpanan (3), Pinjaman, SHU, Dana (3), Neraca, Jurnal, Aset (2), Unit Krisado |
| ⚖️ **Neraca real-time** | Setiap transaksi otomatis mem-posting jurnal; laporan Aset = Kewajiban + Ekuitas selalu tersusun |
| 🔐 **Aturan di server** | Validasi saldo, distribusi jasa 7 pos, dan double-entry berjalan atomik di PostgreSQL |
| 💰 **Unit Krisado mandiri** | Kas unit berdiri sendiri (akun `1114`) + tombol **Ambil dari Bank** |
| 📱 **Lintas platform** | Android, iOS, dan Windows — satu basis kode Flutter |
| 🧪 **Teruji** | 70+ tes otomatis lulus untuk aturan domain (bunga, simpanan, pembukuan) |

---

## 2. Teknologi yang Digunakan

| Lapisan | Teknologi | Peran |
|---|---|---|
| Antarmuka | **Flutter (Dart)** | Aplikasi lintas platform (Windows & mobile). |
| State management | **flutter_bloc / bloc** | Pemetaan kondisi antarmuka (memuat/sukses/gagal). |
| Dependency injection | **get_it + injectable** | Pengelolaan dependensi secara terpusat (codegen). |
| Routing | **go_router** | Navigasi halaman + pengalihan otomatis saat login/logout. |
| Backend | **Supabase (PostgreSQL + PostgREST)** | Basis data, autentikasi, keamanan baris (RLS). |
| Aturan bisnis | **Fungsi PL/pgSQL (RPC)** | Transaksi atomic: catat transaksi + posting jurnal sekaligus. |
| Konfigurasi | **flutter_dotenv** | Membaca kredensial koneksi dari `.env` (tidak di-commit). |

Arsitektur kode mengikuti **Clean Architecture feature-first**: setiap fitur dipisah menjadi lapisan *domain* (entitas & aturan), *data* (sumber data & repositori), dan *presentation* (cubit & tampilan). Tidak ada nilai/GUI yang terikat langsung ke detail basis data di tampilan.

---

## 3. Arsitektur dan Cara Kerja

```text
┌─────────────────────────────┐
│   Antarmuka (Flutter)        │
│   16 modul + laporan         │
└──────────────┬──────────────┘
               │ multi-tabel tidak pernah
               │        dilakukan dari klien
               v
┌─────────────────────────────┐
│   Supabase (PostgREST)       │
│  - login (auth)              │
│  - RPC PL/pgSQL ("buku")     │
│  - read tabel untuk laporan  │
└──────────────┬──────────────┘
               v
┌─────────────────────────────┐
│   PostgreSQL                 │
│  - tabel transaksi           │
│  - LEDGER_ENTRIES (buku besar)│
│  - RLS (keamanan per baris)  │
└─────────────────────────────┘
```

Prinsip penting:

1. **Tidak ada insert multi-tabel dari klien.** Pencatatan yang memengaruhi >1 tabel dipanggil lewat **fungsi RPC di basis data** sehingga berjalan atomik. Contoh: membayar cicilan menulis tabel jadwal, distribusi jasa, simpanan SWK, dan 8 baris jurnal sekaligus — gagal di tengah berarti tidak ada data yang setengah tersimpan.
2. **Jurnal otomatis.** Setiap "buku" (kas, bank, simpanan, pinjaman, dana, aset, pajak, usaha) mem-posting baris debit/kredit ke `ledger_entries`. Buku besar dan neraca membaca tabel tersebut langsung (real-time).
3. **Keamanan dua lapis.** Login diperiksa lewat `auth.uid()` di tiap fungsi; setiap baris data dilindungi RLS (Row Level Security) — pengguna tidak bisa membaca/mengubah data milik pengguna lain.

---

## 4. Rincian Modul

### 4.1 Beranda (Dashboard)

- Ringkasan neraca real-time: **Aset, Piutang Pinjaman, Ekuitas/Modal, Stok Keripik, Status Neraca (SEIMBANG/SELISIH)**.
- Statistik anggota: Total / Aktif / Nonaktif.
- Aksi cepat: Setor Simpanan, Cairkan Pinjaman, Unit Krisado, Kas Umum.
- Navigasi **16 modul koperasi** dengan filter kelompok (Utama & Kas, Simpan Pinjam, Dana & SHU, Aset & Usaha).

### 4.2 Data Anggota

- Tambah / edit / nonaktifkan anggota; nomor anggota dibuat otomatis.
- Pencarian nama dan filter status (Aktif/Nonaktif).
- Anggota nonaktif tetap menyimpan riwayatnya (bukan hapus permanen).

### 4.3 Simpanan

Empat jenis dengan perlakuan akuntansi berbeda:

| Jenis | Kode Akun | Karakter |
|---|---|---|
| Simpanan Pokok | 3112 (ekuitas) | Setoran manual. |
| Wajib Bulanan | 3113 (ekuitas) | Setoran manual. |
| Mana Suka | 2111 (kewajiban) | Satu-satunya yang dapat ditarik. |
| Wajib Kredit | 2113 (kewajiban) | Terbit otomatis dari cicilan pinjaman (tidak diinput manual). |

Setoran: Debit Kas / Kredit akun simpanan. Tarikan (hanya SMS) diblokir bila saldo kurang.

### 4.4 Pinjaman

- Dua jenis pinjaman:
  - **Biasa (mengangsur)** — bunga/jasa **2% dari pokok per angsuran** (20 ribu per 1 juta). Contoh 10 juta, tenor 10 → bunga **200 ribu per angsuran**, **total bunga 2 juta** (2% × pokok × tenor).
  - **Cepat (lunas di akhir)** — bunga/jasa **3% dari pokok per bulan × tenor**, dibayar sekaligus di akhir tenor. Contoh 10 juta, tenor 10 → **total bunga 3 juta** (3% × pokok × tenor).
- Tenor pilihan 3–50 bulan; biaya administrasi 3% dipotong saat pencairan.
- Jurnal pencairan: Debit Piutang Pinjaman / Kredit Kas (bersih) + Pendapatan Administrasi.
- Pembayaran angsuran mendistribusikan jasa secara otomatis:

| Pos | Bagian |
|---|---|
| Japinup (Jasa Pinjaman) | 55% |
| Kesra (Kesejahteraan) | 25% |
| SWK (Simpanan Wajib Kredit) | 10% → masuk saldo simpanan anggota |
| Sosial / Pendidikan / CRK / Pembangunan | masing-masing 2,5% |

### 4.5 Kas Umum & Bank

- Tab **Saldo Berjalan** (total + rincian sisi kredit).
- Tab **Kas** — 9 kartu sumber pemasukan: Japinup, Kesra, Sosial, Pendidikan, CRK, Pembangunan, SWK, SMS, dan Cair dari Bank.
- Tab **Buku Bank** — mutasi rekening + aksi bank:
  - **Dana Masuk ke Bank** (penambahan saldo dari luar);
  - **Cairkan ke Kas** (Debit Kas / Kredit Bank).

### 4.6 Dana & SHU

- **Buku Dana**: 7 pos (Kesra, Sosial, Pendidikan, CRK, Pembangunan, Japinup, SWK) dengan kartu **Total Kas (7 Pos)**.
  - Kas masuk/keluar manual per pos (Debit 1111 ↔ kredit akun pos), sumber terbatas pada 7 pos dana.
  - Kartu **Cair dari Bank** menampilkan total transfer bank → kas.
- **SHU**: alur *draft → disetujui → terdistribusi* dengan alokasi persentase (Cadangan, Sosial, Pendidikan, Dasim, Dapin, Pengurus & Pengawas, Pegawai, Pembangunan). Terdapat tombol "Ambil dari Buku Besar" untuk mengisi total SHU = laba bersih tahun buku.

### 4.7 Aset Koperasi

- Buku inventaris: nilai perolehan, umur pakai (1–50 tahun), nilai residu, penyusutan/tahun.
- Hitung penyusutan metode **garis lurus proporsional bulan** per tahun buku.
- Kartu ringkasan nilai buku: Nilai Perolehan, Akumulasi Penyusutan, Nilai Buku.

### 4.8 Modul Pajak

- Buku pajak (PPh 21, PPh 23, PPN, Pajak Lainnya) dengan status Dibayar/Belum.
- Prinsip **akrual**: saat belum dibayar tercatat sebagai Hutang Pajak (kewajiban); "Tandai Dibayar" mem-posting jurnal penyelesaian.

### 4.9 Unit Krisado

- **Saldo unit mandiri**: kas unit berdiri sendiri (akun `1114`), terpisah dari kas koperasi.
- **Ambil dari Bank**: tarik uang dari Buku Bank ke kas unit (jurnal Debit 1114 / Kredit 1112 + baris penarikan di Buku Bank), dengan validasi saldo bank.
- **Bahan Baku**: daftar jenis bahan + satuan, stok, pembelian (stok masuk + harga) dan pemakaian (stok keluar; dibatasi stok tersedia).
- **Produksi**: catat hasil, satuan (kg/gram), hasil pack, biaya.
- **Penjualan**: catat produk, jumlah, harga dengan pratinjau total (omzet bulan berjalan); posting Debit Kas Unit / Kredit Pendapatan.

### 4.10 Laporan

- **Neraca / Komposisi Keuangan**: persamaan akuntansi, badge SEIMBANG/SELISIH, kelompok Aset, Kewajiban, Ekuitas, Laba/Rugi, break-even TOTAL AKTIVA = TOTAL PASIVA. Filter per tahun buku.
- **Buku Besar**: jurnal rinci per akun (filter tahun + akun) dengan saldo akhir tiap akun.
- **Jurnal**: log transaksi kronologis dengan filter tahun, akun, jenis buku, dan rentang tanggal.

---

## 5. Aturan Bisnis yang Tertanam di Server

| Aturan | Implementasi |
|---|---|
| Setiap transaksi jurnal harus seimbang (debit = kredit) | Validasi + toleransi pembulatan di mesin buku besar |
| Saldo tidak boleh negatif | Penarikan SMS & kas keluar dana diblokir bila saldo kurang |
| SWK tidak bisa diinput manual | dikelola sistem dari cicilan pinjaman |
| Distribusi jasa angsuran | otomatis 55/25/10/2,5×4 ke 7 pos |
| SHU hanya bisa didistribusikan setelah disetujui | status flow draft→approved→distributed |
| SHU yang sudah terdistribusi tidak terhapus | aksi "Batalkan Distribusi" mengembalikan ke draft |
| Nomor anggota otomatis & unik | dibuat di server (max+1) |
| Pajak akrual | tercatat sebagai kewajiban sebelum dibayar |
| Penyusutan garis lurus proporsional bulan | dihitung dari seluruh aset aktif per tahun |

---

## 6. Keamanan dan Integritas Data

- **Autentikasi**: email + password via Supabase Auth; router otomatis mengarahkan pengguna yang belum login ke halaman login.
- **RLS (Row Level Security)**: setiap baris data dilindungi kebijakan per tabel; konfigurasi (bagan akun) hanya-baca dari aplikasi.
- **Transaksi eksklusif**: pembayaran cicilan mengunci baris (FOR UPDATE) untuk mencegah pembayaran ganda oleh dua pengurus.
- **Kredensial tidak di-commit**: URL dan kunci Supabase dibaca dari `.env` (masuk `.gitignore`).

---

## 7. Persyaratan Menjalankan

1. Proyek Supabase berisi seluruh migrasi basis data (skema, RLS, seed, dan fungsi RPC).
2. File `.env` dengan `SUPABASE_URL` dan `SUPABASE_PUBLISHABLE_KEY`.
3. Akun pengurus dibuat di panel Authentication Supabase.
4. Menjalankan aplikasi dari kode sumber (Flutter) atau build untuk Windows/mobile.

---

## 8. Capaian dan Penutup

Aplikasi Sadaya telah diuji bersama pengurus untuk kasus transaksi riil (simpanan, pencairan & pembayaran pinjaman, kas masuk/keluar dana, aksi bank, penyusutan aset) dengan hasil jurnal yang selalu seimbang dan laporan tersusun otomatis. Pengembangan selanjutnya mencakup hak akses berjenjang, ekspor laporan (PDF/Excel), void berjejak, dan pencadangan rutin.

---

*Dikembangkan oleh **0xfndlabs** (Elfan Dwi Saputra) — KKN KSU Cahaya Dhamma Phala, 2026.*

*Sadaya: satu aplikasi, satu buku besar, satu koperasi yang sehat.* 🦄