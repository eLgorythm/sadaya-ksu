-- =============================================================
-- Sadaya — Migrasi 42: Buku Dana — kas masuk/keluar manual 7 pos
--
--  1) Perluas fund_transactions.fund_type agar 7 pos dana bisa
--     menjadi sumber kas masuk/keluar manual:
--        welfare, social, education, crk, development,
--        japinup (4111), swk (2113).
--     Inventaris (aset) TIDAK termasuk → tidak bisa jadi sumber.
--
--  2) RPC post_fund_entry: catat transaksi dana manual SEKALIGUS
--     posting jurnal 2 baris ke buku besar (atomik):
--        masuk  : Debit 1111 Kas / Kredit akun pos
--        keluar : Debit akun pos / Kredit 1111 Kas
--     Sehingga total kas & saldo pos sumber ikut berubah.
--
--  3) RPC get_cair_bank_total: total transfer bank -> kas
--     (debit 1111 yang berpasangan dengan kredit 1112).
--     Tanpa p_year = kumulatif seluruh tahun berjalan.
-- =============================================================

-- ---------- 1) Perluas CHECK fund_type ------------------------
alter table public.fund_transactions
  drop constraint if exists fund_transactions_fund_type_check;
alter table public.fund_transactions
  add constraint fund_transactions_fund_type_check
  check (fund_type in (
    'social', 'education', 'welfare', 'crk', 'development',
    'reserve', 'japinup', 'swk'
  ));

-- ---------- 2) RPC catat kas masuk/keluar dana ---------------
create or replace function public.post_fund_entry(
  p_fund_type text,
  p_transaction_type text,
  p_amount numeric,
  p_description text,
  p_date date default current_date
)
returns void
language plpgsql
set search_path = public
as $$
declare
  v_account text;
  v_tx_id uuid;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  v_account := case p_fund_type
    when 'welfare'    then '2119'
    when 'social'     then '2114'
    when 'education'  then '2115'
    when 'crk'        then '3115'
    when 'development' then '3114'
    when 'japinup'    then '4111'
    when 'swk'        then '2113'
    else null
  end;

  if v_account is null then
    raise exception 'Sumber dana tidak dikenal atau tidak diizinkan';
  end if;

  if p_transaction_type not in ('income', 'expense') then
    raise exception 'Arah transaksi tidak dikenal';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'Nominal harus lebih dari 0';
  end if;

  if p_description is null or btrim(p_description) = '' then
    raise exception 'Keterangan wajib diisi';
  end if;

  -- ---- baris buku dana ----
  insert into public.fund_transactions (
    fund_type, transaction_type, transaction_date, amount,
    description, source_type, created_by
  ) values (
    p_fund_type, p_transaction_type, p_date, p_amount,
    btrim(p_description), 'manual', auth.uid()
  ) returning id into v_tx_id;

  -- ---- jurnal 2 baris (auto-posting) ----
  if p_transaction_type = 'income' then
    insert into public.ledger_entries (
      entry_date, account_code, source_book, reference_id, reference_type,
      debit_amount, credit_amount, description, fiscal_year, created_by
    ) values
      (p_date, '1111', 'fund', v_tx_id, 'fund_entry',
       p_amount, 0, btrim(p_description), public.v_year_of(p_date), auth.uid()),
      (p_date, v_account, 'fund', v_tx_id, 'fund_entry',
       0, p_amount, btrim(p_description), public.v_year_of(p_date), auth.uid());
  else
    insert into public.ledger_entries (
      entry_date, account_code, source_book, reference_id, reference_type,
      debit_amount, credit_amount, description, fiscal_year, created_by
    ) values
      (p_date, v_account, 'fund', v_tx_id, 'fund_entry',
       p_amount, 0, btrim(p_description), public.v_year_of(p_date), auth.uid()),
      (p_date, '1111', 'fund', v_tx_id, 'fund_entry',
       0, p_amount, btrim(p_description), public.v_year_of(p_date), auth.uid());
  end if;
end;
$$;

revoke all on function public.post_fund_entry(text, text, numeric, text, date)
  from public, anon;
grant execute on function public.post_fund_entry(text, text, numeric, text, date)
  to authenticated;

-- ---------- 3) RPC total cair dari bank (bank -> kas) ----------
create or replace function public.get_cair_bank_total(
  p_year integer default null
)
returns numeric
language plpgsql
set search_path = public
as $$
declare
  v_total numeric;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  select coalesce(sum(le.debit_amount), 0)
  into v_total
  from public.ledger_entries le
  where le.account_code = '1111'
    and le.is_void = false
    and (p_year is null or le.fiscal_year = p_year)
    and exists (
      select 1 from public.ledger_entries p
      where p.reference_id = le.reference_id
        and p.reference_type = le.reference_type
        and p.account_code = '1112'
        and p.is_void = false
    );

  return v_total;
end;
$$;

revoke all on function public.get_cair_bank_total(integer)
  from public, anon;
grant execute on function public.get_cair_bank_total(integer)
  to authenticated;