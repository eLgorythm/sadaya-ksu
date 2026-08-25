-- =============================================================
-- ITERASI 9B — Edit/Delete Aset
-- Versi baru recalculate_asset_depreciations: meregenerasi SELURUH
-- baris penyusutan tiap aset aktif dari tahun perolehan sampai tahun
-- target, sehingga angka tetap konsisten setelah data aset diedit.
-- Baris tahun > tahun target tidak disentuh.
-- Jalankan file ini SETEPAI/saja setelah 00010 (create or replace).
-- =============================================================

create or replace function public.recalculate_asset_depreciations(
  p_fiscal_year integer
)
returns integer
language plpgsql
set search_path = public
as $$
declare
  v_asset record;
  v_max_total numeric;
  v_annual numeric;
  v_amount numeric;
  v_accum numeric;
  v_start integer;
  y integer;
  v_inserted integer := 0;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  if p_fiscal_year < 2000 or p_fiscal_year > extract(year from current_date)::int then
    raise exception 'Tahun penyusutan tidak valid';
  end if;

  for v_asset in
    select * from public.assets
    where status = 'active'
  loop
    v_max_total := greatest(v_asset.acquisition_cost - v_asset.salvage_value, 0);
    if v_max_total <= 0 then continue; end if;

    v_start := extract(year from v_asset.acquisition_date)::int;
    if v_start > p_fiscal_year then continue; end if;

    -- Regenerasi penuh riwayat aset ini hingga tahun target
    delete from public.asset_depreciations
     where asset_id = v_asset.id and fiscal_year <= p_fiscal_year;

    v_accum := 0;
    v_annual := v_max_total / v_asset.useful_life_years;
    for y in v_start..p_fiscal_year loop
      exit when v_accum >= v_max_total - 0.005; -- sudah lunas disusutkan

      if y = v_start then
        -- Proporsional bulan perolehan (bulan itu dihitung penuh)
        v_amount := round(
          v_annual * (13 - extract(month from v_asset.acquisition_date)::int) / 12, 2);
      else
        v_amount := round(v_annual, 2);
      end if;

      if v_accum + v_amount > v_max_total then
        v_amount := round(v_max_total - v_accum, 2);
      end if;
      exit when v_amount <= 0;

      insert into public.asset_depreciations (
        asset_id, fiscal_year, depreciation_amount,
        accumulated_depreciation, book_value
      ) values (
        v_asset.id, y, v_amount,
        v_accum + v_amount,
        round(v_asset.acquisition_cost - (v_accum + v_amount), 2)
      );
      v_inserted := v_inserted + 1;
      v_accum := v_accum + v_amount;
    end loop;
  end loop;

  return v_inserted;
end;
$$;

revoke all on function public.recalculate_asset_depreciations(integer)
  from anon, public;
grant execute on function public.recalculate_asset_depreciations(integer)
  to authenticated;
