-- =============================================================
-- Sadaya — Migrasi 40: perbaikan get_cash_sources
--
-- Error "relation pos not exist": statement `select into v_result
-- ... from pos` di migrasi 39 mereferensi CTE `pos` yang hanya
-- hidup pada statement pertama. Perbaikan: gabung semua agregasi
-- + rincian entries dalam SATU statement WITH pos AS (...) dengan
-- subquery skalar, sehingga CTE `pos` tetap dalam scope.
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
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

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
      and k.source_book = 'installment'
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

  select into v_bank
    coalesce(sum(coalesce(le.debit_amount - le.credit_amount, 0)), 0)
    from public.ledger_entries le
    where le.account_code = '1111'
      and le.source_book = 'cash'
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
    'total', v_kesra + v_sosial + v_pendidikan + v_crk + v_pembangunan + v_swk + v_japinup + v_sms + v_bank
  );
end;
$$;

revoke all on function public.get_cash_sources(integer) from anon, public;
grant execute on function public.get_cash_sources(integer) to authenticated;