-- =============================================================
-- ITERASI 21 — Saldo Awal 2025/2026 (periode 2025 & 2026 terpisah)
--
-- 1. Tambah tahun buku 2025 (aktif=false, tertutup).
-- 2. Izinkan source_book 'opening' & 'closing' pada ledger_entries.
-- 3. Penutupan 2025: saldo per akun per 31-12-2025 (fiscal_year 2025).
-- 4. Saldo pembuka 2026: pos yang sama tanggal 01-01-2026 (fiscal_year 2026).
--
-- Sumber: "Dokumen/7. 8 NERACA KOMPARASI PER 31 DESEMBER 2025.xlsx"
-- Total debit = kredit = 948.799.281 (seimbang).
-- Aman di-run ulang (guard NOT EXISTS per tahun + sumber).
-- =============================================================

-- 1. Tahun buku 2025 (periode historis tertutup)
insert into public.fiscal_years (year, start_date, end_date, is_active, is_closed)
values (2025, '2025-01-01', '2025-12-31', false, true)
on conflict (year) do nothing;

-- 2. Perluas izin source_book + 'opening' & 'closing'
alter table public.ledger_entries
  drop constraint if exists ledger_entries_source_book_check;

alter table public.ledger_entries
  add constraint ledger_entries_source_book_check
  check (source_book in ('cash', 'bank', 'savings', 'loan', 'installment', 'fund', 'asset', 'chip_business', 'tax', 'opening', 'closing'));

-- 3. Penutupan tahun 2025 (saldo per 31-12-2025)
insert into public.ledger_entries (
  entry_date, account_code, source_book, reference_id, reference_type,
  debit_amount, credit_amount, description, fiscal_year, created_by
)
select
  date '2025-12-31',
  t.account_code,
  'closing',
  '00000000-0000-0000-0000-000000000002'::uuid,
  'closing',
  t.debit,
  t.credit,
  'Penutupan tahun 2025 — ' || t.label,
  2025,
  null
from (values
  -- AKTIVA
  ('1111', 177544618, 0,        'Kas'),
  ('1112', 258709183, 0,        'Simpanan Di Bank'),
  ('1113', 456870000, 0,        'Pinjaman yang diberikan'),
  ('1121', 16564680,  0,        'Rumah Produksi'),
  ('1122', 2950000,   0,        'Freezer'),
  ('1123', 4350000,   0,        'Dastang'),
  ('1124', 25485000,  0,        'Vacuum Frying'),
  ('1125', 1860800,   0,        'Tabung Gas'),
  ('1126', 465000,    0,        'Gerabah'),
  ('1131', 4000000,   0,        'Printer'),
  -- PASSIVA & MODAL
  ('2111', 0, 361297246,        'Simpanan Manasuka'),
  ('2113', 0, 8611000,          'Simpanan Wajib Kredit'),
  ('2114', 0, 10159927,         'Dana Sosial'),
  ('2115', 0, 7642726,          'Dana Pendidikan'),
  ('2116', 0, 15982090,         'Penyisihan Biaya RAT'),
  ('2117', 0, 13302642,         'Penyisihan Jasa SM'),
  ('2118', 0, 38006448,         'Penyisihan Lain-lain'),
  ('2119', 0, 27221445,         'Dana Kesejahteraan Anggota'),
  ('3111', 0, 55675480,         'Modal Tetap'),
  ('3112', 0, 16400000,         'Simpanan Pokok'),
  ('3113', 0, 310554000,        'Simpanan Wajib'),
  ('3114', 0, 6590824,          'Dana Pembangunan'),
  ('3115', 0, 14936661,         'Dana Cadangan Resiko Kredit'),
  ('3116', 0, 25513535,         'Dana Cadangan'),
  ('3117', 0, 5000000,          'Modal Penyertaan'),
  ('3118', 0, 31905257,         'Sisa Hasil Usaha')
) as t(account_code, debit, credit, label)
where not exists (
  select 1 from public.ledger_entries
   where source_book = 'closing' and fiscal_year = 2025
);

-- 4. Saldo pembuka 2026 (pos yang sama dibawa ke awal 2026)
insert into public.ledger_entries (
  entry_date, account_code, source_book, reference_id, reference_type,
  debit_amount, credit_amount, description, fiscal_year, created_by
)
select
  date '2026-01-01',
  t.account_code,
  'opening',
  '00000000-0000-0000-0000-000000000001'::uuid,
  'opening',
  t.debit,
  t.credit,
  'Saldo awal per 31-12-2025 — ' || t.label,
  2026,
  null
from (values
  -- AKTIVA
  ('1111', 177544618, 0,        'Kas'),
  ('1112', 258709183, 0,        'Simpanan Di Bank'),
  ('1113', 456870000, 0,        'Pinjaman yang diberikan'),
  ('1121', 16564680,  0,        'Rumah Produksi'),
  ('1122', 2950000,   0,        'Freezer'),
  ('1123', 4350000,   0,        'Dastang'),
  ('1124', 25485000,  0,        'Vacuum Frying'),
  ('1125', 1860800,   0,        'Tabung Gas'),
  ('1126', 465000,    0,        'Gerabah'),
  ('1131', 4000000,   0,        'Printer'),
  -- PASSIVA & MODAL
  ('2111', 0, 361297246,        'Simpanan Manasuka'),
  ('2113', 0, 8611000,          'Simpanan Wajib Kredit'),
  ('2114', 0, 10159927,         'Dana Sosial'),
  ('2115', 0, 7642726,          'Dana Pendidikan'),
  ('2116', 0, 15982090,         'Penyisihan Biaya RAT'),
  ('2117', 0, 13302642,         'Penyisihan Jasa SM'),
  ('2118', 0, 38006448,         'Penyisihan Lain-lain'),
  ('2119', 0, 27221445,         'Dana Kesejahteraan Anggota'),
  ('3111', 0, 55675480,         'Modal Tetap'),
  ('3112', 0, 16400000,         'Simpanan Pokok'),
  ('3113', 0, 310554000,        'Simpanan Wajib'),
  ('3114', 0, 6590824,          'Dana Pembangunan'),
  ('3115', 0, 14936661,         'Dana Cadangan Resiko Kredit'),
  ('3116', 0, 25513535,         'Dana Cadangan'),
  ('3117', 0, 5000000,          'Modal Penyertaan'),
  ('3118', 0, 31905257,         'Sisa Hasil Usaha')
) as t(account_code, debit, credit, label)
where not exists (
  select 1 from public.ledger_entries
   where source_book = 'opening' and fiscal_year = 2026
);