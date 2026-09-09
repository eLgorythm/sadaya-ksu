-- =============================================================
-- Sadaya — Migrasi 45: Unit Krisado berdiri sendiri
--
-- Unit Krisado punya KAS SENDIRI (1114), tidak menyentuh kas
-- koperasi (1111). Alur unit:
--   - Penjualan        : Debit 1114 Kas Unit Krisado / Kredit 4114-4116
--   - Beli bahan baku  : Debit 1130 Persediaan / Kredit 1114
--   - Pakai bahan      : Debit 5125 Biaya Bahan / Kredit 1130
--   - Ambil dari bank  : Debit 1114 / Kredit 1112 Bank  (dari Buku Bank,
--                        tercatat sebagai penarikan "debit" di Buku Bank)
--
-- Akun lawan (pendapatan/biaya) tetap akun koperasi agar neraca dan
-- laba koperasi benar. Saldo 1114 tampil di neraca sebagai aset.
-- Saldo kas koperasi (get_cash_ledger_summary / get_cash_sources)
-- tetap tidak menyertakan 1114 -> unit tidak campur kas koperasi.
-- =============================================================

-- 1. COA baru: Kas Unit Krisado
insert into public.chart_of_accounts (code, name, account_type) values
  ('1114', 'Kas Unit Krisado', 'asset')
on conflict (code) do nothing;

-- 2. Alihkan jurnal unit yang tercatat ke 1111 ke akun 1114
update public.ledger_entries
   set account_code = '1114'
 where source_book = 'chip_business'
   and account_code = '1111';

-- 3. record_chip_sale -> debit Kas Unit (1114), bukan Kas (1111)
create or replace function public.record_chip_sale(
  p_product_type text,
  p_date date,
  p_quantity numeric,
  p_unit text,
  p_unit_price numeric,
  p_total_price numeric,
  p_buyer text default null,
  p_notes text default null
)
returns uuid
language plpgsql
set search_path = public
as $$
declare
  v_sale_id uuid;
  v_account_code text;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  insert into public.chip_sales (
    product_type, sale_date, quantity, unit, unit_price, total_price,
    buyer, notes, created_by
  ) values (
    p_product_type, p_date, p_quantity, p_unit, p_unit_price, p_total_price,
    p_buyer, p_notes, auth.uid()
  ) returning id into v_sale_id;

  -- Map product type ke COA pendapatan
  v_account_code := case p_product_type
    when 'keripik_kentang' then '4115'
    when 'keripik_salak'   then '4116'
    when 'kopi'            then '4114'
    else '4115'
  end;

  -- Jurnal: debit 1114 Kas Unit Krisado / credit 41xx Pendapatan
  insert into public.ledger_entries (
    entry_date, account_code, source_book, reference_id, reference_type,
    debit_amount, credit_amount, description, fiscal_year, created_by
  ) values
    (p_date, '1114',  'chip_business', v_sale_id, 'chip_sale',
     p_total_price, 0, 'Penjualan ' || replace(p_product_type, '_', ' ') ||
       ' (' || p_quantity::text || ' ' || p_unit || ')',
       public.v_year_of(p_date), auth.uid()),
    (p_date, v_account_code,  'chip_business', v_sale_id, 'chip_sale',
     0, p_total_price, 'Penjualan ' || replace(p_product_type, '_', ' ') ||
       ' (' || p_quantity::text || ' ' || p_unit || ')',
       public.v_year_of(p_date), auth.uid());

  return v_sale_id;
end;
$$;

-- 4. record_material_transaction: beli bahan kredit Kas Unit (1114)
create or replace function public.record_material_transaction(
  p_material_id uuid,
  p_type text,
  p_quantity numeric,
  p_unit_price numeric default null,
  p_date date default current_date,
  p_notes text default null
)
returns numeric
language plpgsql
set search_path = public
as $$
declare
  v_stock numeric;
  v_name text;
  v_total numeric;
  v_txn_id uuid;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  if p_type not in ('purchase', 'usage') then
    raise exception 'Jenis transaksi harus purchase atau usage';
  end if;
  if p_quantity is null or p_quantity <= 0 then
    raise exception 'Jumlah harus lebih dari 0';
  end if;

  select current_stock, name into v_stock, v_name
    from public.chip_raw_materials
   where id = p_material_id
   for update;
  if not found then
    raise exception 'Bahan baku tidak ditemukan';
  end if;

  if p_type = 'usage' and v_stock < p_quantity then
    raise exception 'Stok % tidak cukup (tersedia %)', v_name, v_stock;
  end if;

  v_total := case when p_unit_price is not null
                  then round(p_quantity * p_unit_price, 2) end;

  insert into public.chip_material_transactions (
    material_id, transaction_type, quantity,
    unit_price, total_price, transaction_date, notes, created_by
  ) values (
    p_material_id, p_type, p_quantity,
    p_unit_price, v_total, p_date, p_notes, auth.uid()
  ) returning id into v_txn_id;

  update public.chip_raw_materials
     set current_stock = case
           when p_type = 'purchase' then current_stock + p_quantity
           else current_stock - p_quantity
         end
   where id = p_material_id;

  -- Posting ke ledger
  if p_type = 'purchase' and v_total is not null and v_total > 0 then
    -- Beli bahan: debit 1130 Persediaan / credit 1114 Kas Unit Krisado
    insert into public.ledger_entries (
      entry_date, account_code, source_book, reference_id, reference_type,
      debit_amount, credit_amount, description, fiscal_year, created_by
    ) values
      (p_date, '1130',  'chip_business', v_txn_id, 'material_purchase',
       v_total, 0, 'Beli bahan: ' || v_name, public.v_year_of(p_date), auth.uid()),
      (p_date, '1114',  'chip_business', v_txn_id, 'material_purchase',
       0, v_total, 'Beli bahan: ' || v_name, public.v_year_of(p_date), auth.uid());
  elsif p_type = 'usage' and v_total is not null and v_total > 0 then
    -- Pakai bahan: debit 5125 Biaya Bahan / credit 1130 Persediaan
    insert into public.ledger_entries (
      entry_date, account_code, source_book, reference_id, reference_type,
      debit_amount, credit_amount, description, fiscal_year, created_by
    ) values
      (p_date, '5125',  'chip_business', v_txn_id, 'material_usage',
       v_total, 0, 'Pakai bahan: ' || v_name, public.v_year_of(p_date), auth.uid()),
      (p_date, '1130',  'chip_business', v_txn_id, 'material_usage',
       0, v_total, 'Pakai bahan: ' || v_name, public.v_year_of(p_date), auth.uid());
  end if;

  return case
    when p_type = 'purchase' then v_stock + p_quantity
    else v_stock - p_quantity
  end;
end;
$$;

revoke all on function public.record_material_transaction(
  uuid, text, numeric, numeric, date, text)
  from anon, public;
grant execute on function public.record_material_transaction(
  uuid, text, numeric, numeric, date, text)
  to authenticated;

revoke all on function public.record_chip_sale(text, date, numeric, text, numeric, numeric, text, text)
  from anon, public;
grant execute on function public.record_chip_sale(text, date, numeric, text, numeric, numeric, text, text)
  to authenticated;

-- =============================================================
-- 5. RPC saldo & ambil dari bank
-- =============================================================

-- Saldo kas Unit Krisado (akun 1114, source_book chip_business).
-- Mengembalikan jsonb { balance }.
create or replace function public.get_chip_business_summary()
returns jsonb
language plpgsql
set search_path = public
as $$
declare
  v_balance numeric;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  select coalesce(sum(le.debit_amount - le.credit_amount), 0)
    into v_balance
    from public.ledger_entries le
   where le.account_code = '1114'
     and le.source_book = 'chip_business'
     and le.is_void = false;

  return jsonb_build_object('balance', v_balance);
end;
$$;

revoke all on function public.get_chip_business_summary() from anon, public;
grant execute on function public.get_chip_business_summary() to authenticated;

-- Ambil uang dari rekening bank (Buku Bank) ke kas Unit Krisado.
-- Bank_transactions type 'debit' = penarikan rekening, tampil di Buku Bank.
-- Jurnal: Debit 1114 Kas Unit Krisado / Kredit 1112 Bank.
create or replace function public.chip_ambil_dari_bank(
  p_amount numeric,
  p_description text,
  p_date date default current_date
)
returns uuid
language plpgsql
set search_path = public
as $$
declare
  v_bank_balance numeric;
  v_tx_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Tidak memiliki akses. Silakan login ulang';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'Nominal harus lebih dari 0';
  end if;

  if p_description is null or btrim(p_description) = '' then
    raise exception 'Keterangan wajib diisi';
  end if;

  -- Saldo bank = seluruh pemasukan Bank (debit 1112) dikurangi penarikan
  select coalesce(sum(le.debit_amount - le.credit_amount), 0)
    into v_bank_balance
    from public.ledger_entries le
   where le.account_code = '1112'
     and le.is_void = false;

  if v_bank_balance < p_amount then
    raise exception 'Saldo bank tidak mencukupi (sisa %.2f)', v_bank_balance;
  end if;

  -- Baris Buku Bank: penarikan (debit rekening / uang keluar)
  insert into public.bank_transactions (
    transaction_date, transaction_type, amount, description, created_by
  ) values (
    p_date, 'debit', p_amount, btrim(p_description), auth.uid()
  ) returning id into v_tx_id;

  -- Jurnal: Debit 1114 KAS UNIT / Kredit 1112 BANK
  insert into public.ledger_entries (
    entry_date, account_code, source_book, reference_id, reference_type,
    debit_amount, credit_amount, description, fiscal_year, created_by
  ) values
    (p_date, '1114', 'chip_business', v_tx_id, 'manual',
     p_amount, 0, btrim(p_description), public.v_year_of(p_date), auth.uid()),
    (p_date, '1112', 'chip_business', v_tx_id, 'manual',
     0, p_amount, btrim(p_description), public.v_year_of(p_date), auth.uid());

  return v_tx_id;
end;
$$;

revoke all on function public.chip_ambil_dari_bank(numeric, text, date) from anon, public;
grant execute on function public.chip_ambil_dari_bank(numeric, text, date) to authenticated;