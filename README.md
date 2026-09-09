# Sistem Aplikasi Koperasi Sadaya — KSU Cahaya Dhamma Phala

Aplikasi **manajemen koperasi** berbasis Flutter + Supabase. Mencakup admin anggota,
simpanan & pinjaman, buku kas/bank, unit usaha (Unit Krisado), aset, pajak,
SDK Pembagian Sisa Hasil Usaha (SHU), hingga **Buku Besar (ledger)** dan
**Neraca real-time** yang tersinkron otomatis.

## Fitur Utama

- **Dashboard** — ringkasan neraca real-time, saldo kas total, stok keripik,
  statistik anggota, 16 modul koperasi, dan aksi cepat transaksi.
- **Simpanan Anggota** — Simpanan Pokok, Wajib, Mana Suka, Wajib Kredit + tarik SMS.
- **Pinjaman Anggota** — pencairan, jadwal angsuran, pembayaran cicilan,
  dan bunga per angsuran (2% pokok/angsuran; cepat: 3% × pokok × tenor).
- **Buku Kas & Bank** — catat masuk/keluar, dana masuk bank, cairkan ke kas.
- **Unit Krisado** — kas unit **berdiri sendiri** (akun `1114`), stok & produksi
  bahan baku, penjualan, dan **Ambil dari Bank** ke kas unit. Akun lawan tetap
  akun koperasi agar neraca/laba benar.
- **Aset & Penyusutan** — inventaris dan depresiasi periodik.
- **Pajak** — Buku Pajak dengan akrual `2122 Hutang Pajak`.
- **SHU & Dana** — alokasi hasil usaha 8 pos (Modal, Cadangan, Pendidikan, dsb).
- **Buku Besar & Neraca** — seluruh transaksi mem-posting jurnal D/K ke
  `ledger_entries`; neraca dikelompokkan per COA dan otomatis seimbang.

## Teknologi

- **Flutter** (Android, iOS, Windows) — `flutter_bloc`, `go_router`, `get_it` + `injectable`
- **Supabase** (PostgreSQL + RLS + RPC) — migrasi di `supabase/migrations/`
- **Mermaid** diagram di [`Flowchart-Sadaya.md`](Flowchart-Sadaya.md)

## Struktur Proyek

```
lib/
  core/            # tema, router, widget bersama, utilitas, ledger
  features/
    auth/          # login/logout
    anggota/       # data anggota + pilih anggota
    dashboard/     # beranda (shell, modul, aksi cepat)
    keuangan/      # buku kas & bank, laporan
    simpanan/      # simpanan anggota
    pinjaman/      # pinjaman & angsuran
    usaha/         # Unit Krisado (bahan, produksi, penjualan, saldo)
    aset/          # inventaris & penyusutan
    dana/          # SHU & dana
    pajak/         # buku pajak
    laporan/       # neraca & buku besar
supabase/migrations/   # migration SQL berurutan (COA, RPC, RLS)
```

## Cara Menjalankan

1. Salin `.env.example` (atau isi `.env`) dengan kredensial Supabase:
   ```
   SUPABASE_URL=https://xxxx.supabase.co
   SUPABASE_PUBLISHABLE_KEY=eyJ...
   ```
2. Pasang dependensi & jalankan:
   ```bash
   flutter pub get
   flutter run
   ```
3. (Opsional) Regenerasi dependensi injeksi setelah menambah `@Injectable`:
   ```bash
   dart run build_runner build
   ```

> `.env` sengaja di-gitignore dan ikut dikemas sebagai asset — hanya berisi
> *publishable key* yang aman untuk publik. **Jangan** menaruh `service_role`
> key di sana.

## Dokumentasi

- [`Flowchart-Sadaya.md`](Flowchart-Sadaya.md) — 4 flowchart sistem (Mermaid)
- [`Panduan-Penggunaan.md`](Panduan-Penggunaan.md) — panduan fitur per modul
- [`Dokumen-Produk-Sadaya.md`](Dokumen-Produk-Sadaya.md) — spesifikasi produk
- [`Laporan-KKN.md`](Laporan-KKN.md) — laporan KKN

## Skema Akun (Chart of Accounts)

Modul yang relevan:

| Kode | Akun | Keterangan |
|------|------|------------|
| 1111 | Kas | Kas koperasi (Buku Kas) |
| 1112 | Bank | Rekening (Buku Bank) |
| 1113 | Pinjaman diberikan | Piutang pinjaman anggota |
| 1114 | Kas Unit Krisado | Kas mandiri Unit Krisado |
| 1130 | Persediaan Bahan Baku | Stok bahan unit |
| 2111/2113 | Simpanan Mana Suka / Wajib Kredit | Kewajiban ke anggota |
| 2122 | Hutang Pajak | Akrual pajak |
| 3112/3113/3118 | Simpanan Pokok/Wajib, Akumulasi SHU | Ekuitas |
| 4114–4116 | Pendapatan unit (Kopi/Kentang/Salak) | Akun lawan penjualan |
| 5125 | Biaya Bahan Baku Keripik | Beban unit |

Neraca dikelompokkan otomatis: **1xxx Aset, 2xxx Kewajiban, 3xxx Ekuitas,
4xxx Pendapatan, 5xxx Beban** — dengan indikator SEIMBANG/SELISIH.