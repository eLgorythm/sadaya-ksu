-- =============================================================
-- ITERASI 8 — Modul Dana & SHU
-- RPC distribusi SHU: set status 'distributed' + catat otomatis
-- alokasi dana ke fund_transactions (sosial, pendidikan, cadangan).
-- =============================================================

create or replace function public.distribute_shu(
  p_distribution_id uuid
)
returns void
language plpgsql
set search_path = public
as $$
declare
  v_shu public.shu_distributions;
  v_social numeric;
  v_education numeric;
  v_reserve numeric;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  select * into v_shu from public.shu_distributions
    where id = p_distribution_id;
  if not found then
    raise exception 'SHU_NOT_FOUND';
  end if;
  if v_shu.status <> 'approved' then
    raise exception 'Hanya SHU berstatus disetujui yang bisa didistribusikan';
  end if;

  -- Alokasi dihitung dari net SHU (total dikurangi pajak)
  v_social := round(v_shu.net_shu * coalesce(v_shu.social_fund_pct, 0), 2);
  v_education := round(v_shu.net_shu * coalesce(v_shu.education_fund_pct, 0), 2);
  v_reserve := round(v_shu.net_shu * coalesce(v_shu.reserve_fund_pct, 0), 2);

  insert into public.fund_transactions (
    fund_type, transaction_type, transaction_date, amount,
    description, source_type, reference_id, created_by
  )
  select t.fund_type, 'income', coalesce(v_shu.distribution_date, current_date),
         t.amount,
         'Alokasi SHU tahun fiskal ' || v_shu.fiscal_year,
         'shu_allocation', v_shu.id, auth.uid()
  from (values
    ('social', v_social),
    ('education', v_education),
    ('reserve', v_reserve)
  ) as t(fund_type, amount)
  where t.amount > 0;

  update public.shu_distributions set
    status = 'distributed',
    distribution_date = coalesce(distribution_date, current_date)
  where id = p_distribution_id;
end;
$$;

revoke all on function public.distribute_shu(uuid) from anon, public;
grant execute on function public.distribute_shu(uuid) to authenticated;
