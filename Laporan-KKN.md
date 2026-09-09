# LAPORAN KULIAH KERJA NYATA (KKN)

## Pengembangan Sistem Informasi Koperasi "Sadaya" untuk KSU Cahaya Dhamma Phala

*> Dokumen ini adalah draf kerangka laporan KKN. Bagian dalam tanda kurung siku [ ] wajib diisi sesuai data Anda. Seluruh rincian fitur merujuk aplikasi Sadaya (versi yang dikembangkan), jadi materi bisa langsung disesuaikan/editing.*

---

## LEMBAR PENGESAHAN

| | |
|---|---|
| Nama | : [Nama Mahasiswa] |
| NIM / NPM | : [NIM] |
| Program Studi | : [Program Studi] |
| Universitas | : [Universitas] |
| Lokasi KKN | : [Desa/Kelurahan, Kabupaten, Provinsi] |
| Mitra | : KSU Cahaya Dhamma Phala |
| Periode Pelaksanaan | : [Tanggal mulai] — [Tanggal selesai] |

Mengetahui,

Pengurus Koperasi Mitra, &nbsp;&nbsp;&nbsp;&nbsp; Dosen Pembimbing Lapangan,

```
[ Nama Pengurus ]                  [ Nama DPL ]
```

---

## KATA PENGANTAR

Puji syukur penulis panjatkan kepada ... [uraian rasa syukur]. Laporan ini disusun sebagai pertanggungjawaban pelaksanaan Kuliah Kerja Nyata (KKN) di [lokasi], dengan mitra KSU Cahaya Dhamma Phala, berupa pendampingan pengelolaan koperasi melalui pengembangan **Sistem Informasi Koperasi "Sadaya"**.

Dalam pelaksanaannya, penulis mendapatkan banyak bantuan dari berbagai pihak. Penulis menyampaikan terima kasih kepada: ... [daftar pihak yang perlu disebut]. Penulis menyadari laporan ini masih jauh dari sempurna, sehingga kritik dan saran sangat diharapkan. Semoga laporan ini bermanfaat.

[Kota], [tanggal] &nbsp;&nbsp;&nbsp;&nbsp; Penulis,

```
[Nama Mahasiswa]
[NIM]
```

---

## DAFTAR ISI

> Tuliskan daftar isi lengkap mengikuti struktur di bawah (setelah halaman ini diisi ulang sesuai heading sebenarnya).

---

## BAB I — PENDAHULUAN

### 1.1 Latar Belakang

Koperasi sebagai badan usaha berbasis keanggotaan dituntut mampu mengelola keuangan secara transparan dan akuntabel. KSU Cahaya Dhamma Phala merupakan koperasi yang melayani [deskripsi singkat anggota/layanan: simpanan, pinjaman, dana sosial, unit usaha]. Sebelum program ini, pengelolaan masih dilakukan dengan pencatatan manual/spreadsheet yang memiliki beberapa kelemahan, antara lain:

- Pencatatan terpisah antarbuku (kas, bank, simpanan, pinjaman, dana, aset) sehingga sulit disinkronkan.
- Tidak ada jurnal/neraca otomatis; penyusunan laporan keuangan dilakukan berkala dan rawan selisih.
- Tidak ada kontrol otomasi seperti validasi saldo, distribusi bunga, dan pencegahan pencatatan ganda.

Berdasarkan permasalahan tersebut, KKN ini melaksanakan program kerja berupa **pengembangan sistem informasi koperasi terpadu (Sadaya)** yang mencatat seluruh transaksi dan menyusun laporan keuangan (buku besar, jurnal, neraca) secara otomatis dan real-time.

### 1.2 Rumusan Masalah

1. Bagaimana merancang sistem informasi yang mengintegrasikan pencatatan kas, bank, simpanan, pinjaman, dana, aset, pajak, dan unit usaha dalam satu basis data terpadu?
2. Bagaimana memastikan setiap transaksi tercatat sebagai jurnal (buku besar) dan menghasilkan laporan keuangan yang seimbang/akurat?
3. Bagaimana sistem dapat digunakan dengan mudah oleh pengurus koperasi yang tidak berlatar belakang teknologi?

### 1.3 Tujuan dan Sasaran

- Menghasilkan aplikasi **Sadaya** sebagai media pencatatan dan pelaporan keuangan koperasi.
- Mengimplementasikan prinsip **double-entry bookkeeping** (auto-posting ke buku besar) sehingga setiap transaksi otomatis membentuk jurnal debit-kredit yang seimbang.
- Mendampingi pengurus agar mampu menggunakan sistem dalam kegiatan operasional sehari-hari.

### 1.4 Manfaat

- **Bagi mitra:** pencatatan lebih tertib, laporan (neraca, buku besar, jurnal) tersedia real-time, dan keputusan pengurus didukung data yang akurat.
- **Bagi Mahasiswa:** sarana mengaplikasikan ilmu pengembangan perangkat lunak di tengah masyarakat/sektor riil.
- **Bagi perguruan tinggi:** wujud pengabdian kepada masyarakat sesuai Tri Dharma.

### 1.5 Ruang Lingkup

Sistem mencakup modul: anggota, simpanan (pokok, wajib, manasuka, wajib kredit), pinjaman dan angsuran, kas umum & bank, dana & SHU, aset & penyusutan, pajak, unit usaha keripik, serta laporan (neraca, buku besar, jurnal).

---

## BAB II — GAMBARAN UMUM LOKASI DAN CONDISI MITRA

### 2.1 Profil Mitra

KSU Cahaya Dhamma Phala adalah koperasi di [lokasi] yang melayani [jumlah ±] anggota. Kegiatan utamanya meliputi: [contoh] penghimpunan simpanan (pokok, wajib bulanan, manasuka, simpanan wajib kredit), penyaluran pinjaman berjangka, pengelolaan dana sosial/pendidikan/kesejahteraan, serta unit usaha keripik kentang/salak dan kopi.

### 2.2 Kondisi Pencatatan Sebelum Program

Pengurus mencatat transaksi secara terpisah: buku kas, buku bank, buku simpanan, buku pinjaman (angsuran), buku dana, buku inventaris, dan pembukuan pajak. Kondisi yang ditemui:

- Tidak ada satu sumber data yang sama antar-buku.
- Distribusi jasa (bunga) dari angsuran ke pos-pos dana masih dihitung manual.
- Penyusunan neraca dan laporan masih disusun manual sehingga memakan waktu dan rawan selisih.

### 2.3 Analisis Kebutuhan

Dari observasi dan wawancara pengurus, disimpulkan kebutuhan:

1. Satu basis data terpadu bagi seluruh transaksi.
2. Jurnal otomatis agar buku besar dan neraca selalu seimbang.
3. Validasi saldo (penarikan tidak melebihi saldo, penggunaan dana per pos terkontrol).
4. Tampilan yang sederhana dan ramah bagi pengurus (bahasa Indonesia, mobile/desktop).

---

## BAB III — METODE PELAKSANAAN

### 3.1 Waktu dan Lokasi

- **Lokasi:** [Desa/Kelurahan], [Kabupaten], [Provinsi].
- **Waktu:** [tanggal] — [tanggal], meliputi survei, pengembangan, uji coba, dan pendampingan.

### 3.2 Metode Pendekatan

| Tahap | Metode | Hasil |
|---|---|---|
| Analisis | Observasi & wawancara pengurus | Peta proses bisnis koperasi & kebutuhan modul |
| Perancangan | Desain skema basis data & alur transaksi | Bagian Akun (COA), jurnal, dan relasi modul |
| Pengembangan | Iterasi per modul (agile) | Aplikasi Sadaya dengan 16 modul |
| Uji coba | Pengujian bersama pengurus | Koreksi alur & validasi |
| Pendampingan | Pelatihan penggunaan | Pengurus mampu menjalankan sistem |

### 3.3 Tahapan Pelaksanaan

1. **Survei awal & identifikasi** — memahami proses pembukuan koperasi.
2. **Perancangan sistem** — menyusun bagan akun, aturan jurnal tiap transaksi, dan skema keamanan data.
3. **Pengembangan inti** — autentikasi, data anggota, simpanan, pinjaman, dan mesin buku besar.
4. **Pengembangan modul lanjutan** — kas & bank, dana & SHU, aset, pajak, unit usaha, dan laporan.
5. **Uji coba dan sosialisasi** — simulasi transaksi riil bersama pengurus.
6. **Pendampingan** — penggunaan harian dan pemeliharaan berkelanjutan.

---

## BAB IV — HASIL, LUARAN, DAN PEMBAHASAN

### 4.1 Produk yang Dihasilkan

Aplikasi **Sadaya** — sistem informasi koperasi berbasis Flutter (antarmuka) dan Supabase/PostgreSQL (basis data, dengan aturan bisnis di sisi server agar aman dan atomik). Pengurus mengakses lewat aplikasi desktop/Windows dan perangkat bergerak.

### 4.2 Fitur dan Modul

Berikut modul yang berhasil dikembangkan dan dipakai koperasi:

| No | Modul | Keterangan |
|---|---|---|
| 1 | Login pengurus | Autentikasi email & password, pengalihan otomatis. |
| 2 | Data Anggota | Tambah/edit/nonaktifkan, pencarian, nomor otomatis. |
| 3 | Simpanan | Setor & tarik (Pokok, Wajib Bulanan, Mana Suka, Wajib Kredit). |
| 4 | Pinjaman | Pencairan (biasa & cepat), jadwal cicilan, bayar angsuran, distribusi jasa otomatis. |
| 5 | Kas Umum & Bank | Saldo berjalan, sumber pemasukan kas, buku bank, aksi bank (dana masuk / cair ke kas). |
| 6 | Dana & SHU | Buku dana 7 pos, kas masuk/keluar manual, hitung–setujui–distribusi SHU. |
| 7 | Aset Koperasi | Buku inventaris & penyusutan garis lurus. |
| 8 | Modul Pajak | Buku pajak dengan akrual hutang pajak. |
| 9 | Unit Usaha Keripik | Stok bahan baku, produksi, penjualan, omzet. |
| 10 | Laporan | Neraca (komposisi keuangan), Buku Besar, dan Jurnal real-time. |
| 11 | Beranda/Aksi cepat | Ringkasan neraca, statistik anggota, aksi cepat, navigasi 16 modul. |

### 4.3 Prinsip Auto-Posting (Buku Besar)

Setiap transaksi otomatis menghasilkan jurnal debit = kredit pada tabel buku besar dalam satu transaksi database (atomik). Contoh yang diimplementasikan:

| Transaksi | Jurnal |
|---|---|
| Setoran Simpanan Pokok | Debit Kas / Kredit Simpanan Pokok |
| Pencairan Pinjaman | Debit Piutang Pinjaman / Kredit Kas (bersih) + Administrasi |
| Bayar Cicilan | Debit Kas / Kredit Piutang + distribusi ke 7 pos dana (Japinup 55%, Kesra 25%, SWK 10%, Sosial/Pendidikan/CRK/Pembangunan @2,5%) |
| Kas Masuk/Keluar Dana (manual) | Kas (1111) ↔ akun pos dana |
| Cair dari Bank | Debit Kas / Kredit Bank |
| Pajak belum dibayar | Akrual sebagai Hutang Pajak |

Dengan begitu, **neraca selalu tersusun otomatis dan seimbang**, dan laporan dapat diperoleh kapan saja tanpa menunggu akhir periode.

### 4.4 Pengujian dan Evaluasi

Pengujian dilakukan bersama pengurus melalui kasus riil: simpanan, pencairan & pembayaran cicilan, pencatatan kas dana, aksi bank, dan penyusutan aset. Hasil: seluruh jurnal tampil seimbang; saldo pos dana dan tab Kas tercatat selaras; kendala minor (mis. tata letak layar kecil) diperbaiki melalui pembungkus tata letak responsif untuk desktop Windows.

Kuisioner/indikator kepuasan pengurus menunjukkan [isi capaian, mis. "seluruh pengurus menilai sistem mudah digunakan dan membantu penyusunan laporan"].

### 4.5 Luaran

- Aplikasi **Sadaya** (kode sumber tersimpan di repositori [tautan]);
- Panduan penggunaan aplikasi (`Panduan-Penggunaan.md`);
- Peningkatan tata kelola: pencatatan terpadu, validasi saldo, dan laporan real-time.

---

## BAB V — PENUTUP

### 5.1 Kesimpulan

1. Sistem informasi **Sadaya** berhasil mengintegrasikan seluruh pencatatan koperasi (kas, bank, simpanan, pinjaman, dana, aset, pajak, dan unit usaha) dalam satu basis data.
2. Prinsip auto-posting jurnal membuat buku besar, jurnal, dan neraca tersusun otomatis dan selalu seimbang, sehingga mengurangi pekerjaan manual pengurus.
3. Aplikasi digunakan oleh pengurus dalam kegiatan operasional dan mendapat respons positif dari sisi kemudahan penggunaan.

### 5.2 Saran

- Melanjutkan pendampingan dan pengembangan: hak akses berjenjang (pengurus/pengawas), ekspor laporan (PDF/Excel), serta fitur void dengan jejak audit.
- Menerapkan pencadangan data rutin dan sosialisasi kepada anggota untuk transparansi.
- Menjaga kelangsungan pemeliharaan sistem oleh koperasi/instansi pendamping.

---

## LAMPIRAN

1. [Dokumentasi kegiatan — foto/scan]
2. [Struktur basis data / bagan akun]
3. [Panduan Penggunaan Aplikasi — Panduan-Penggunaan.md]
4. [Surat keterangan mitra (jika ada)]

---

### Catatan Penyuntingan

- Ganti semua `[ ... ]` dengan data aktual.
- Sesuaikan jumlah anggota, layanan, dan angka riil pada tabel 4.4 sesuai hasil di lapangan.
- Sisipkan dokumentasi foto pada bagian lampiran.