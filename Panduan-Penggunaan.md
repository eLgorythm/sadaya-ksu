# Panduan Penggunaan Aplikasi Sadaya

**Sistem Informasi Koperasi — KSU Cahaya Dhamma Phala**

Dokumen ini menjelaskan cara menggunakan aplikasi Sadaya untuk pengurus koperasi: mulai dari masuk aplikasi, memahami beranda, mencatat transaksi di tiap modul, hingga membaca laporan yang tersusun otomatis dari buku besar.

---

## Daftar Isi

1. [Persiapan & Masuk Aplikasi](#1-persiapan--masuk-aplikasi)
2. [Navigasi Utama](#2-navigasi-utama)
3. [Beranda](#3-beranda)
4. [Modul Anggota](#4-modul-anggota)
5. [Modul Simpanan](#5-modul-simpanan)
6. [Modul Pinjaman](#6-modul-pinjaman)
7. [Kas Umum & Bank](#7-kas-umum--bank)
8. [Dana & SHU](#8-dana--shu)
9. [Aset Koperasi](#9-aset-koperasi)
10. [Modul Pajak](#10-modul-pajak)
11. [Unit Usaha Keripik](#11-unit-usaha-keripik)
12. [Laporan: Neraca, Buku Besar & Jurnal](#12-laporan--neraca--buku-besar--jurnal)
13. [Pengaturan & Tentang](#13-pengaturan--tentang)
14. [Prinsip Pencatatan (Auto-Posting ke Buku Besar)](#14-prinsip-pencatatan)
15. [Tip & Hal yang Perlu Diketahui](#15-tip--hal-yang-perlu-diketahui)

---

## 1. Persiapan & Masuk Aplikasi

### 1.1 Menjalankan Aplikasi

Aplikasi membaca pengaturan koneksi dari file `.env` di samping file aplikasi. Pastikan file tersebut sudah berisi `SUPABASE_URL` dan `SUPABASE_PUBLISHABLE_KEY` yang benar, lalu jalankan aplikasi.

### 1.2 Halaman Masuk (Login)

Layar pertama berisi:

- Logo lingkaran "S" dan nama **Sadaya** dengan subjudul **KSU Cahaya Dhamma Phala**.
- Kolom **Email** dan **Password** (tersedia tombol mata untuk menampilkan/menyembunyikan password).
- Tombol **Masuk** (hijau). Selama proses masuk berjalan, tombol berubah menjadi indikator memuat.

Langkah:

1. Isi email dan password akun pengurus.
2. Tekan **Masuk** (atau tombol "done" pada keyboard).
3. Bila berhasil, Anda langsung diarahkan ke beranda.

> **Catatan:** Bila login gagal, muncul pesan merah di bawah layar (mis. email/password salah atau akun belum dikonfirmasi). Periksa kembali data Anda.

### 1.3 Keluar Aplikasi

Keluar dilakukan dari menu **Pengaturan → Keluar** (lihat [Bagian 13](#13-pengaturan--tentang)). Sistem menampilkan dialog konfirmasi **"Yakin ingin keluar dari aplikasi?"** — tekan **Keluar** untuk mengonfirmasi.

---

## 2. Navigasi Utama

Setelah masuk, aplikasi menampilkan cangkang utama dengan beberapa pintu navigasi. Tampilan menyesuaikan perangkat:

- **Desktop/Windows (lebar layar ≥ 1024 px):** menggunakan panel navigasi di sisi kiri (Navigation Rail).
- **Perangkat mobile/sempit:** menggunakan bilah bawah (bottom navigation).

Baik pada rail maupun bilah bawah, tersedia 5 area:

| Area | Fungsi |
|---|---|
| **Beranda** | Halaman utama: ringkasan keuangan, statistik anggota, aksi cepat, dan daftar 16 modul. |
| **Neraca** | Membuka laporan Komposisi Keuangan (Neraca) real-time. |
| **Input** (tombol + hijau) | Membuka lembar **"Pilih Modul Transaksi"** berisi aksi cepat transaksi. |
| **Buku Besar** | Membuka halaman Buku Besar (jurnal rinci per akun). |
| **Pengaturan** | Menu pengaturan aplikasi (anggota, pilih anggota, pinjaman/simpanan, tentang, keluar). |

> **Catatan:** Tombol "Input" dan "Buku Besar" adalah *aksi* (bukan halaman tetap). "Buku Besar" selalu membuka halaman baru di atas beranda.

---

## 3. Beranda

Beranda menyajikan ringkasan kondisi koperasi dan pintu ke semua modul.

### 3.1 Ringkasan Keuangan (Kartu Hero)

Kartu hijau berjudul **"LAPORAN NERACA REAL-TIME"** menampilkan:

- **Aset** — total aset koperasi.
- **Piutang Pinjaman** — total piutang dari pinjaman anggota yang belum lunas.
- **Total Ekuitas/Modal** — modal koperasi (termasuk simpanan pokok/wajib, dana, dsb).
- **Stok Keripik (kg)** — jumlah stok bahan/produk unit usaha.
- **Status Neraca** — badge **SEIMBANG** (persamaan akuntansi benar) atau **SELISIH** (ada entri jurnal yang perlu ditelusuri).

Data ini diperbarui setiap kali Anda menarik layar ke bawah (pull-to-refresh). Di bawah kartu hero tampil statistik **Total Anggota**, **Aktif**, dan **Nonaktif**.

### 3.2 Aksi Cepat Transaksi

Empat tombol untuk mencatat transaksi paling sering:

| Tombol | Hasil |
|---|---|
| **Setor Simpanan** | Pilih anggota → halaman Simpanan anggota. |
| **Cairkan Pinjaman** | Pilih anggota → halaman Pinjaman anggota. |
| **POS Keripik** | Membuka Unit Usaha Keripik. |
| **Kas Umum** | Membuka Kas Umum & Bank. |

Lembar yang sama juga terbuka lewat tombol **Input** (+ hijau) pada navigasi.

### 3.3 Daftar Modul

Bagian **"16 Modul Koperasi"** menampilkan semua modul dalam kisi. Kartu yang mem-posting jurnal ke buku besar diberi badge **"Neraca"**. Tersedia filter untuk menyaring tampilan:

- **Semua**
- **Utama & Kas** — Buku Kas, Buku Bank, Buku Pajak, Komposisi Keuangan, Jurnal.
- **Simpan Pinjam** — Simpanan Pokok, Simpanan Wajib, Simpanan Mana Suka, Pinjaman Anggota.
- **Dana & SHU** — Penerimaan SHU, Dana Sosial, Dana Pendidikan, Dana Kesejahteraan.
- **Aset & Usaha** — Buku Inventaris, Penyusutan Aset, Unit Keripik.

| Modul | Menuju ke |
|---|---|
| Buku Kas / Buku Bank | Kas Umum & Bank |
| Buku Pajak | Modul Pajak |
| Simpanan Pokok / Wajib / Mana Suka | pilih anggota → halaman Simpanan |
| Pinjaman Anggota | pilih anggota → halaman Pinjaman |
| Penerimaan SHU / Dana Sosial / Dana Pendidikan / Dana Kesejahteraan | Dana & SHU |
| Komposisi Keuangan | tab Neraca |
| Jurnal | halaman Jurnal |
| Buku Inventaris / Penyusutan Aset | Aset Koperasi |
| Unit Keripik | Unit Usaha Keripik |

---

## 4. Modul Anggota

### 4.1 Data Anggota (`/anggota`)

Dibuka dari **Pengaturan → Anggota**.

- Kolom **pencarian nama** (dengan tombol × untuk mengosongkan) dan **filter chip**: Semua / Aktif / Nonaktif.
- Daftar kartu anggota menampilkan nomor anggota, nama, telepon, tanggal masuk, catatan (bila ada), dan badge status **Aktif/Nonaktif**.
- Tarik layar ke bawah untuk memuat ulang.

**Aksi:**

- Tombol **"Anggota Baru"** (FAB) → lembar tambah anggota.
- Menu **⋮** pada kartu anggota → **Edit**, **Simpanan**, **Pinjaman**, atau **Nonaktifkan/Aktifkan** (dengan dialog konfirmasi). Anggota nonaktif tetap tersimpan riwayatnya.

**Form Anggota:** isi **Nama Anggota \*** (wajib), **Alamat**, **No. Telepon**, **Tanggal Bergabung \*** (pilih tanggal), dan **Catatan**. Tekan **Simpan**. Nomor anggota dibuat otomatis.

### 4.2 Pilih Anggota (`/pilih-anggota`)

Halaman pemilihan sementara yang muncul sebelum membuka Simpanan/Pinjaman seorang anggota. Cari nama atau gunakan filter status, lalu ketuk kartu anggota untuk memilih. Anggota nonaktif tetap dapat dipilih.

---

## 5. Modul Simpanan

**Akses:** beranda → modul Simpanan / aksi cepat **Setor Simpanan** / Pengaturan → **Buka Simpanan Anggota** / menu ⋮ pada kartu anggota.

Halaman menampilkan **4 kartu saldo**:

| Kartu | Keterangan |
|---|---|
| **Simpanan Pokok (SP)** | Modal pokok anggota. |
| **Wajib Bulanan (SWB)** | Simpanan wajib bulanan. |
| **Mana Suka (SMS)** | Simpanan sukarela; satu-satunya yang bisa ditarik. |
| **Wajib Kredit (SWK)** | Simpanan wajib kredit; muncul otomatis dari cicilan pinjaman. |

Di bawahnya terdapat **Riwayat Transaksi** (tanda +/− berwarna), termasuk chip **"Dibatalkan"** untuk transaksi void.

**Aksi:**

- **"Setor Simpanan"** → pilih jenis simpanan (sp/kode), isi **Nominal (Rp) \*** (format ribuan otomatis) dan **Keterangan**, tekan **Simpan Setoran**. SWK dikecualikan karena muncul otomatis dari angsuran pinjaman.
- **"Tarik Simpanan (Mana Suka)"** → seperti setoran tetapi hanya untuk SMS dan **nonaktif bila saldo SMS 0**.

Tiap setoran/tarikan langsung diposting ke buku besar (Debit/Kredit Kas 1111 vs akun simpanan).

---

## 6. Modul Pinjaman

**Akses:** beranda → modul Pinjaman Anggota / aksi cepat **Cairkan Pinjaman** / Pengaturan → **Buka Pinjaman Anggota** / menu ⋮ pada kartu anggota.

### 6.1 Daftar Pinjaman

Kartu pinjaman menampilkan: nomor pinjaman (+ ikon ⚡ untuk pinjaman cepat), badge **LUNAS/AKTIF**, pokok, tanggal pencairan • tenor • bunga, progress bar, sisa pinjaman, dan persentase terbayar. Tekan **"Pinjaman Baru"** (FAB) untuk mengajukan.

### 6.2 Mengajukan Pinjaman Baru

Lembar **"Pinjaman Baru"**:

- **Jumlah Pinjaman (Rp) \*** — wajib, format ribuan otomatis.
- **Jenis Pinjaman** — SegmentedButton:
  - **Biasa (Mengangsur)** — bunga/jasa **2% dari pokok per angsuran** (setara **20 ribu per 1 juta** per angsuran). Contoh: pinjaman 10 juta tenor 10 → bunga **200.000 per angsuran**, **total bunga 2 juta** (2% × pokok × tenor).
  - **Cepat (Lunas di Akhir)** — **3% dari pokok per bulan × tenor**, dibayar sekaligus di akhir tenor. Contoh: pinjaman 10 juta tenor 10 → **total bunga 3 juta** (3% × pokok × tenor).
- **Tenor (bulan)** — pilihan chip: 3, 5, 10, 20, 30, 40, 50 (bawaan 10).
- **Biaya administrasi 3%** — dipotong saat pencairan (kas yang diterima bersih).
- **Keterangan / agunan** — opsional.

Tekan **"Cairkan Pinjaman"**. Sistem membuat pinjaman, jadwal cicilan (10–50 bulan), SWK otomatis, dan jurnal pencairan (Debit Piutang / Kredit Kas + Administrasi).

### 6.3 Detail & Pembayaran Cicilan

Ketuk kartu pinjaman untuk melihat ringkasan (pokok, tenor, bunga/jasa, administrasi, sisa & sudah dibayar) dan jadwal. Setiap baris cicilan menampilkan pokok + bunga, jatuh tempo / **"Dibayar pada <tanggal>"**, dan tombol **"Bayar"** (aktif selama pinjaman belum lunas).

Lembar **"Bayar Cicilan ke-N"** menampilkan rincian pokok, bunga, total, serta **Distribusi bunga** ke 7 pos secara otomatis:

- **Japinup** (Jasa Pinjaman) 55%
- **Kesra** (Kesejahteraan) 25%
- **SWK** (Simpanan Wajib Kredit) 10% → masuk saldo simpanan anggota
- **Sosial, Pendidikan, CRK, Pembangunan** masing-masing 2,5%

Tekan **"Bayar Rp <total>"** → pembayaran tercatat, jurnal terdistribusi ke 7 pos, dan detail otomatis diperbarui.

---

## 7. Kas Umum & Bank

**Akses:** beranda → modul Buku Kas / Buku Bank / aksi cepat **Kas Umum**.

Halaman **"Kas Umum & Bank"** memiliki 3 tab:

### 7.1 Tab "Saldo Berjalan"

- Kartu hijau **"Saldo Berjalan"** (total seluruh posisi sisi kredit).
- Kartu **"Saldo Berjalan (Sisi Kredit)"** — rincian per akun (kewajiban + ekuitas + pendapatan), mencerminkan bobot tiap pos.

### 7.2 Tab "Kas"

Menampilkan kartu **Kas** dan **9 kartu sumber pemasukan kas** dengan rincian setiap baris:

Japinup (Jasa Pinjaman) • Kesra (Kesejahteraan) • Dana Sosial • Dana Pendidikan • CRK (Cadangan Risiko Kredit) • Dana Pembangunan • SWK (Simpanan Wajib Kredit) • SMS (Simpanan Mana Suka) • **Cair dari Bank**.

Pemasukan dari angsuran pinjaman, setoran simpanan, hingga pemasukan dana manual dari Buku Dana tercatat di sini sesuai sumbernya.

### 7.3 Tab "Buku Bank"

Kartu saldo bank + daftar mutasi rekening (masuk `+` hijau / keluar `-` merah; kategori • deskripsi • tanggal).

**Aksi Bank (FAB "Aksi Bank" — hanya muncul di tab Buku Bank):**

1. **"Dana Masuk ke Bank"** — menambah saldo rekening dari luar (tanpa kategori). Isi **Nominal (Rp) \***, **Tanggal Transaksi \***, **Keterangan \*** → **Simpan**.
2. **"Cairkan ke Kas"** — menarik tunai dari rekening ke kas koperasi. Kas bertambah, bank berkurang, dan jurnalnya otomatis.

### 7.4 Mencatat Kas Masuk/Keluar Dana

Pencatatan kas untuk pos dana dilakukan di **Buku Dana** (Modul Dana & SHU) lewat tombol **"Catat Dana"** — lihat [Bagian 8.1](#81-tab-buku-dana).

---

## 8. Dana & SHU

**Akses:** beranda → modul Penerimaan SHU / Dana Sosial / Dana Pendidikan / Dana Kesejahteraan.

Halaman **"Dana & SHU"** memiliki 2 tab.

### 8.1 Tab "Buku Dana"

- Kartu hijau **"Total Kas (7 Pos Dana)"** — jumlah saldo seluruh pos dana.
- **7 kartu saldo pos dana**: Kesra (Kesejahteraan), Dana Sosial, Dana Pendidikan, CRK, Dana Pembangunan, Japinup, SWK. Warna berbeda tiap pos.
- Kartu **"Cair dari Bank"** — total uang yang ditarik dari rekening ke kas (akumulasi), dengan tombol **"Cair dari Bank"** (membuka lembar aksi bank untuk menarik dana ke kas).
- Daftar **Transaksi** dengan arah masuk/keluar (`+`/`-`).

**FAB "Catat Dana"** — untuk kas masuk/keluar manual dari salah satu dari 7 pos:

1. Pilih **pos dana** (sumber).
2. Pilih arah **Masuk** (kas bertambah pada pos itu) atau **Keluar** (pos berkurang).
3. Isi **Nominal (Rp) \***, **Tanggal Transaksi \***, **Keterangan \***.
4. Tekan **Simpan**.

Transaksi langsung diposting ke buku besar (Kas 1111 ↔ akun pos), sehingga saldo pos, Total Kas, tab Kas, dan Neraca ikut berubah. Inventaris/aset **tidak** termasuk pos dana dan tidak dapat dijadikan sumber.

### 8.2 Tab "SHU"

Menampilkan kartu perhitungan SHU per tahun dengan badge status **Draft / Disetujui / Terdistribusi**, total SHU, pajak (bila ada), net SHU, rincian alokasi (% & rupiah), dan catatan.

**Alur status:**

1. **Draft** → tombol **"Setujui SHU"**, **Ubah**, **Hapus**.
2. **Disetujui** → tombol **"Distribusikan SHU"** (alokasi sosial/pendidikan/cadangan otomatis tercatat ke Buku Dana), Ubah, Hapus.
3. **Terdistribusi** → tombol **"Batalkan Distribusi"** (kembali menjadi draft).

Setiap aksi meminta konfirmasi dialog. FAB **"Hitung SHU"** membuka lembar perhitungan SHU baru:

- **Tahun Fiskal \***, tombol **"Ambil dari Buku Besar"** (otomatis mengisi Total SHU = laba bersih tahun itu; bila laba ≤ 0 sistem memberi tahu tidak ada laba bersih).
- **Total SHU (Rp) \***, **Pajak (Rp)**.
- **Alokasi (%)** untuk: Cadangan, Sosial, Pendidikan, Dasim (Simpanan), Dapin (Pinjaman), Pengurus & Pengawas, Pegawai, Pembangunan — dengan **pratinjau rupiah langsung** dan validasi total ≤ 100%.
- Checkbox **"Langsung setujui"** (hanya saat baru) dan **Catatan**.
- Tombol **"Simpan & Setujui"** / **"Simpan Draft"** / **"Simpan Perubahan"**.

---

## 9. Aset Koperasi

**Akses:** beranda → modul Buku Inventaris / Penyusutan Aset.

Halaman **"Aset Koperasi"** menampilkan:

- Kartu hijau **"Nilai Buku per <tahun>"**: **Nilai Perolehan (aktif)**, **Akumulasi Penyusutan**, **Nilai Buku**. Tombol kalender untuk memilih tahun (tahun berjalan s.d. 2020).
- Tombol **"Hitung Penyusutan <tahun>"** (atau **"Hitung Ulang Penyusutan <tahun>"** bila sudah pernah dihitung) — metode garis lurus proporsional bulan, dibuat dari seluruh aset aktif.
- **"Buku Penyusutan <tahun>"** — rincian penyusutan tiap aset.
- **"Buku Inventaris (<n>)"** — kartu aset dengan status (badge **Dilepas/Dihapuskan** bila tidak aktif), tanggal & nilai perolehan, umur pakai, residu, dan penyusutan per tahun.

**Aksi:**

- **FAB "Tambah Aset"** → form: **Nama Aset \***, **Tanggal Perolehan \***, **Nilai Perolehan (Rp) \***, **Nilai Residu (Rp)**, **Umur Pakai (tahun) \*** (1–50), pratinjau penyusutan per tahun, **Keterangan** → **Simpan**.
- Ikon **edit** pada kartu aset aktif → ubah aset.
- Ikon **hapus** → dialog **"Hapus Aset?"** (riwayat penyusutan ikut terhapus dan tidak dapat dibatalkan).
- **Hitung Penyusutan** → dialog konfirmasi → sistem membuat baris penyusutan untuk tahun terpilih.

---

## 10. Modul Pajak

**Akses:** beranda → modul Buku Pajak.

- Dua kartu ringkasan: **"Sudah Dibayar"** (hijau) dan **"Belum Dibayar"** (oranye).
- Daftar kartu pajak: jenis pajak, keterangan, tanggal, badge **Dibayar/Belum**, menu **⋮**.

**FAB "Tambah Pajak"** → form: **Jenis Pajak** (PPh 21, PPh 23, PPN, Pajak Lainnya), **Keterangan**, **Jumlah (Rp) \***, **Tanggal**, **Status** (Belum Dibayar/Sudah Dibayar), **Nomor Referensi**, **Catatan**.

**Menu ⋮ pada kartu pajak:**

- **"Tandai Dibayar"** (hanya untuk yang belum dibayar) → mengubah status dan **mem-posting jurnal otomatis** (akrual: saat belum dibayar tampil sebagai Hutang; setelah dibayar, kas 1111 bertambah/tidak — sesuai ketentuan aplikasi, pajak terakrual sebagai kewajiban).
- **"Edit"** → mengubah data pajak.
- **"Hapus"** → menghapus permanen (data + jurnal).

Keberhasilan operasi ditampilkan dalam kartu hijau khusus di bawah daftar.

---

## 11. Unit Usaha Keripik

**Akses:** beranda → modul Unit Keripik / aksi cepat **POS Keripik**.

Halaman **"Unit Usaha Keripik"** memiliki 3 tab. FAB menyesuaikan tab aktif: **"Bahan Baru"**, **"Catat Produksi"**, atau **"Catat Penjualan"**.

### 11.1 Tab Bahan Baku

- Kartu info ringkas: jumlah jenis bahan, pembelian, dan pemakaian tercatat.
- **"Stok Bahan"** — kartu per bahan dengan stok dan tombol **"Beli"** (stok masuk + harga) dan **"Pakai"** (stok keluar; tidak boleh melebihi stok tersedia).
- **"Transaksi Terakhir"** (15 baris terakhir).

**FAB "Bahan Baru"** → daftarkan jenis bahan: **Nama Bahan \*** dan **Satuan \*** (kg, gram, liter, biji, pack).

### 11.2 Tab Produksi

- Kartu **"Total produksi bulan ini"** (kg • gram • pack).
- **"Riwayat Produksi"** — jenis produk (Keripik Kentang, Keripik Salak, Kopi), tanggal, jumlah & satuan, biaya produksi (bila ada).

**FAB "Catat Produksi"** → **Jenis Produk \***, **Tanggal Produksi \***, **Jumlah Hasil \***, satuan, **Hasil Pack** (opsional), **Biaya Produksi** (opsional), **Keterangan**.

### 11.3 Tab Penjualan

- Kartu **"Omzet penjualan bulan ini"**.
- **"Riwayat Penjualan"** dengan ikon hapus per baris (dengan konfirmasi).

**FAB "Catat Penjualan"** → **Jenis Produk \***, **Tanggal Penjualan \***, **Jumlah Terjual \***, satuan, **Harga per satuan (Rp) \*** (dengan pratinjau total penjualan langsung), **Pembeli**, **Keterangan**.

---

## 12. Laporan: Neraca, Buku Besar & Jurnal

Semua laporan dibaca langsung dari buku besar dan tersedia real-time.

### 12.1 Komposisi Keuangan (Neraca)

**Akses:** navigasi **Neraca** atau modul "Komposisi Keuangan".

- Pemilih **tahun** (panah kiri/kanan).
- Banner **"Persamaan Akuntansi"** (`Aset = Kewajiban + Ekuitas + (Pendapatan − Beban)`) dan badge **SEIMBANG/SELISIH**.
- Kartu grup: **ASET (AKTIVA)**, **KEWAJIBAN (PASIVA)**, **EKUITAS / MODAL**, **LABA / (RUGI) BERJALAN**, dan bilah **TOTAL AKTIVA / TOTAL PASIVA**.

### 12.2 Buku Besar

**Akses:** tombol **"Buku Besar"** pada navigasi.

- Filter: tahun + akun (**"Semua Akun"** atau akun tertentu).
- Bilah Total Debit / Total Kredit untuk jurnal terfilter.
- Per akun: header (kode, nama, jenis, jumlah jurnal, **Saldo**) dan baris jurnal D/K dengan chip sumber buku (Kas, Bank, Simpanan, Pinjaman, Angsuran, Dana, Aset, Usaha, Pajak, dsb).

### 12.3 Jurnal

**Akses:** beranda → modul Jurnal.

- Filter lengkap: **tahun**, **akun**, **jenis buku**, dan **rentang tanggal** (Dari … s/d …; otomatis saling menyesuaikan agar konsisten, dengan link "Reset rentang").
- Jurnal dikelompokkan per tanggal secara kronologis, tiap baris menampilkan akun, deskripsi, sumber, dan nilai D/K.

---

## 13. Pengaturan & Tentang

### 13.1 Halaman Pengaturan

Menu dari navigasi **Pengaturan**:

| Menu | Fungsi |
|---|---|
| **Anggota** | Membuka Data Anggota. |
| **Pilih Anggota** | Membuka halaman pemilih anggota. |
| **Buka Pinjaman Anggota** | Pilih anggota → halaman Pinjaman. |
| **Buka Simpanan Anggota** | Pilih anggota → halaman Simpanan. |
| **Tentang** | Informasi aplikasi. |
| **Keluar** | Keluar dari aplikasi (dengan konfirmasi). |

### 13.2 Tentang

Menampilkan logo koperasi, nama (koperasi dapat dikonfigurasi), versi aplikasi, filosofi "Tentang Sadaya", motto, dan informasi aplikasi (nama, versi, pengembang, tahun).

---

## 14. Prinsip Pencatatan

Sadaya menerapkan **auto-posting ke buku besar**: hampir setiap tindakan di aplikasi otomatis membuat jurnal 2 baris (debit = kredit) di tabel `ledger_entries` dalam satu transaksi database (atomik) — validasi saldo juga dilakukan di sisi server.

Contoh:

| Transaksi | Jurnal otomatis |
|---|---|
| Setoran Simpanan Pokok | Debit Kas 1111 / Kredit Simpanan Pokok 3112 |
| Setoran SMS | Debit Kas 1111 / Kredit Simpanan Mana Suka 2111 |
| Pencairan Pinjaman | Debit Piutang Pinjaman 1113 / Kredit Kas 1111 (bersih) + Administrasi 4112 |
| Bayar Cicilan | Debit Kas 1111 / Kredit Piutang + 7 pos distribusi jasa |
| Kas Masuk Dana (manual) | Debit Kas 1111 / Kredit akun pos dana |
| Kas Keluar Dana (manual) | Debit akun pos dana / Kredit Kas 1111 |
| Cair dari Bank | Debit Kas 1111 / Kredit Bank 1112 |
| Pajak belum dibayar | Akrual sebagai Hutang Pajak (kewajiban) |

Karena itu **jumlah kas, saldo pos dana, Buku Besar, Jurnal, dan Neraca selalu selaras** setelah setiap pencatatan — tanpa perlu jurnal manual tambahan. Buku Besar dan Jurnal dapat dipakai untuk menelusuri atau memeriksa setiap jurnal yang timbul.

---

## 15. Tip & Hal yang Perlu Diketahui

1. **Tahun buku**: sebagian besar layar memakai pemilih tahun (bawaan = tahun berjalan). Setiap transaksi diperlakukan pada tanggal yang Anda isi.
2. **Pull-to-refresh**: hampir semua halaman mendukung tarik-ke-bawah untuk memuat ulang data terbaru.
3. **Tidak ada penghapusan jurnal bebas**: transaksi seperti pinjaman/pajak hanya bisa dibatalkan lewat mekanisme yang disediakan (mis. Batalkan Distribusi SHU, Hapus Pajak). Void/penghapusan tidak tersedia di semua modul.
4. **SWK tidak diinput manual**: muncul otomatis dari pembayaran angsuran (10% dari jasa).
5. **Kas vs Dana**: Kas Umum & Bank menampilkan saldo berjalan & sumber pemasukan; Buku Dana khusus mencatat kas masuk/keluar per pos dana. Keduanya saling terhubung lewat buku besar.
6. **Koneksi**: aplikasi membutuhkan akses internet ke Supabase. Saat koneksi terputus, tampilan menampilkan pesan dan tombol **"Coba Lagi"**.