-- =============================================================
-- ITERASI 8D — Batalkan distribusi SHU (untuk hapus/redistribusi)
-- Menghapus alokasi fund_transactions buatan distribute_shu lalu
-- mengembalikan status SHU ke 'draft' agar bisa direvisi ulang.
-- =============================================================

create or replace function public.cancel_shu_distribution(
  p_distribution_id uuid
)
returns void
language plpgsql
set search_path = public
as $$
declare
  v_status text;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  select status into v_status from public.shu_distributions
    where id = p_distribution_id;
  if not found then
    raise exception 'SHU_NOT_FOUND';
  end if;
  if v_status <> 'distributed' then
    raise exception 'Hanya SHU terdistribusi yang bisa dibatalkan';
  end if;

  delete from public.fund_transactions
   where reference_id = p_distribution_id
     and source_type = 'shu_allocation';

  update public.shu_distributions set
    status = 'draft',
    distribution_date = null
  where id = p_distribution_id;
end;
$$;

revoke all on function public.cancel_shu_distribution(uuid) from anon, public;
grant execute on function public.cancel_shu_distribution(uuid) to authenticated;
