-- =============================================================
-- Sadaya — Migrasi 32: RPC "Aset Lancar"
--
-- Buku Kas & card Beranda menampilkan "Aset Lancar" = total AKTIVA
-- LANCAR, murni sisi aset (tidak mencampur dana pasiva / Japinup):
--   Kas (1111) + Bank (1112) + Pinjaman yang Diberikan (1113)
--
-- Catatan: get_cash_ledger_summary tetap utuh (rincian dana + Japinup)
-- dan dipakai modul Buku Dana. Fungsi baru get_aset_lancar_summary
-- khusus Buku Kas ("Aset Lancar") dan Beranda.
-- =============================================================

-- ---------- get_aset_lancar_summary (baru) ----------
create or replace function public.get_aset_lancar_summary(
  p_year integer
)
returns jsonb
language plpgsql
set search_path = public
as $$
declare
  v_result jsonb;
  v_total numeric;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  with bal as (
    select
      coa.code,
      coa.name,
      coa.account_type,
      abs(coalesce(sum(le.debit_amount - le.credit_amount), 0)) as balance
    from public.chart_of_accounts coa
    left join public.ledger_entries le
      on le.account_code = coa.code
     and le.fiscal_year = p_year
     and le.is_void = false
    where coa.code in ('1111', '1112', '1113')
    group by coa.code, coa.name, coa.account_type
  )
  select into v_result, v_total
    coalesce(
      (select jsonb_agg(jsonb_build_object(
          'code', code,
          'name', name,
          'account_type', account_type,
          'balance', balance
        ) order by code) from bal),
      '[]'::jsonb
    ),
    coalesce((select sum(balance) from bal), 0);

  return jsonb_build_object('accounts', v_result, 'total', v_total);
end;
$$;

revoke all on function public.get_aset_lancar_summary(integer) from anon, public;
grant execute on function public.get_aset_lancar_summary(integer) to authenticated;

-- ---------- get_dashboard_summary (kas_bank = aset lancar) ----------
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

  -- Aset Lancar = Kas (1111) + Bank (1112) + Pinjaman (1113), sisi aset.
  select coalesce(sum(debit_amount - credit_amount), 0) into v_kas_bank
    from public.ledger_entries
    where fiscal_year = v_year
      and account_code in ('1111', '1112', '1113');

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