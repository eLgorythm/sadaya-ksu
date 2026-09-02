-- =============================================================
-- Sadaya — Migrasi 34: Card Home "Aset" = total aktiva (948)
--
-- get_dashboard_summary.kas_bank sebelumnya hanya aset lancar
-- (1111+1112+1113 = 893). Tambahkan aset tetap sehingga card
-- "Aset" di Beranda = total aktiva neraca (948.799.281).
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

  -- Aset = total aktiva (lancar + tetap): kas/bank/piutang + aset tetap.
  select coalesce(sum(debit_amount - credit_amount), 0) into v_kas_bank
    from public.ledger_entries
    where fiscal_year = v_year
      and account_code in (
        '1111', '1112', '1113',
        '1121', '1122', '1123', '1124', '1125', '1126', '1131'
      );

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