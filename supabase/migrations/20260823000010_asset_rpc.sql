-- =============================================================
-- ITERASI 9 — Modul Aset
-- RPC: regenerasi buku penyusutan (garis lurus) untuk satu tahun
-- fiskal, proporsional bulanan pada tahun perolehan, dengan batas
-- akumulasi maksimum (nilai perolehan − residu).
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
  v_annual numeric;
  v_amount numeric;
  v_prev_accum numeric;
  v_max_total numeric;
  v_inserted integer := 0;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  if p_fiscal_year < 2000 or p_fiscal_year > extract(year from current_date)::int then
    raise exception 'Tahun penyusutan tidak valid';
  end if;

  -- Regenerasi penuh untuk tahun terpilih (idempoten)
  delete from public.asset_depreciations where fiscal_year = p_fiscal_year;

  for v_asset in
    select * from public.assets
    where status = 'active'
      and extract(year from acquisition_date)::int <= p_fiscal_year
  loop
    v_max_total := greatest(v_asset.acquisition_cost - v_asset.salvage_value, 0);
    if v_max_total <= 0 then continue; end if;

    select coalesce(accumulated_depreciation, 0) into v_prev_accum
      from public.asset_depreciations
     where asset_id = v_asset.id and fiscal_year < p_fiscal_year
     order by fiscal_year desc limit 1;
    v_prev_accum := coalesce(v_prev_accum, 0);

    -- Sudut habis disusutkan → lewati
    if v_prev_accum >= v_max_total - 0.005 then continue; end if;

    v_annual := v_max_total / v_asset.useful_life_years;
    if extract(year from v_asset.acquisition_date)::int = p_fiscal_year then
      -- Proporsional bulan perolehan (bulan itu dihitung penuh)
      v_amount := round(
        v_annual * (13 - extract(month from v_asset.acquisition_date)::int) / 12, 2);
    else
      v_amount := round(v_annual, 2);
    end if;

    -- Jangan melewati batas maksimum
    if v_prev_accum + v_amount > v_max_total then
      v_amount := round(v_max_total - v_prev_accum, 2);
    end if;
    if v_amount <= 0 then continue; end if;

    insert into public.asset_depreciations (
      asset_id, fiscal_year, depreciation_amount,
      accumulated_depreciation, book_value
    ) values (
      v_asset.id, p_fiscal_year, v_amount,
      v_prev_accum + v_amount,
      round(v_asset.acquisition_cost - (v_prev_accum + v_amount), 2)
    );
    v_inserted := v_inserted + 1;
  end loop;

  return v_inserted;
end;
$$;

revoke all on function public.recalculate_asset_depreciations(integer)
  from anon, public;
grant execute on function public.recalculate_asset_depreciations(integer)
  to authenticated;
