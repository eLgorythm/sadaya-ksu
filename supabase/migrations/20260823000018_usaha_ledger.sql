-- =============================================================
-- ITERASI 14B — Usaha Keripik → Ledger (Auto-Posting)
-- 1. Tambah COA: 5125 Biaya Bahan Baku
-- 2. Updated record_material_transaction: + jurnal beli/pakai
-- 3. RPC record_chip_sale: + jurnal pendapatan
-- 4. RPC void_chip_sale: hapus jurnal saat sale dihapus
-- =============================================================

-- 1. Tambah COA biaya bahan baku + persediaan
insert into public.chart_of_accounts (code, name, account_type) values
  ('5125', 'Biaya Bahan Baku Keripik', 'expense'),
  ('1130', 'Persediaan Bahan Baku', 'asset')
on conflict (code) do nothing;

-- 2. Updated record_material_transaction: + posting ledger
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
    -- Beli bahan: debit 1130 Persediaan / credit 1111 Kas
    insert into public.ledger_entries (
      entry_date, account_code, source_book, reference_id, reference_type,
      debit_amount, credit_amount, description, fiscal_year, created_by
    ) values
      (p_date, '1130',  'chip_business', v_txn_id, 'material_purchase',
       v_total, 0, 'Beli bahan: ' || v_name, public.v_year_of(p_date), auth.uid()),
      (p_date, '1111',  'chip_business', v_txn_id, 'material_purchase',
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

-- 3. RPC catat penjualan keripik + posting ledger
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

  -- Jurnal: debit 1111 Kas / credit 41xx Pendapatan
  insert into public.ledger_entries (
    entry_date, account_code, source_book, reference_id, reference_type,
    debit_amount, credit_amount, description, fiscal_year, created_by
  ) values
    (p_date, '1111',  'chip_business', v_sale_id, 'chip_sale',
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

revoke all on function public.record_chip_sale(text, date, numeric, text, numeric, numeric, text, text)
  from anon, public;
grant execute on function public.record_chip_sale(text, date, numeric, text, numeric, numeric, text, text)
  to authenticated;

-- 4. RPC void jurnal penjualan saat sale dihapus
create or replace function public.void_chip_sale(
  p_sale_id uuid
)
returns void
language plpgsql
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  delete from public.ledger_entries
   where reference_id = p_sale_id
     and reference_type = 'chip_sale';
end;
$$;

revoke all on function public.void_chip_sale(uuid)
  from anon, public;
grant execute on function public.void_chip_sale(uuid)
  to authenticated;
