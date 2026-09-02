-- =============================================================
-- Sadaya — Migrasi 36: Buku Kas — Saldo berjalan sisi kredit
--
-- Saldo berjalan Buku Kas memuat seluruh akun sisi kredit
-- (kewajiban + ekuitas + pendapatan) KECUALI Modal Tetap (3111).
-- Akun aset (debit) dan beban (5xx) tidak termasuk di sini.
-- =============================================================
create or replace function public.get_cash_ledger_summary(
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
      abs(coalesce(sum(le.credit_amount - le.debit_amount), 0)) as balance
    from public.chart_of_accounts coa
    left join public.ledger_entries le
      on le.account_code = coa.code
     and le.fiscal_year = p_year
     and le.is_void = false
    where coa.account_type in ('liability', 'equity', 'revenue')
      and coa.code <> '3111'
    group by coa.code, coa.name, coa.account_type
    having abs(coalesce(sum(le.credit_amount - le.debit_amount), 0)) <> 0
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

revoke all on function public.get_cash_ledger_summary(integer) from anon, public;
grant execute on function public.get_cash_ledger_summary(integer) to authenticated;