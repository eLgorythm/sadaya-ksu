-- =============================================================
-- Sadaya — Migrasi 38: tab Kas — pemasukan dari 7 pos dana + SMS + cair bank
--
-- Koreksi definisi sumber Kas (akun 1111):
--   1. 7 Pos Dana    -> source_book = 'installment' (distribusi jasa angsuran)
--   2. SMS (Manasuka)-> source_book = 'savings'
--   3. Cair dari Bank-> source_book = 'cash' berpasangan akun 1112
--
-- Saldo pembuka (opening) tidak termasuk total Kas.
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
  v_total_dana numeric;
  v_total_sms numeric;
  v_total_bank numeric;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  with kas as (
    select
      le.entry_date,
      le.source_book,
      le.reference_id::text as reference_id,
      le.reference_type,
      le.debit_amount,
      le.credit_amount,
      le.description,
      case
        when le.source_book = 'cash'
         and exists (
           select 1 from public.ledger_entries p
           where p.reference_id = le.reference_id
             and p.reference_type = le.reference_type
             and p.account_code = '1112'
             and p.fiscal_year = le.fiscal_year
             and p.is_void = false
         ) then 'cair_bank'
        when le.source_book = 'installment' then 'dana'
        when le.source_book = 'savings' then 'sms'
        else 'kas_lain'
      end as src
    from public.ledger_entries le
    where le.account_code = '1111'
      and le.fiscal_year = p_year
      and le.is_void = false
  )
  select into v_result
    coalesce(
      (select jsonb_agg(jsonb_build_object(
          'source', src,
          'date', to_char(entry_date, 'YYYY-MM-DD'),
          'amount', coalesce(debit_amount - credit_amount, 0),
          'description', description
        ) order by entry_date) from kas),
      '[]'::jsonb
    ),
    coalesce((select sum(debit_amount - credit_amount) from kas where src = 'dana'), 0),
    coalesce((select sum(debit_amount - credit_amount) from kas where src = 'sms'), 0),
    coalesce((select sum(debit_amount - credit_amount) from kas where src = 'cair_bank'), 0);

  return jsonb_build_object(
    'entries', v_result,
    'total_dana', v_total_dana,
    'total_sms', v_total_sms,
    'total_cair_bank', v_total_bank,
    'total', v_total_dana + v_total_sms + v_total_bank
  );
end;
$$;

revoke all on function public.get_cash_sources(integer) from anon, public;
grant execute on function public.get_cash_sources(integer) to authenticated;