-- =============================================================
-- ITERASI 14C — Modul Pajak + Ledger
-- 1. Tabel taxes
-- 2. COA: 5126 Pajak Penghasilan, 5127 Pajak Pertambahan Nilai
-- 3. RPC: insert_tax, update_tax, delete_tax (dengan ledger posting)
-- =============================================================

-- 1. Tabel pajak
create table if not exists public.taxes (
  id uuid primary key default gen_random_uuid(),
  tax_type text not null check (tax_type in ('PPh 21', 'PPh 23', 'PPN', 'Pajak Lainnya')),
  description text,
  amount numeric(15,2) not null check (amount > 0),
  tax_date date not null,
  status text not null default 'unpaid' check (status in ('paid', 'unpaid')),
  reference_number text,
  notes text,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now()
);

create index if not exists idx_taxes_date on public.taxes(tax_date);

alter table public.taxes enable row level security;

drop policy if exists "Authenticated full access" on public.taxes;
create policy "Authenticated full access" on public.taxes
  for all using (auth.uid() is not null);

-- 2. Tambah COA pajak (+ akun Hutang Pajak untuk baris "Buku Pajak (Hutang)")
insert into public.chart_of_accounts (code, name, account_type) values
  ('5126', 'Pajak Penghasilan', 'expense'),
  ('5127', 'Pajak Pertambahan Nilai', 'expense'),
  ('2122', 'Hutang Pajak', 'liability')
on conflict (code) do nothing;

-- 3. RPC insert pajak + posting ledger (akrual jika unpaid, bayar jika paid)
create or replace function public.insert_tax(
  p_tax_type text,
  p_description text,
  p_amount numeric,
  p_date date,
  p_status text default 'unpaid',
  p_reference_number text default null,
  p_notes text default null
)
returns uuid
language plpgsql
set search_path = public
as $$
declare
  v_tax_id uuid;
  v_account text;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  insert into public.taxes (
    tax_type, description, amount, tax_date, status,
    reference_number, notes, created_by
  ) values (
    p_tax_type, p_description, p_amount, p_date, p_status,
    p_reference_number, p_notes, auth.uid()
  ) returning id into v_tax_id;

  v_account := case
    when p_tax_type in ('PPh 21', 'PPh 23') then '5126'
    when p_tax_type = 'PPN' then '5127'
    else '5126'
  end;

  if p_status = 'paid' then
    insert into public.ledger_entries (
      entry_date, account_code, source_book, reference_id, reference_type,
      debit_amount, credit_amount, description, fiscal_year, created_by
    ) values
      (p_date, v_account,  'tax', v_tax_id, 'tax_payment',
       p_amount, 0, 'Bayar ' || p_tax_type || ': ' || coalesce(p_description, ''),
       public.v_year_of(p_date), auth.uid()),
      (p_date, '1111',  'tax', v_tax_id, 'tax_payment',
       0, p_amount, 'Bayar ' || p_tax_type || ': ' || coalesce(p_description, ''),
       public.v_year_of(p_date), auth.uid());
  else
    insert into public.ledger_entries (
      entry_date, account_code, source_book, reference_id, reference_type,
      debit_amount, credit_amount, description, fiscal_year, created_by
    ) values
      (p_date, v_account,  'tax', v_tax_id, 'tax_payment',
       p_amount, 0, 'Hutang ' || p_tax_type || ': ' || coalesce(p_description, ''),
       public.v_year_of(p_date), auth.uid()),
      (p_date, '2122',  'tax', v_tax_id, 'tax_payment',
       0, p_amount, 'Hutang ' || p_tax_type || ': ' || coalesce(p_description, ''),
       public.v_year_of(p_date), auth.uid());
  end if;

  return v_tax_id;
end;
$$;

revoke all on function public.insert_tax(text, text, numeric, date, text, text, text)
  from anon, public;
grant execute on function public.insert_tax(text, text, numeric, date, text, text, text)
  to authenticated;

-- 4. RPC update pajak + ledger sync
create or replace function public.update_tax(
  p_id uuid,
  p_tax_type text,
  p_description text,
  p_amount numeric,
  p_date date,
  p_status text,
  p_reference_number text default null,
  p_notes text default null
)
returns void
language plpgsql
set search_path = public
as $$
declare
  v_old record;
  v_account text;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  select * into v_old from public.taxes where id = p_id;
  if not found then
    raise exception 'Data pajak tidak ditemukan';
  end if;

  update public.taxes set
    tax_type = p_tax_type,
    description = p_description,
    amount = p_amount,
    tax_date = p_date,
    status = p_status,
    reference_number = p_reference_number,
    notes = p_notes
  where id = p_id;

  -- Hapus jurnal lama
  delete from public.ledger_entries
   where reference_id = p_id and reference_type = 'tax_payment';

  -- Post jurnal baru sesuai status
  v_account := case
    when p_tax_type in ('PPh 21', 'PPh 23') then '5126'
    when p_tax_type = 'PPN' then '5127'
    else '5126'
  end;

  if p_status = 'paid' then
    insert into public.ledger_entries (
      entry_date, account_code, source_book, reference_id, reference_type,
      debit_amount, credit_amount, description, fiscal_year, created_by
    ) values
      (p_date, v_account,  'tax', p_id, 'tax_payment',
       p_amount, 0, 'Bayar ' || p_tax_type || ': ' || coalesce(p_description, ''),
       public.v_year_of(p_date), auth.uid()),
      (p_date, '1111',  'tax', p_id, 'tax_payment',
       0, p_amount, 'Bayar ' || p_tax_type || ': ' || coalesce(p_description, ''),
       public.v_year_of(p_date), auth.uid());
  else
    insert into public.ledger_entries (
      entry_date, account_code, source_book, reference_id, reference_type,
      debit_amount, credit_amount, description, fiscal_year, created_by
    ) values
      (p_date, v_account,  'tax', p_id, 'tax_payment',
       p_amount, 0, 'Hutang ' || p_tax_type || ': ' || coalesce(p_description, ''),
       public.v_year_of(p_date), auth.uid()),
      (p_date, '2122',  'tax', p_id, 'tax_payment',
       0, p_amount, 'Hutang ' || p_tax_type || ': ' || coalesce(p_description, ''),
       public.v_year_of(p_date), auth.uid());
  end if;
end;
$$;

revoke all on function public.update_tax(uuid, text, text, numeric, date, text, text, text)
  from anon, public;
grant execute on function public.update_tax(uuid, text, text, numeric, date, text, text, text)
  to authenticated;

-- 5. RPC delete pajak + void ledger
create or replace function public.delete_tax(
  p_id uuid
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
   where reference_id = p_id and reference_type = 'tax_payment';

  delete from public.taxes where id = p_id;
end;
$$;

revoke all on function public.delete_tax(uuid)
  from anon, public;
grant execute on function public.delete_tax(uuid)
  to authenticated;
