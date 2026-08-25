-- =============================================================
-- Sadaya — Migrasi 07: RPC Tambah Kategori Transaksi
-- create_transaction_category(p_name, p_type) :
--   buat kategori baru dari aplikasi + kode COA otomatis
--   income -> prefix 41 (revenue), expense -> prefix 51 (expense)
--   kode = max urut existing + 1 (mis. 4117, 5124)
-- =============================================================

create or replace function public.create_transaction_category(
  p_name text,
  p_type text
)
returns text
language plpgsql

-- SECURITY DEFINER: tabel chart_of_accounts memang sengaja read-only
-- bagi authenticated (policy coa_pengurus_read). Pembuatan kode COA
-- baru hanya boleh lewat fungsi tervalidasi ini, bukan insert langsung.
security definer
set search_path = public
as $$
declare
  v_prefix text;
  v_coa_type text;
  v_max_suffix integer;
  v_new_code text;
begin
  if auth.uid() is null then
    raise exception 'Tidak memiliki akses. Silakan login ulang';
  end if;

  if p_name is null or btrim(p_name) = '' then
    raise exception 'Nama kategori wajib diisi';
  end if;

  if p_type not in ('income', 'expense') then
    raise exception 'Jenis kategori tidak dikenal';
  end if;

  -- nama unik (case-insensitive)
  if exists (
    select 1 from public.transaction_categories
    where lower(name) = lower(btrim(p_name))
      and category_type = p_type
  ) then
    raise exception 'Kategori "%" sudah ada', btrim(p_name);
  end if;

  v_prefix   := case when p_type = 'income' then '41' else '51' end;
  v_coa_type := case when p_type = 'income' then 'revenue' else 'expense' end;

  select coalesce(max((substring(code from 3))::integer), 100)
    into v_max_suffix
  from public.chart_of_accounts
  where code like v_prefix || '%';

  v_new_code := v_prefix || ((v_max_suffix + 1)::text);

  insert into public.chart_of_accounts (code, name, account_type)
  values (v_new_code, btrim(p_name), v_coa_type);

  insert into public.transaction_categories (code, name, category_type, parent_category)
  values (v_new_code, btrim(p_name), p_type, null);

  return v_new_code;
end;
$$;

revoke all on function public.create_transaction_category(text, text) from public, anon;
grant execute on function public.create_transaction_category(text, text) to authenticated;
