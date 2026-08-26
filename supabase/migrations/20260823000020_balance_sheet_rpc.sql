-- =============================================================
-- ITERASI 14D — Laporan Komposisi Keuangan (Neraca)
-- RPC: get_balance_sheet_data
-- Query ledger_entries join chart_of_accounts, group by account_type & code
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
      (select jsonb_agg(
        jsonb_build_object(
          'code', coa.code,
          'name', coa.name,
          'account_type', coa.account_type,
          'debit_total', sub.debit_total,
          'credit_total', sub.credit_total,
          'balance', sub.balance
        )
      )
      from (
        select
          le.account_code,
          sum(le.debit_amount) as debit_total,
          sum(le.credit_amount) as credit_total,
          sum(le.debit_amount - le.credit_amount) as balance
        from public.ledger_entries le
        where le.fiscal_year = p_fiscal_year
        group by le.account_code
      ) sub
      join public.chart_of_accounts coa on coa.code = sub.account_code
      order by coa.code),
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
