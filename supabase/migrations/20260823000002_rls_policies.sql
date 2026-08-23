-- =============================================================
-- Sadaya — Row Level Security
-- MVP hanya satu role: Pengurus (semua user terautentikasi).
-- =============================================================

alter table public.users enable row level security;
alter table public.members enable row level security;
alter table public.savings_types enable row level security;
alter table public.savings_transactions enable row level security;
alter table public.loans enable row level security;
alter table public.installment_schedules enable row level security;
alter table public.installment_payments enable row level security;
alter table public.interest_distributions enable row level security;
alter table public.transaction_categories enable row level security;
alter table public.cash_transactions enable row level security;
alter table public.bank_transactions enable row level security;
alter table public.tax_records enable row level security;
alter table public.fund_transactions enable row level security;
alter table public.shu_distributions enable row level security;
alter table public.assets enable row level security;
alter table public.asset_depreciations enable row level security;
alter table public.chip_raw_materials enable row level security;
alter table public.chip_material_transactions enable row level security;
alter table public.chip_productions enable row level security;
alter table public.chip_sales enable row level security;
alter table public.budget_plans enable row level security;
alter table public.fiscal_years enable row level security;
alter table public.chart_of_accounts enable row level security;
alter table public.ledger_entries enable row level security;
alter table public.app_settings enable row level security;

-- users: tiap pengurus hanya boleh lihat/ubah profil sendiri
create policy "users_select_own" on public.users
  for select using (auth.uid() = id);
create policy "users_update_own" on public.users
  for update using (auth.uid() = id) with check (auth.uid() = id);
create policy "users_insert_own" on public.users
  for insert with check (auth.uid() = id);

-- Semua tabel transaksi/master: akses penuh bagi pengurus terautentikasi.
-- (MVP single-role; pembatasan granular ditambah jika ada role baru.)
create policy "members_pengurus_all" on public.members
  for all to authenticated using (true) with check (true);
create policy "savings_types_pengurus_all" on public.savings_types
  for all to authenticated using (true) with check (true);
create policy "savings_tx_pengurus_all" on public.savings_transactions
  for all to authenticated using (true) with check (true);
create policy "loans_pengurus_all" on public.loans
  for all to authenticated using (true) with check (true);
create policy "schedules_pengurus_all" on public.installment_schedules
  for all to authenticated using (true) with check (true);
create policy "payments_pengurus_all" on public.installment_payments
  for all to authenticated using (true) with check (true);
create policy "dist_pengurus_all" on public.interest_distributions
  for all to authenticated using (true) with check (true);
create policy "categories_pengurus_all" on public.transaction_categories
  for all to authenticated using (true) with check (true);
create policy "cash_pengurus_all" on public.cash_transactions
  for all to authenticated using (true) with check (true);
create policy "bank_pengurus_all" on public.bank_transactions
  for all to authenticated using (true) with check (true);
create policy "tax_pengurus_all" on public.tax_records
  for all to authenticated using (true) with check (true);
create policy "fund_pengurus_all" on public.fund_transactions
  for all to authenticated using (true) with check (true);
create policy "shu_pengurus_all" on public.shu_distributions
  for all to authenticated using (true) with check (true);
create policy "assets_pengurus_all" on public.assets
  for all to authenticated using (true) with check (true);
create policy "depreciations_pengurus_all" on public.asset_depreciations
  for all to authenticated using (true) with check (true);
create policy "chip_materials_pengurus_all" on public.chip_raw_materials
  for all to authenticated using (true) with check (true);
create policy "chip_mat_tx_pengurus_all" on public.chip_material_transactions
  for all to authenticated using (true) with check (true);
create policy "chip_prod_pengurus_all" on public.chip_productions
  for all to authenticated using (true) with check (true);
create policy "chip_sales_pengurus_all" on public.chip_sales
  for all to authenticated using (true) with check (true);
create policy "budget_pengurus_all" on public.budget_plans
  for all to authenticated using (true) with check (true);
create policy "fiscal_years_pengurus_all" on public.fiscal_years
  for all to authenticated using (true) with check (true);
create policy "coa_pengurus_read" on public.chart_of_accounts
  for select to authenticated using (true);
create policy "ledger_pengurus_all" on public.ledger_entries
  for all to authenticated using (true) with check (true);
create policy "settings_pengurus_read" on public.app_settings
  for select to authenticated using (true);
