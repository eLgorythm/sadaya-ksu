-- =============================================================
-- Sadaya — Migrasi 33: Aset (aktiva lancar + aset tetap)
--
-- Jumlahkan seluruh akun AKTIVA sehingga headline = total aktiva
-- neraca (948.799.281 per 31-12-2025), bukan hanya aktiva lancar.
--   Lancar : 1111, 1112, 1113
--   Tetap  : 1121, 1122, 1123, 1124, 1125, 1126, 1131
-- Hanya fungsi get_aset_lancar_summary yang dipakai Buku Kas.
-- =============================================================

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
    where coa.code in (
      '1111', '1112', '1113',
      '1121', '1122', '1123', '1124', '1125', '1126', '1131'
    )
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