-- =============================================================
-- Sadaya — Migrasi 37: Tab Kas — pemasukan Kas (1111) per sumber
--
-- Tab Kas menampilkan masuknya uang ke Kas (akun 1111) yang berasal
-- dari tiga sumber utama, diambang dari buku besar (ledger_entries):
--   1. Angsuran Pinjaman   -> source_book = 'installment'
--   2. Simpanan Manasuka   -> source_book = 'savings'
--   3. Cair / Tarik Bank   -> source_book = 'cash' yang berpasangan
--                            dengan akun 1112 (Bank) pada jurnal sama
--                            (reference_id + reference_type yang sama).
--
-- Mengembalikan rincian per sumber berikut totalnya.
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
  v_total_angsuran numeric;
  v_total_simpanan numeric;
  v_total_bank numeric;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  with kas as (
    select
      le.entry_date,
      le.account_code,
      le.source_book,
      le.reference_id::text as reference_id,
      le.reference_type,
      le.debit_amount,
      le.credit_amount,
      le.description,
      -- Cair dari bank bila entri berpasangan (jurnal sama) melibatkan akun bank
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
        when le.source_book = 'installment' then 'angsuran'
        when le.source_book = 'savings' then 'simpanan'
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
    coalesce((select sum(debit_amount - credit_amount) from kas where src = 'angsuran'), 0),
    coalesce((select sum(debit_amount - credit_amount) from kas where src = 'simpanan'), 0),
    coalesce((select sum(debit_amount - credit_amount) from kas where src = 'cair_bank'), 0);

  return jsonb_build_object(
    'entries', v_result,
    'total_angsuran', v_total_angsuran,
    'total_simpanan', v_total_simpanan,
    'total_cair_bank', v_total_bank,
    'total', v_total_angsuran + v_total_simpanan + v_total_bank
  );
end;
$$;

revoke all on function public.get_cash_sources(integer) from anon, public;
grant execute on function public.get_cash_sources(integer) to authenticated;