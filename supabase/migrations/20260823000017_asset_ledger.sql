-- =============================================================
-- ITERASI 14 — Aset → Ledger (Auto-Posting)
-- 1. Tambah COA: 1120 Inventaris, 5124 Penyusutan
-- 2. RPC post_asset_acquisition: beli aset → jurnal kas/inventaris
-- 3. Updated recalculate_asset_depreciations: + jurnal penyusutan
-- 4. RPC void_asset_ledger: hapus jurnal aset saat aset dihapus
-- =============================================================

-- 1. Tambah COA baru
insert into public.chart_of_accounts (code, name, account_type) values
  ('1120', 'Inventaris dan Perlengkapan', 'asset'),
  ('5124', 'Penyusutan Inventaris', 'expense')
on conflict (code) do nothing;

-- 2. RPC posting pembelian aset ke buku besar
create or replace function public.post_asset_acquisition(
  p_asset_id uuid,
  p_amount numeric,
  p_date date,
  p_description text
)
returns void
language plpgsql
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  -- Debit 1120 Inventaris / Credit 1111 Kas
  insert into public.ledger_entries (
    entry_date, account_code, source_book, reference_id, reference_type,
    debit_amount, credit_amount, description, fiscal_year, created_by
  ) values
    (p_date, '1120', 'asset', p_asset_id, 'asset_acquisition',
     p_amount, 0, p_description, public.v_year_of(p_date), auth.uid()),
    (p_date, '1111', 'asset', p_asset_id, 'asset_acquisition',
     0, p_amount, p_description, public.v_year_of(p_date), auth.uid());
end;
$$;

revoke all on function public.post_asset_acquisition(uuid, numeric, date, text)
  from anon, public;
grant execute on function public.post_asset_acquisition(uuid, numeric, date, text)
  to authenticated;

-- 3. Updated recalculate_asset_depreciations: + posting penyusutan ke ledger
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
  v_prev_total numeric;
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

    -- Simpan jumlah penyusutan lama untuk tahun target (untuk selisih ledger)
    select coalesce(sum(depreciation_amount), 0) into v_prev_total
      from public.asset_depreciations
     where asset_id = v_asset.id and fiscal_year = p_fiscal_year;

    -- Regenerasi penuh riwayat aset ini hingga tahun target
    delete from public.asset_depreciations
     where asset_id = v_asset.id and fiscal_year <= p_fiscal_year;

    v_accum := 0;
    v_annual := v_max_total / v_asset.useful_life_years;
    for y in v_start..p_fiscal_year loop
      exit when v_accum >= v_max_total - 0.005;

      if y = v_start then
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

    -- Posting selisih penyusutan tahun target ke ledger
    -- (hanya jika ada perubahan)
    declare
      v_new_total numeric;
      v_diff numeric;
    begin
      select coalesce(sum(depreciation_amount), 0) into v_new_total
        from public.asset_depreciations
       where asset_id = v_asset.id and fiscal_year = p_fiscal_year;

      v_diff := v_new_total - v_prev_total;

      if v_diff > 0 then
        -- Ada penyusutan tambahan → post debit expense / credit inventaris
        insert into public.ledger_entries (
          entry_date, account_code, source_book, reference_id, reference_type,
          debit_amount, credit_amount, description, fiscal_year, created_by
        ) values
          (make_date(p_fiscal_year, 12, 31), '5124', 'asset', v_asset.id, 'asset_depreciation',
           v_diff, 0, 'Penyusutan ' || v_asset.name || ' ' || p_fiscal_year::text,
           p_fiscal_year, auth.uid()),
          (make_date(p_fiscal_year, 12, 31), '1120', 'asset', v_asset.id, 'asset_depreciation',
           0, v_diff, 'Penyusutan ' || v_asset.name || ' ' || p_fiscal_year::text,
           p_fiscal_year, auth.uid());
      elsif v_diff < 0 then
        -- Ada pengurangan penyusutan → reverse (hapus jurnal lama, post yang baru)
        delete from public.ledger_entries
         where reference_id = v_asset.id
           and reference_type = 'asset_depreciation'
           and fiscal_year = p_fiscal_year;

        if v_new_total > 0 then
          insert into public.ledger_entries (
            entry_date, account_code, source_book, reference_id, reference_type,
            debit_amount, credit_amount, description, fiscal_year, created_by
          ) values
            (make_date(p_fiscal_year, 12, 31), '5124', 'asset', v_asset.id, 'asset_depreciation',
             v_new_total, 0, 'Penyusutan ' || v_asset.name || ' ' || p_fiscal_year::text,
             p_fiscal_year, auth.uid()),
            (make_date(p_fiscal_year, 12, 31), '1120', 'asset', v_asset.id, 'asset_depreciation',
             0, v_new_total, 'Penyusutan ' || v_asset.name || ' ' || p_fiscal_year::text,
             p_fiscal_year, auth.uid());
        end if;
      end if;
    end;
  end loop;

  return v_inserted;
end;
$$;

revoke all on function public.recalculate_asset_depreciations(integer)
  from anon, public;
grant execute on function public.recalculate_asset_depreciations(integer)
  to authenticated;

-- 4. RPC void jurnal aset saat aset dihapus
create or replace function public.void_asset_ledger(
  p_asset_id uuid
)
returns void
language plpgsql
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  -- Hapus jurnal akuisisi
  delete from public.ledger_entries
   where reference_id = p_asset_id
     and reference_type = 'asset_acquisition';

  -- Hapus jurnal penyusutan
  delete from public.ledger_entries
   where reference_id = p_asset_id
     and reference_type = 'asset_depreciation';
end;
$$;

revoke all on function public.void_asset_ledger(uuid)
  from anon, public;
grant execute on function public.void_asset_ledger(uuid)
  to authenticated;
