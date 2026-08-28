# Flowchart Sistem Aplikasi Koperasi Sadaya — KSU Cahaya Dhamma Phala

Dokumen ini berisi 4 flowchart (format Mermaid):
1. Flowchart Sistem Keseluruhan
2. Alur Dashboard / Pengguna (login → beranda → navigasi modul)
3. Alur Transaksi → Buku Besar (Ledger) → Neraca
4. Alur Simpanan / Pinjaman Anggota

Renders otomatis di GitHub, VS Code (plugin Markdown Preview Mermaid), atau https://mermaid.live.

---

## 1. Flowchart Sistem Keseluruhan

```mermaid
flowchart TD
    U[Pengurus / Anggota Koperasi] -->|Login email + password| AUTH[Auth Supabase<br/>GoRouter redirect]

    AUTH -->|Session valid| SHELL[MainShellPage<br/>Bottom Nav: Beranda | Neraca | Input | Pengaturan]
    AUTH -->|Tidak login| LOGIN[/login/]

    SHELL --> B[Dashboard]
    SHELL --> NERACA[Neraca / Komposisi Keuangan]
    SHELL --> SETT[Pengaturan]
    SHELL --> FAB[FAB Input / Aksi Cepat]

    B --> MOD1[Buku Kas]
    B --> MOD2[Buku Bank]
    B --> MOD3[Buku Pajak]
    B --> MOD4[Simpanan Pokok]
    B --> MOD5[Simpanan Wajib]
    B --> MOD6[Simpanan Mana Suka]
    B --> MOD7[Pinjaman Anggota]
    B --> MOD8[Penerimaan SHU]
    B --> MOD9[Dana Sosial]
    B --> MOD10[Dana Pendidikan]
    B --> MOD11[Dana Kesejahteraan]
    B --> MOD12[Komposisi Keuangan]
    B --> MOD13[Buku Inventaris]
    B --> MOD14[Penyusutan Aset]
    B --> MOD15[Unit Keripik]

    MOD1 & MOD2 --> KEU[/keuangan/]
    MOD3 --> PAJAK[/pajak/]
    MOD4 & MOD5 & MOD6 & MOD7 --> PIHL[Pilih Anggota<br/>/pilih-anggota/]
    MOD8 & MOD9 & MOD10 & MOD11 --> DANA[/dana/]
    MOD12 --> NERACA2[Tab Neraca dalam Shell]
    MOD13 & MOD14 --> ASET[/aset/]
    MOD15 --> USAHA[/usaha/]

    KEU --> POST[Posting otomatis ke Buku Besar]
    PAJAK --> POST
    PIHL --> SIMPIN[Simpanan / Pinjaman Anggota]
    DANA --> POST
    ASET --> POST
    USAHA --> POST
    SIMPIN --> POST

    POST --> LEDGER[(ledger_entries<br/>debit / kredit + COA)]
    LEDGER --> NERACA3[Laporan Komposisi Keuangan<br/>ASET = KEWAJIBAN + EKUITAS]
```

---

## 2. Alur Dashboard / Pengguna

```mermaid
flowchart TD
    START[Pengguna membuka aplikasi] --> ROUTE{GoRouter redirect<br/>apakah session valid?}
    ROUTE -->|Tidak| LOGIN[LoginPage<br/>email + password]
    LOGIN -->|Berhasil| ROUTE
    ROUTE -->|Ya| SHELL[MainShellPage]

    subgraph SHELL2[IndexedStack 3 halaman]
        direction TB
        H[Tab 0: Beranda - HomePage]
        N[Tab 1: Neraca - BalanceSheetPage]
        S[Tab 2: Pengaturan - SettingsPage]
    end

    SHELL --> SHELL2

    H --> LOAD[Load get_dashboard_summary RPC]
    LOAD --> HERO[Laporan Neraca Real-Time + Total Kas & Aset Lancar<br/>+ Piutang + Ekuitas + Stok + Status]
    HERO --> STATS[Baris Statistik Anggota<br/>Total | Aktif | Nonaktif]
    STATS --> QA[Aksi Cepat Transaksi]
    STATS --> FILTER[Filter Tab Modul<br/>Semua | Utama & Kas | Simpan Pinjam | Dana & SHU | Aset & Usaha]
    FILTER --> GRID[Grid 15 Modul Koperasi]

    QA -->|Setor Simpanan| QA1[Pilih Anggota → /simpanan/id]
    QA -->|Cairkan Pinjaman| QA2[Pilih Anggota → /pinjaman/id]
    QA -->|POS Keripik| QA3[/usaha/]
    QA -->|Kas Umum| QA4[/keuangan/]

    GRID --> TAP{Cari modul diklik?}
    TAP -->|Neraca / Komposisi Keuangan| SW[Nyalakan index=1 → Tab Neraca]
    TAP -->|Modul simpanan/pinjaman| PICK[Pilih Anggota]
    TAP -->|Modul lain| ROUTE2[Navigasi context.push ke rute modul]

    FAB[FAB Input di bottom nav] --> BSheet[Bottom Sheet Aksi Cepat<br/>sama dengan Quick Actions]
```

---

## 3. Alur Transaksi → Buku Besar → Neraca

```mermaid
flowchart TD
    subgraph SUMBER[SUMBER TRANSAKSI / BUKU]
        K[Buku Kas & Bank<br/>keuangan]
        SIM[Simpanan<br/>simpanan/cash_ledger]
        PIN[Pinjaman<br/>loans/cash_ledger]
        DAN[SHU & Dana<br/>dana.rpc]
        AST[Aset & Penyusutan<br/>aset.rpc]
        USA[Usaha (keripik)<br/>usaha.rpc]
        P[Pajak<br/>pajak.rpc]
    end

    K --> RPC[RPC Transaksi: insert_* / record_*]
    SIM --> RPC
    PIN --> RPC
    DAN --> RPC
    AST --> RPC
    USA --> RPC
    P --> RPC

    RPC --> VALID{Validasi:<br/>auth.uid() / saldo / status}
    VALID -->|Gagal| ERR[Return error<br/>tampil SnackBar]
    VALID -->|Berhasil| POST[PostLedgerEntry<br/>debit + credit di ledger_entries]

    POST --> LEDGER[(ledger_entries<br/>entry_date, fiscal_year,<br/>account_code, debit, credit,<br/>source_book, reference_type)]

    NERACA_RPC[get_balance_sheet_data(year)] -->|SELECT COA LEFT JOIN ledger<br/>GROUP BY code GROUP BY, HAVING sum ≠ 0| LEDGER
    LEDGER --> AGG[Aggregate saldo per akun<br/>debit/credit balance x account_type]

    AGG --> GRP[Kelompokkan Neraca]
    GRP --> G1[ASET 1xxx]
    GRP --> G2[KEWAJIBAN 2xxx]
    GRP --> G3[EKUITAS 3xxx]
    GRP --> G4[PENDAPATAN 4xxx]
    GRP --> G5[BEBAN 5xxx]

    G1 --> BAL{Keseimbangan?<br/>ASET = LIAB + EKUITAS<br/>+ (PEND − BEBAN)}
    G2 --> BAL
    G3 --> BAL
    G4 --> BAL
    G5 --> BAL

    BAL -->|Ya = 0 (abs < 0.01)| MATCH[Banner SEIMBANG]
    BAL -->|≠ 0| MISMATCH[Banner SELISIH<br/>indikator entri salah]
    MATCH --> UI[BalanceSheetPage<br/>Kartu ASET / KEWAJIBAN / EKUITAS / LABA-RUGI<br/>+ Total Aktiva vs Pasiva]
    MISMATCH --> UI
```

---

## 4. Alur Simpanan / Pinjaman Anggota

```mermaid
flowchart TD
    START{Masuk dari mana?}
    START -->|Modul: Simpanan Pokok / Wajib / Mana Suka| P1
    START -->|Modul: Pinjaman Anggota| P1
    START -->|Quick Action: Setor Simpanan| P1
    START -->|Quick Action: Cairkan Pinjaman| P1
    START -->|Pengaturan: Buka Simpanan/Pinjaman| P1

    P1[openMemberPickerAndGo / inline flow] --> PICK[Push /pilih-anggota<br/>title sesuai mode]

    subgraph PICKER[Halaman Pilih Anggota]
        direction TB
        C0[Pencarian nama + tombol clear]
        C1[Filter chip: Semua | Aktif | Nonaktif<br/>MembersCubit.filterChanged]
        C2[Kartu anggota: nomor, nama, telepon,<br/>tanggal masuk, badge status]
        C0 --> C1 --> C2
    end

    PICK --> PICKER
    PICKER --> POP[Klik anggota → Navigator.pop<br/>mengembalikan MemberEntity]

    POP --> MODE{Mode?}
    MODE -->|Pinjaman| LP[Push /pinjaman/id<br/>extra: MemberLoanTarget]
    MODE -->|Simpanan| SP[Push /simpanan/id<br/>extra: MemberSavingsTarget]

    SP --> SVIEW[Halaman Simpanan Anggota<br/>Kartu saldo: SP | SWB | SMS | SWK]
    SVIEW --> DEP[Tombol Setor Simpanan]
    DEP --> SH1{Filter jenis:<br/>bukan system-managed dan bukan DIV?}
    SH1 -->|Ya| SH2[Form jenis chip + nominal + keterangan]
    SH1 -->|TIDAK| SHX[DIV Dividen SHU disembunyikan<br/>nilai dari sistem, jangan disetor manual]
    SH2 --> SH3[RPC create_savings_transaction<br/>type = deposit]

    SVIEW --> WDL[Tombol Tarik Simpanan Mana Suka]
    WDL --> WH{Saldo SMS > 0?}
    WH -->|Ya| WH2[RPC create_savings_transaction<br/>type = withdrawal]
    WH -->|TIDAK| WHX[Tombol nonaktif]

    SH3 --> MAPPING{Mapping COA}
    MAPPING -->|SP| A1[3112 Simpanan Pokok]
    MAPPING -->|SWB| A2[3113 Simpanan Wajib]
    MAPPING -->|SMS| A3[2111 Simpanan Mana Suka]
    MAPPING -->|SWK| A4[2113 Simpanan Wajib Kredit]
    MAPPING -->|DIV| A5[3118 Akumulasi SHU]
    MAPPING -->|SMS (tarik)| A6[1111 Kas ↔ 2111]

    A1 --> LED[Ledger entry → masuk Neraca]
    A2 --> LED
    A3 --> LED
    A4 --> LED
    A5 --> LED
    A6 --> LED

    LP --> LVIEW[Halaman Pinjaman Anggota]
    LVIEW --> L1[Cairkan Pinjaman<br/>RPC create_loan → posting 1113 Piutang]
    LVIEW --> L2[Detail pinjaman + jadwal angsuran]
    L2 --> L3[Bayar angsuran<br/>RPC record installment → Kas + Piutang berkurang]
    L2 --> L4[Pelunasan / status pinjaman]
```