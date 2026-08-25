-- =============================================================
-- Sadaya — Migrasi 06: RPC Buku Kas Harian & Bank
-- create_cash_book_transaction :
--   catat transaksi kas/bank non-anggota + jurnal 2 baris atomik
--
-- Aturan:
--   Buku KAS   -> akun 1111, tipe transaksi income/expense
--   Buku BANK  -> akun 1112, tipe transaksi credit/debit
--                 (kredit = uang masuk ke rekening)
--   Arah 'in'  : Debit akun buku / Kredit akun lawan
--   Arah 'out' : Debit akun lawan / Kredit akun buku
--   Akun lawan harus ada di chart_of_accounts dan aktif,
--   tidak boleh sama dengan akun buku sendiri.
--   Transfer Kas<->Bank dipakai lewat akun lawan 1112 / 1111.
-- =============================================================

create or replace function public.create_cash_book_transaction(
  p_book text,
  p_direction text,
  p_counter_account text,
  p_amount numeric,
  p_description text,
  p_date date default current_date
)
returns uuid
language plpgsql
set search_path = public
as $$
declare
  v_book_account text;
  v_source_book text;
  v_tx_type text;
  v_tx_id uuid;
  v_category_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Tidak memiliki akses. Silakan login ulang';
  end if;

  if p_book not in ('cash', 'bank') then
    raise exception 'Buku tidak dikenal';
  end if;

  if p_direction not in ('in', 'out') then
    raise exception 'Arah transaksi tidak dikenal';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'Nominal harus lebih dari 0';
  end if;

  if p_description is null or btrim(p_description) = '' then
    raise exception 'Keterangan wajib diisi';
  end if;

  v_book_account := case when p_book = 'cash' then '1111' else '1112' end;
  v_source_book  := p_book;

  if p_counter_account is null then
    raise exception 'Kategori/akun lawan wajib dipilih';
  end if;

  if p_counter_account = v_book_account then
    raise exception 'Akun lawan tidak boleh sama dengan buku sendiri';
  end if;

  if not exists (
    select 1 from public.chart_of_accounts
    where code = p_counter_account and is_active
  ) then
    raise exception 'Akun lawan tidak ditemukan atau tidak aktif';
  end if;

  -- ---- insert baris buku -------------------------------------
  if p_book = 'cash' then
    select id into v_category_id
    from public.transaction_categories
    where code = p_counter_account limit 1;

    v_tx_type := case when p_direction = 'in' then 'income' else 'expense' end;

    insert into public.cash_transactions (
      transaction_date, transaction_type, category_id,
      amount, description, reference_type, created_by
    ) values (
      p_date, v_tx_type, v_category_id,
      p_amount, btrim(p_description), 'manual', auth.uid()
    ) returning id into v_tx_id;
  else
    v_tx_type := case when p_direction = 'in' then 'credit' else 'debit' end;

    insert into public.bank_transactions (
      transaction_date, transaction_type,
      amount, description, created_by
    ) values (
      p_date, v_tx_type, p_amount, btrim(p_description), auth.uid()
    ) returning id into v_tx_id;
  end if;

  -- ---- jurnal 2 baris (auto-posting) -------------------------
  insert into public.ledger_entries (
    entry_date, account_code, source_book, reference_id, reference_type,
    debit_amount, credit_amount, description, fiscal_year, created_by
  )
  -- sisi akun buku (kas/bank selalu ikut arah uang)
  values (
    p_date, v_book_account, v_source_book, v_tx_id, 'manual',
    case when p_direction = 'in' then p_amount else 0 end,
    case when p_direction = 'out' then p_amount else 0 end,
    btrim(p_description), public.v_year_of(p_date), auth.uid()
  ),
  -- sisi akun lawan (berlawanan)
  (
    p_date, p_counter_account, v_source_book, v_tx_id, 'manual',
    case when p_direction = 'out' then p_amount else 0 end,
    case when p_direction = 'in' then p_amount else 0 end,
    btrim(p_description), public.v_year_of(p_date), auth.uid()
  );

  return v_tx_id;
end;
$$;

revoke all on function public.create_cash_book_transaction(text, text, text, numeric, text, date) from public, anon;
grant execute on function public.create_cash_book_transaction(text, text, text, numeric, text, date) to authenticated;
