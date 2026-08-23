-- =============================================================
-- Sadaya — Initial Schema (KSU Cahaya Dhamma Phala)
-- Jalankan di Supabase SQL Editor (urutan: 01 -> 02 -> 03)
--
-- CATATAN: Blok DROP di awal akan menghapus tabel Sadaya yang ada
-- beserta datanya (untuk pengulangan saat fase development).
-- =============================================================

create extension if not exists "pgcrypto";

-- -------------------------------------------------------------
-- Reset (development only): hapus tabel lama jika sudah ada
-- -------------------------------------------------------------
drop table if exists public.ledger_entries cascade;
drop table if exists public.app_settings cascade;
drop table if exists public.budget_plans cascade;
drop table if exists public.fiscal_years cascade;
drop table if exists public.chart_of_accounts cascade;
drop table if exists public.chip_sales cascade;
drop table if exists public.chip_productions cascade;
drop table if exists public.chip_material_transactions cascade;
drop table if exists public.chip_raw_materials cascade;
drop table if exists public.asset_depreciations cascade;
drop table if exists public.assets cascade;
drop table if exists public.shu_distributions cascade;
drop table if exists public.fund_transactions cascade;
drop table if exists public.tax_records cascade;
drop table if exists public.bank_transactions cascade;
drop table if exists public.cash_transactions cascade;
drop table if exists public.transaction_categories cascade;
drop table if exists public.interest_distributions cascade;
drop table if exists public.installment_payments cascade;
drop table if exists public.installment_schedules cascade;
drop table if exists public.loans cascade;
drop table if exists public.savings_transactions cascade;
drop table if exists public.savings_types cascade;
drop table if exists public.members cascade;
drop table if exists public.users cascade;

drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();

-- -------------------------------------------------------------
-- Helper: updated_at otomatis
-- -------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- -------------------------------------------------------------
-- chart_of_accounts : daftar kode akun (dibuat duluan karena
-- direferensikan assets, ledger_entries, dll.)
-- -------------------------------------------------------------
create table public.chart_of_accounts (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null,
  account_type text not null check (account_type in ('asset', 'liability', 'equity', 'revenue', 'expense')),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- -------------------------------------------------------------
-- users : profil pengurus, terhubung ke auth.users (Supabase Auth)
-- -------------------------------------------------------------
create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique not null,
  full_name text not null default '',
  jabatan text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, email, full_name)
  values (new.id, new.email, split_part(new.email, '@', 1));
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create trigger trg_users_updated_at
before update on public.users
for each row execute function public.set_updated_at();

-- -------------------------------------------------------------
-- members : anggota koperasi (tanpa akun login)
-- -------------------------------------------------------------
create table public.members (
  id uuid primary key default gen_random_uuid(),
  member_number integer unique not null,
  name text not null,
  address text,
  phone text,
  join_date date not null,
  status text not null default 'active' check (status in ('active', 'inactive')),
  notes text,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_members_name on public.members(name);
create index idx_members_status on public.members(status);

create trigger trg_members_updated_at
before update on public.members
for each row execute function public.set_updated_at();

-- -------------------------------------------------------------
-- savings_types & savings_transactions
-- -------------------------------------------------------------
create table public.savings_types (
  id uuid primary key default gen_random_uuid(),
  code text unique not null check (code in ('SP', 'SWB', 'SMS', 'SWK')),
  name text not null,
  interest_rate numeric(5,4) not null default 0,
  is_withdrawable boolean not null default false,
  is_system_managed boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.savings_transactions (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id),
  savings_type_id uuid not null references public.savings_types(id),
  transaction_type text not null check (transaction_type in ('deposit', 'withdrawal')),
  amount numeric(15,2) not null check (amount > 0),
  transaction_date date not null,
  description text,
  reference_id uuid,
  reference_type text check (reference_type in ('installment_payment', 'manual', 'shu_distribution')),
  created_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_void boolean not null default false,
  void_reason text,
  void_at timestamptz,
  void_by uuid references public.users(id)
);

create index idx_savings_tx_member on public.savings_transactions(member_id);
create index idx_savings_tx_date on public.savings_transactions(transaction_date);
create index idx_savings_tx_ref on public.savings_transactions(reference_id);

create trigger trg_savings_tx_updated_at
before update on public.savings_transactions
for each row execute function public.set_updated_at();

-- -------------------------------------------------------------
-- loans / installment_schedules / installment_payments /
-- interest_distributions
-- -------------------------------------------------------------
create table public.loans (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id),
  loan_number serial,
  principal_amount numeric(15,2) not null check (principal_amount > 0),
  tenor integer not null check (tenor > 0),
  interest_rate numeric(5,4) not null default 0.02,
  admin_fee_rate numeric(5,4) not null default 0.03,
  admin_fee_amount numeric(15,2) not null,
  disbursement_date date not null,
  status text not null default 'active' check (status in ('active', 'paid_off', 'restructured')),
  remaining_balance numeric(15,2) not null,
  total_paid_principal numeric(15,2) not null default 0,
  total_paid_interest numeric(15,2) not null default 0,
  notes text,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_loans_member on public.loans(member_id);
create index idx_loans_status on public.loans(status);

create trigger trg_loans_updated_at
before update on public.loans
for each row execute function public.set_updated_at();

create table public.installment_schedules (
  id uuid primary key default gen_random_uuid(),
  loan_id uuid not null references public.loans(id) on delete cascade,
  installment_number integer not null,
  due_date date not null,
  principal_amount numeric(15,2) not null,
  interest_amount numeric(15,2) not null,
  total_amount numeric(15,2) not null,
  status text not null default 'pending' check (status in ('pending', 'paid', 'partial', 'overdue')),
  created_at timestamptz not null default now(),
  unique (loan_id, installment_number)
);

create index idx_schedule_loan on public.installment_schedules(loan_id);
create index idx_schedule_due on public.installment_schedules(due_date);

create table public.installment_payments (
  id uuid primary key default gen_random_uuid(),
  loan_id uuid not null references public.loans(id),
  schedule_id uuid references public.installment_schedules(id),
  payment_date date not null,
  principal_paid numeric(15,2) not null default 0,
  interest_paid numeric(15,2) not null default 0,
  total_paid numeric(15,2) not null,
  remaining_balance numeric(15,2) not null,
  swk_amount numeric(15,2) not null default 0,
  notes text,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  is_void boolean not null default false,
  void_reason text,
  void_at timestamptz,
  void_by uuid references public.users(id)
);

create index idx_payment_loan on public.installment_payments(loan_id);
create index idx_payment_date on public.installment_payments(payment_date);

create table public.interest_distributions (
  id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references public.installment_payments(id) on delete cascade,
  distribution_date date not null,
  total_interest numeric(15,2) not null,
  japinup_amount numeric(15,2) not null default 0,
  social_fund_amount numeric(15,2) not null default 0,
  education_fund_amount numeric(15,2) not null default 0,
  crk_amount numeric(15,2) not null default 0,
  development_fund_amount numeric(15,2) not null default 0,
  swk_amount numeric(15,2) not null default 0,
  welfare_fund_amount numeric(15,2) not null default 0,
  created_at timestamptz not null default now()
);

create index idx_dist_payment on public.interest_distributions(payment_id);
create index idx_dist_date on public.interest_distributions(distribution_date);

-- -------------------------------------------------------------
-- Keuangan: kategori transaksi, kas harian, bank, pajak
-- -------------------------------------------------------------
create table public.transaction_categories (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null,
  category_type text not null check (category_type in ('income', 'expense')),
  parent_category text check (parent_category in ('rapat', 'lembur_atk', 'pembinaan', 'jasa_rat')),
  created_at timestamptz not null default now()
);

create table public.cash_transactions (
  id uuid primary key default gen_random_uuid(),
  transaction_date date not null,
  transaction_type text not null check (transaction_type in ('income', 'expense')),
  category_id uuid references public.transaction_categories(id),
  amount numeric(15,2) not null check (amount > 0),
  description text not null,
  reference_id uuid,
  reference_type text check (reference_type in ('savings', 'loan', 'installment', 'fund', 'manual')),
  created_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_void boolean not null default false,
  void_reason text
);

create index idx_cash_date on public.cash_transactions(transaction_date);
create index idx_cash_ref on public.cash_transactions(reference_id);

create trigger trg_cash_updated_at
before update on public.cash_transactions
for each row execute function public.set_updated_at();

create table public.bank_transactions (
  id uuid primary key default gen_random_uuid(),
  transaction_date date not null,
  transaction_type text not null check (transaction_type in ('credit', 'debit')),
  amount numeric(15,2) not null check (amount > 0),
  description text not null,
  bank_name text,
  reference_number text,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  is_void boolean not null default false
);

create index idx_bank_date on public.bank_transactions(transaction_date);

create table public.tax_records (
  id uuid primary key default gen_random_uuid(),
  fiscal_year integer not null,
  tax_type text not null default 'pph21',
  taxable_amount numeric(15,2) not null,
  tax_rate numeric(5,4) not null,
  tax_amount numeric(15,2) not null,
  payment_date date,
  status text not null default 'pending' check (status in ('pending', 'paid')),
  notes text,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now()
);

create index idx_tax_year on public.tax_records(fiscal_year);

-- -------------------------------------------------------------
-- Dana & SHU
-- -------------------------------------------------------------
create table public.fund_transactions (
  id uuid primary key default gen_random_uuid(),
  fund_type text not null check (fund_type in ('social', 'education', 'welfare', 'crk', 'development', 'reserve')),
  transaction_type text not null check (transaction_type in ('income', 'expense')),
  transaction_date date not null,
  amount numeric(15,2) not null check (amount > 0),
  description text not null,
  source_type text check (source_type in ('interest_distribution', 'shu_allocation', 'manual')),
  reference_id uuid,
  member_id uuid references public.members(id),
  created_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  is_void boolean not null default false
);

create index idx_fund_type_date on public.fund_transactions(fund_type, transaction_date);
create index idx_fund_ref on public.fund_transactions(reference_id);

create table public.shu_distributions (
  id uuid primary key default gen_random_uuid(),
  fiscal_year integer not null,
  total_shu numeric(15,2) not null,
  tax_amount numeric(15,2) not null default 0,
  net_shu numeric(15,2) not null,
  reserve_fund_pct numeric(5,4),
  social_fund_pct numeric(5,4) default 0.05,
  education_fund_pct numeric(5,4) default 0.05,
  member_dividend_pct numeric(5,4),
  management_pct numeric(5,4),
  distribution_date date,
  status text not null default 'draft' check (status in ('draft', 'approved', 'distributed')),
  notes text,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  unique (fiscal_year)
);

-- -------------------------------------------------------------
-- Aset: inventaris & penyusutan
-- -------------------------------------------------------------
create table public.assets (
  id uuid primary key default gen_random_uuid(),
  account_code text references public.chart_of_accounts(code),
  name text not null,
  description text,
  acquisition_date date not null,
  acquisition_cost numeric(15,2) not null check (acquisition_cost >= 0),
  useful_life_years integer not null check (useful_life_years > 0),
  salvage_value numeric(15,2) not null default 0,
  depreciation_method text not null default 'straight_line',
  status text not null default 'active' check (status in ('active', 'disposed', 'written_off')),
  created_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger trg_assets_updated_at
before update on public.assets
for each row execute function public.set_updated_at();

create table public.asset_depreciations (
  id uuid primary key default gen_random_uuid(),
  asset_id uuid not null references public.assets(id) on delete cascade,
  fiscal_year integer not null,
  depreciation_amount numeric(15,2) not null,
  accumulated_depreciation numeric(15,2) not null,
  book_value numeric(15,2) not null,
  calculated_at timestamptz not null default now(),
  unique (asset_id, fiscal_year)
);

-- -------------------------------------------------------------
-- Unit Usaha Keripik
-- -------------------------------------------------------------
create table public.chip_raw_materials (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  unit text not null default 'kg',
  current_stock numeric(10,2) not null default 0,
  created_at timestamptz not null default now()
);

create table public.chip_material_transactions (
  id uuid primary key default gen_random_uuid(),
  material_id uuid not null references public.chip_raw_materials(id),
  transaction_type text not null check (transaction_type in ('purchase', 'usage')),
  quantity numeric(10,2) not null check (quantity > 0),
  unit_price numeric(15,2),
  total_price numeric(15,2),
  transaction_date date not null,
  notes text,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now()
);

create index idx_chip_mat_date on public.chip_material_transactions(transaction_date);

create table public.chip_productions (
  id uuid primary key default gen_random_uuid(),
  product_type text not null check (product_type in ('keripik_kentang', 'keripik_salak', 'kopi')),
  production_date date not null,
  quantity_produced numeric(10,2) not null check (quantity_produced > 0),
  unit text not null default 'kg',
  production_cost numeric(15,2),
  notes text,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now()
);

create index idx_chip_prod_date on public.chip_productions(production_date);

create table public.chip_sales (
  id uuid primary key default gen_random_uuid(),
  product_type text not null check (product_type in ('keripik_kentang', 'keripik_salak', 'kopi')),
  sale_date date not null,
  quantity numeric(10,2) not null check (quantity > 0),
  unit_price numeric(15,2) not null,
  total_price numeric(15,2) not null,
  buyer text,
  notes text,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now()
);

create index idx_chip_sales_date on public.chip_sales(sale_date);

-- -------------------------------------------------------------
-- Perencanaan & tahun buku
-- -------------------------------------------------------------
create table public.budget_plans (
  id uuid primary key default gen_random_uuid(),
  fiscal_year integer not null,
  category_id uuid references public.transaction_categories(id),
  category_name text not null,
  planned_amount numeric(15,2) not null,
  notes text,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  unique (fiscal_year, category_id)
);

create table public.fiscal_years (
  id uuid primary key default gen_random_uuid(),
  year integer unique not null,
  start_date date not null,
  end_date date not null,
  is_active boolean not null default false,
  is_closed boolean not null default false,
  created_at timestamptz not null default now()
);

-- -------------------------------------------------------------
-- Ledger pusat (Buku Laporan Komposisi Keuangan)
-- -------------------------------------------------------------
create table public.ledger_entries (
  id uuid primary key default gen_random_uuid(),
  entry_date date not null,
  account_code text not null references public.chart_of_accounts(code),
  source_book text not null check (source_book in ('cash', 'bank', 'savings', 'loan', 'installment', 'fund', 'asset', 'chip_business', 'tax')),
  reference_id uuid not null,
  reference_type text not null,
  debit_amount numeric(15,2) not null default 0,
  credit_amount numeric(15,2) not null default 0,
  description text not null,
  fiscal_year integer not null,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  is_void boolean not null default false
);

create index idx_ledger_account on public.ledger_entries(account_code);
create index idx_ledger_date on public.ledger_entries(entry_date);
create index idx_ledger_fiscal on public.ledger_entries(fiscal_year);
create index idx_ledger_source on public.ledger_entries(source_book);
create index idx_ledger_ref on public.ledger_entries(reference_id);

-- -------------------------------------------------------------
-- app_settings
-- -------------------------------------------------------------
create table public.app_settings (
  id uuid primary key default gen_random_uuid(),
  key text unique not null,
  value text not null,
  description text,
  updated_at timestamptz not null default now()
);

create trigger trg_app_settings_updated_at
before update on public.app_settings
for each row execute function public.set_updated_at();
