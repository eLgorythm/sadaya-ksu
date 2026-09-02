-- =============================================================
-- Sadaya — Migrasi 27: Ringkasan buku kas dari buku besar (ledger)
--
-- Buku Kas = saldo koperasi. "Kas" mencakup kas (1111), bank (1112),
-- dan seluruh dana (2114 Sosial, 2115 Pendidikan, 2119 Kesra,
-- 3114 Pembangunan, 3115 CRK, 3116 Cadangan) serta Japinup (4111).
--
-- Card "Saldo Berjalan" di Buku Kas = jumlah nilai utuh (|saldo|) tiap
-- akun tsb (per model user), plus rincian per akun.
--
-- RPC: get_cash_ledger_summary(p_year) -> jsonb
--   {
--     "accounts": [ {code,name,account_type,balance} ... dalam |saldo| ],
--     "total": number   // Σ |balance| seluruh akun kas+dana
--   }
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
      case
        when coa.account_type = 'asset'
          then abs(coalesce(sum(le.debit_amount - le.credit_amount), 0))
        else abs(coalesce(sum(le.credit_amount - le.debit_amount), 0))
      end as balance
    from public.chart_of_accounts coa
    left join public.ledger_entries le
      on le.account_code = coa.code
     and le.fiscal_year = p_year
     and le.is_void = false
    where coa.code in (
      '1111', '1112',
      '2114', '2115', '2119', '3114', '3115', '3116', '4111'
    )
    group by coa.code, coa.name, coa.account_type
    having coalesce(sum(le.debit_amount), 0) <> 0
        or coalesce(sum(le.credit_amount), 0) <> 0
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