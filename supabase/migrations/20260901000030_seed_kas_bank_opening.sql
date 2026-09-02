-- =============================================================
-- Sadaya — Migrasi 30: Seed transaksi awal Buku Kas & Buku Bank
--
-- Tabel bank_transactions & cash_transactions kosong karena saldo
-- pembuka hanya ditulis ke ledger_entries (migrasi 00022).
-- Tambahkan baris "saldo awal" ke kedua tabel agar Buku Kas dan
-- Buku Bank menampilkan transaksi awal & saldonya sesuai buku besar:
--   Kas  1111 = 177.544.618
--   Bank 1112 = 258.709.183
-- (sumber: NERACA KOMPARASI per 31-12-2025)
-- Aman di-run ulang (guard NOT EXISTS per source_book + tanggal).
-- =============================================================

insert into public.cash_transactions (
  transaction_date, transaction_type, amount, description,
  reference_type, created_by
)
select
  date '2026-01-01',
  'income',
  177544618,
  'Saldo awal kas per 31-12-2025',
  'manual',
  null
where not exists (
  select 1 from public.cash_transactions
   where transaction_date = date '2026-01-01'
     and description like 'Saldo awal kas%'
);

insert into public.bank_transactions (
  transaction_date, transaction_type, amount, description,
  bank_name, reference_number, created_by
)
select
  date '2026-01-01',
  'credit',
  258709183,
  'Saldo awal bank per 31-12-2025',
  null,
  null,
  null
where not exists (
  select 1 from public.bank_transactions
   where transaction_date = date '2026-01-01'
     and description like 'Saldo awal bank%'
);