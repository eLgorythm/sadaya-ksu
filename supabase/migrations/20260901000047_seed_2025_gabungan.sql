-- =============================================================
-- Sadaya — Migrasi 47 (GABUNGAN SEED 2025): satu file untuk semua
-- swift penggunaan periode 2025 & saldo awal.
--
-- Menggantikan migrasi 22 (opening balance) + 30 (seed kas/bank)
-- menjadi SATU migrasi, plus perbaikan agar saldo awal Kas tampil
-- di tab Kas (get_cash_sources ikut menghitung source_book 'opening').
--
-- Isi:
--   1. Tahun buku 2025 (historis, tertutup) + izin source_book.
--   2. Penutupan 2025 & saldo pembuka 2026 di ledger_entries.
--   3. Seed baris Kas & Bank agar muncul di Buku Kas / Buku Bank.
--   4. get_cash_sources menyertakan saldo awal kas (1111, 'opening').
--
-- Sumber angka: "NERACA KOMPARASI PER 31 DESEMBER 2025"
-- Total debit = kredit = 948.799.281 (seimbang).
-- Aman di-run ulang (guard NOT EXISTS per tahun + sumber).
-- =============================================================

-- =============================================================
-- BAGIAN 1 — Tahun buku 2025 & izin source_book opening/closing
-- =============================================================

insert into public.fiscal_years (year, start_date, end_date, is_active, is_closed)
values (2025, '2025-01-01', '2025-12-31', false, true)
on conflict (year) do nothing;

alter table public.ledger_entries
  drop constraint if exists ledger_entries_source_book_check;

alter table public.ledger_entries
  add constraint ledger_entries_source_book_check
  check (source_book in ('cash', 'bank', 'savings', 'loan', 'installment', 'fund', 'asset', 'chip_business', 'tax', 'opening', 'closing'));

-- =============================================================
-- BAGIAN 2 — Penutupan 2025 & saldo pembuka 2026 (buku besar)
-- =============================================================

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

-- =============================================================
-- BAGIAN 3 — Seed Buku Kas & Buku Bank (transaksi pembuka)
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

-- =============================================================
-- BAGIAN 4 — get_cash_sources ikut menghitung saldo awal kas
--
-- Sebelumnya hanya menghitung source_book installment/fund/savings/
-- bank, sehingga saldo awal kas (source_book 'opening', 1111) yang
-- di-seed di bagian 2 tidak pernah tampil di tab Kas. Tambahkan
-- variabel saldo_awal + total_kas_awal agar angka 177.544.618
-- ikut tercantum.
-- =============================================================

create or replace function public.get_cash_sources(
  p_year integer
)
returns jsonb
language plpgsql
set search_path = public
as $$
declare
  v_result jsonb;
  v_kesra numeric;
  v_sosial numeric;
  v_pendidikan numeric;
  v_crk numeric;
  v_pembangunan numeric;
  v_swk numeric;
  v_japinup numeric;
  v_sms numeric;
  v_bank numeric;
  v_saldo_awal numeric;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  -- Saldo awal Kas (akun 1111, sumber 'opening').
  select into v_saldo_awal
    coalesce(sum(coalesce(debit_amount - credit_amount, 0)), 0)
    from public.ledger_entries
    where account_code = '1111'
      and source_book = 'opening'
      and fiscal_year = p_year
      and is_void = false;

  with pos as materialized (
    select
      k.entry_date,
      k.reference_type,
      k.description,
      p.account_code,
      p.credit_amount
    from public.ledger_entries k
    join public.ledger_entries p
      on p.reference_id::text = k.reference_id::text
     and p.reference_type = k.reference_type
     and p.fiscal_year = p_year
     and p.is_void = false
     and p.account_code in ('4111','2119','2114','2115','3115','3114','2113')
     and p.credit_amount > 0
    where k.account_code = '1111'
      and k.source_book in ('installment', 'fund')
      and k.fiscal_year = p_year
      and k.is_void = false
  )
  select into
    v_kesra, v_sosial, v_pendidikan, v_crk, v_pembangunan, v_swk, v_japinup, v_result
    (select coalesce(sum(credit_amount) filter (where account_code='2119'), 0) from pos),
    (select coalesce(sum(credit_amount) filter (where account_code='2114'), 0) from pos),
    (select coalesce(sum(credit_amount) filter (where account_code='2115'), 0) from pos),
    (select coalesce(sum(credit_amount) filter (where account_code='3115'), 0) from pos),
    (select coalesce(sum(credit_amount) filter (where account_code='3114'), 0) from pos),
    (select coalesce(sum(credit_amount) filter (where account_code='2113'), 0) from pos),
    (select coalesce(sum(credit_amount) filter (where account_code='4111'), 0) from pos),
    coalesce((
      select jsonb_agg(jsonb_build_object(
        'source', account_code,
        'date', to_char(entry_date, 'YYYY-MM-DD'),
        'amount', credit_amount,
        'description', coalesce(description, '')
      ) order by entry_date)
      from pos
    ), '[]'::jsonb);

  select into v_sms
    coalesce(sum(coalesce(le.debit_amount - le.credit_amount, 0)), 0)
    from public.ledger_entries le
    where le.account_code = '1111'
      and le.source_book = 'savings'
      and le.fiscal_year = p_year
      and le.is_void = false;

  -- Cair dari Bank: bank_cair_ke_kas mencatat dengan source_book='bank'
  -- (p_book='bank'), bukan 'cash'. Cari baris 1111 yang punya pasangan 1112.
  select into v_bank
    coalesce(sum(coalesce(le.debit_amount - le.credit_amount, 0)), 0)
    from public.ledger_entries le
    where le.account_code = '1111'
      and le.source_book = 'bank'
      and le.fiscal_year = p_year
      and le.is_void = false
      and exists (
        select 1 from public.ledger_entries p
        where p.reference_id = le.reference_id
          and p.reference_type = le.reference_type
          and p.account_code = '1112'
          and p.is_void = false
      );

  return jsonb_build_object(
    'entries', v_result,
    'pos_kesra', v_kesra,
    'pos_sosial', v_sosial,
    'pos_pendidikan', v_pendidikan,
    'pos_crk', v_crk,
    'pos_pembangunan', v_pembangunan,
    'pos_swk', v_swk,
    'pos_japinup', v_japinup,
    'total_sms', v_sms,
    'total_cair_bank', v_bank,
    'saldo_awal', v_saldo_awal,
    'total', v_saldo_awal + v_kesra + v_sosial + v_pendidikan + v_crk + v_pembangunan + v_swk + v_japinup + v_sms + v_bank
  );
end;
$$;

revoke all on function public.get_cash_sources(integer) from anon, public;
grant execute on function public.get_cash_sources(integer) to authenticated;