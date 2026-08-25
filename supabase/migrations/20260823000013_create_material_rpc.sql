-- =============================================================
-- ITERASI 10C — Tambah Bahan = Pembelian Pertama
-- Mendaftarkan bahan baku baru sekaligus mencatat pembelian
-- pertamanya dalam satu transaksi atomik.
-- =============================================================

create or replace function public.create_raw_material(
  p_name text,
  p_unit text default 'kg',
  p_quantity numeric default 0,
  p_unit_price numeric default null,
  p_date date default current_date
)
returns uuid
language plpgsql
set search_path = public
as $$
declare
  v_id uuid;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  if coalesce(trim(p_name), '') = '' then
    raise exception 'Nama bahan wajib diisi';
  end if;
  if coalesce(trim(p_unit), '') = '' then
    raise exception 'Satuan wajib diisi';
  end if;
  if p_quantity < 0 then
    raise exception 'Jumlah tidak boleh negatif';
  end if;

  insert into public.chip_raw_materials (name, unit, current_stock)
  values (trim(p_name), trim(p_unit), p_quantity)
  returning id into v_id;

  if p_quantity > 0 then
    insert into public.chip_material_transactions (
      material_id, transaction_type, quantity,
      unit_price, total_price, transaction_date, created_by
    ) values (
      v_id, 'purchase', p_quantity,
      p_unit_price,
      case when p_unit_price is not null
           then round(p_quantity * p_unit_price, 2) end,
      coalesce(p_date, current_date),
      auth.uid()
    );
  end if;

  return v_id;
end;
$$;

revoke all on function public.create_raw_material(text, text, numeric, numeric, date)
  from anon, public;
grant execute on function public.create_raw_material(text, text, numeric, numeric, date)
  to authenticated;
