-- =============================================================
-- Sadaya — Migrasi 29: Home hero = "Saldo Koperasi"
--
-- Card utama di Beranda sebelumnya "Total Kas & Aset Lancar" hanya
-- Kas (1111) + Bank (1112). Sesuai model user, angka utama harus
-- "Saldo Koperasi" = Σ |saldo natural| seluruh akun kas + bank
-- + dana (2114/2115/2119/3114/3115/3116) + Japinup (4111).
--
-- Samakan dengan get_cash_ledger_summary agar konsisten dengan Buku Kas.
-- =============================================================
create or replace function public.get_dashboard_summary()
returns jsonb
language plpgsql
set search_path = public
as $$
declare
  v_kas_bank numeric;
  v_piutang numeric;
  v_stok_keripik numeric;
  v_total_asset numeric;
  v_total_liability numeric;
  v_total_equity numeric;
  v_total_revenue numeric;
  v_total_expense numeric;
  v_balanced boolean;
  v_year integer;
  v_total_anggota integer;
  v_anggota_aktif integer;
  v_anggota_nonaktif integer;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  v_year := extract(year from current_date)::int;

  -- Total anggota
  select count(*) into v_total_anggota from public.members;
  select count(*) into v_anggota_aktif
    from public.members where status = 'active';
  v_anggota_nonaktif := v_total_anggota - v_anggota_aktif;

  -- Saldo Koperasi = Σ |saldo natural| kas + bank + dana + Japinup.
  -- Asset: debit-credit; lainnya (liability/equity/revenue): credit-debit.
  select coalesce(sum(bal), 0) into v_kas_bank
  from (
    select
      case
        when coa.account_type = 'asset'
          then abs(coalesce(sum(le.debit_amount - le.credit_amount), 0))
        else abs(coalesce(sum(le.credit_amount - le.debit_amount), 0))
      end as bal
    from public.chart_of_accounts coa
    left join public.ledger_entries le
      on le.account_code = coa.code
     and le.fiscal_year = v_year
     and le.is_void = false
    where coa.code in (
      '1111', '1112',
      '2114', '2115', '2119', '3114', '3115', '3116', '4111'
    )
    group by coa.code, coa.account_type
  ) t;

  -- Piutang Pinjaman (1113 Pinjaman yang diberikan)
  select coalesce(sum(debit_amount - credit_amount), 0) into v_piutang
    from public.ledger_entries
    where fiscal_year = v_year
      and account_code = '1113';

  -- Stok Keripik (produksi - penjualan, basis kg)
  select coalesce(sum(kg), 0) into v_stok_keripik
  from (
    select
      case when unit = 'gram' then quantity_produced / 1000
           else quantity_produced end as kg
    from public.chip_productions
    where production_date::date <= current_date
    union all
    select
      case when unit = 'gram' then quantity * -1 / 1000
           else quantity * -1 end as kg
    from public.chip_sales
    where sale_date::date <= current_date
  ) t;

  -- Neraca status: total_asset vs total_pasiva
  select coalesce(sum(debit_amount - credit_amount), 0) into v_total_asset
    from public.ledger_entries
    where fiscal_year = v_year
      and account_code like '1%';

  select coalesce(sum(credit_amount - debit_amount), 0) into v_total_liability
    from public.ledger_entries
    where fiscal_year = v_year
      and account_code like '2%';

  select coalesce(sum(credit_amount - debit_amount), 0) into v_total_equity
    from public.ledger_entries
    where fiscal_year = v_year
      and account_code like '3%';

  select coalesce(sum(credit_amount - debit_amount), 0) into v_total_revenue
    from public.ledger_entries
    where fiscal_year = v_year
      and account_code like '4%';

  select coalesce(sum(debit_amount - credit_amount), 0) into v_total_expense
    from public.ledger_entries
    where fiscal_year = v_year
      and account_code like '5%';

  v_balanced := abs(v_total_asset - (v_total_liability + v_total_equity + (v_total_revenue - v_total_expense))) < 0.01;

  return jsonb_build_object(
    'kas_bank', v_kas_bank,
    'piutang', v_piutang,
    'stok_keripik', v_stok_keripik,
    'ekuitas', v_total_equity,
    'kewajiban', v_total_liability,
    'balanced', v_balanced,
    'total_anggota', v_total_anggota,
    'anggota_aktif', v_anggota_aktif,
    'anggota_nonaktif', v_anggota_nonaktif
  );
end;
$$;

revoke all on function public.get_dashboard_summary()
  from anon, public;
grant execute on function public.get_dashboard_summary()
  to authenticated;