-- =============================================================
-- ITERASI 10 — Unit Usaha Keripik
-- RPC atomik: catat transaksi bahan baku (beli/pakai) sekaligus
-- menyesuaikan stok. Pakai divalidasi tidak boleh membuat stok minus.
-- =============================================================

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

  -- Kunci baris bahan agar stok konsisten pada input bersamaan
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

  insert into public.chip_material_transactions (
    material_id, transaction_type, quantity,
    unit_price, total_price, transaction_date, notes, created_by
  ) values (
    p_material_id, p_type, p_quantity,
    p_unit_price,
    case when p_unit_price is not null
         then round(p_quantity * p_unit_price, 2) end,
    p_date,
    p_notes,
    auth.uid()
  );

  update public.chip_raw_materials
     set current_stock = case
           when p_type = 'purchase' then current_stock + p_quantity
           else current_stock - p_quantity
         end
   where id = p_material_id;

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
