-- =============================================================
-- ITERASI 14D — Laporan Komposisi Keuangan (Neraca)
-- RPC: get_balance_sheet_data
-- Query ledger_entries join chart_of_accounts, group by code
-- =============================================================

create or replace function public.get_balance_sheet_data(
  p_fiscal_year integer
)
returns jsonb
language plpgsql
set search_path = public
as $$
declare
  v_result jsonb;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  select jsonb_build_object(
    'accounts', coalesce(
      (select jsonb_agg(t) from (
        select
          coa.code,
          coa.name,
          coa.account_type,
          sum(le.debit_amount) as debit_total,
          sum(le.credit_amount) as credit_total,
          sum(le.debit_amount - le.credit_amount) as balance
        from public.chart_of_accounts coa
        left join public.ledger_entries le
          on le.account_code = coa.code and le.fiscal_year = p_fiscal_year
        group by coa.code, coa.name, coa.account_type
        having sum(le.debit_amount) > 0 or sum(le.credit_amount) > 0
        order by coa.code
      ) t),
      '[]'::jsonb
    )
  ) into v_result;

  return v_result;
end;
$$;

revoke all on function public.get_balance_sheet_data(integer)
  from anon, public;
grant execute on function public.get_balance_sheet_data(integer)
  to authenticated;
