-- =============================================================
-- ITERASI 12 — Auto-Hitung SHU dari Buku Besar + Distribusi
-- Dividen Anggota
--
-- 1. RPC calculate_shu_for_year: hitung SHU dari ledger_entries
-- 2. Savings type 'DIV' (Dividen SHU) + update check constraint
-- 3. Update create_savings_transaction: tambah mapping DIV -> 3118
-- 4. Updated distribute_shu: distribusi dividen per anggota aktif
--    + posting ke ledger_entries
-- 5. Updated cancel_shu_distribution: cabut dividen + ledger
-- =============================================================

-- 1. Fungsi auto-hitung SHU dari buku besar
create or replace function public.calculate_shu_for_year(
  p_year integer
)
returns table (
  total_revenue numeric,
  total_expense numeric,
  net_shu numeric
)
language plpgsql
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  return query
  select
    coalesce(sum(case when coa.account_type = 'revenue' then le.credit_amount else 0 end), 0)::numeric,
    coalesce(sum(case when coa.account_type = 'expense' then le.debit_amount else 0 end), 0)::numeric,
    coalesce(
      sum(case when coa.account_type = 'revenue' then le.credit_amount else 0 end) -
      sum(case when coa.account_type = 'expense' then le.debit_amount else 0 end),
      0
    )::numeric
  from public.ledger_entries le
  join public.chart_of_accounts coa on coa.code = le.account_code
  where le.fiscal_year = p_year
    and le.is_void = false
    and coa.account_type in ('revenue', 'expense');
end;
$$;

revoke all on function public.calculate_shu_for_year(integer) from anon, public;
grant execute on function public.calculate_shu_for_year(integer) to authenticated;

-- 2. Tambah savings_type Dividen SHU
--    Update check constraint agar code 'DIV' diizinkan
alter table public.savings_types
  drop constraint if exists savings_types_code_check;

alter table public.savings_types
  add constraint savings_types_code_check
  check (code in ('SP', 'SWB', 'SMS', 'SWK', 'DIV'));

insert into public.savings_types (code, name, interest_rate, is_withdrawable, is_system_managed)
values ('DIV', 'Dividen SHU', 0.0000, true, true)
on conflict (code) do nothing;

-- Dividen dikelola sistem: tidak boleh disetor manual (bersihkan flag lama bila ada)
update public.savings_types
   set is_system_managed = true,
       is_withdrawable = true
 where code = 'DIV';

-- 3. Update create_savings_transaction: tambah mapping DIV -> 3118 (SHU)
create or replace function public.create_savings_transaction(
  p_member_id uuid,
  p_savings_type_code text,
  p_transaction_type text,
  p_amount numeric,
  p_description text default null
)
returns public.savings_transactions
language plpgsql
set search_path = public
as $$
declare
  v_type public.savings_types;
  v_tx public.savings_transactions;
  v_balance numeric;
  v_saving_code text;
  v_debit_code text;
  v_credit_code text;
  v_year integer := extract(year from current_date);
begin
  if auth.uid() is null then
    raise exception 'Tidak memiliki akses. Silakan login ulang';
  end if;

  if p_transaction_type not in ('deposit', 'withdrawal') then
    raise exception 'Tipe transaksi tidak valid';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'Nominal harus lebih dari 0';
  end if;

  select * into v_type from public.savings_types where code = p_savings_type_code;
  if v_type.id is null then
    raise exception 'Jenis simpanan tidak ditemukan';
  end if;

  if p_transaction_type = 'withdrawal' then
    if v_type.is_withdrawable = false then
      raise exception 'Jenis simpanan % tidak dapat ditarik', v_type.code;
    end if;
    select coalesce(sum(
      case when t.transaction_type = 'deposit' then t.amount else -t.amount end
    ), 0)
      into v_balance
      from public.savings_transactions t
     where t.member_id = p_member_id
       and t.savings_type_id = v_type.id
       and t.is_void = false;
    if v_balance < p_amount then
      raise exception 'Saldo tidak mencukupi. Saldo saat ini: %', v_balance;
    end if;
  end if;

  v_saving_code := case v_type.code
    when 'SP' then '3112'
    when 'SWB' then '3113'
    when 'SMS' then '2111'
    when 'SWK' then '2113'
    when 'DIV' then '3118'
  end;

  if p_transaction_type = 'deposit' then
    v_debit_code := '1111';
    v_credit_code := v_saving_code;
  else
    v_debit_code := v_saving_code;
    v_credit_code := '1111';
  end if;

  insert into public.savings_transactions (
    member_id, savings_type_id, transaction_type, amount,
    transaction_date, description, reference_type, created_by
  ) values (
    p_member_id, v_type.id, p_transaction_type, p_amount,
    current_date,
    coalesce(p_description,
      case when p_transaction_type = 'deposit' then 'Setoran ' else 'Penarikan ' end || v_type.name),
    'manual', auth.uid()
  )
  returning * into v_tx;

  insert into public.ledger_entries (
    entry_date, account_code, source_book, reference_id, reference_type,
    debit_amount, credit_amount, description, fiscal_year, created_by
  ) values
    (current_date, v_debit_code, 'savings', v_tx.id, 'savings_transaction',
     p_amount, 0, v_tx.description, v_year, auth.uid()),
    (current_date, v_credit_code, 'savings', v_tx.id, 'savings_transaction',
     0, p_amount, v_tx.description, v_year, auth.uid());

  return v_tx;
end;
$$;

revoke execute on function public.create_savings_transaction(uuid, text, text, numeric, text) from anon;
grant execute on function public.create_savings_transaction(uuid, text, text, numeric, text) to authenticated;

-- 4. Updated distribute_shu: alokasi dana + dividen anggota + posting ledger
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
  v_dividend numeric;
  v_member_count integer;
  v_per_member numeric;
  v_div_type_id uuid;
  v_active_member record;
  v_year integer;
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

  v_year := v_shu.fiscal_year;

  -- Alokasi dana ke fund_transactions (sudah ada)
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

  -- Posting ledger untuk alokasi dana
  insert into public.ledger_entries (
    entry_date, account_code, source_book, reference_id, reference_type,
    debit_amount, credit_amount, description, fiscal_year, created_by
  )
  select
    coalesce(v_shu.distribution_date, current_date),
    t.account_code, 'fund', v_shu.id, 'shu_distribution',
    t.amount, 0,
    'Alokasi SHU ' || v_shu.fiscal_year || ' — ' || t.label,
    v_year, auth.uid()
  from (values
    ('3118', 'SHU', v_shu.net_shu),
    ('4111', 'Dana Sosial', -v_social),
    ('4112', 'Dana Pendidikan', -v_education),
    ('4113', 'Dana Cadangan', -v_reserve)
  ) as t(account_code, label, amount)
  where t.amount > 0;

  -- Distribusi dividen ke anggota aktif
  v_dividend := round(v_shu.net_shu * coalesce(v_shu.member_dividend_pct, 0), 2);

  if v_dividend > 0 then
    select count(*) into v_member_count
      from public.members where status = 'active';

    if v_member_count > 0 then
      v_per_member := round(v_dividend / v_member_count, 2);

      select id into v_div_type_id
        from public.savings_types where code = 'DIV';

      for v_active_member in
        select id, name from public.members where status = 'active'
      loop
        -- Insert transaksi simpanan dividen
        insert into public.savings_transactions (
          member_id, savings_type_id, transaction_type, amount,
          transaction_date, description, reference_type, reference_id, created_by
        ) values (
          v_active_member.id, v_div_type_id, 'deposit', v_per_member,
          coalesce(v_shu.distribution_date, current_date),
          'Dividen SHU tahun ' || v_shu.fiscal_year || ' — ' || v_active_member.name,
          'shu_distribution', v_shu.id, auth.uid()
        );

        -- Posting ledger untuk dividen anggota
        insert into public.ledger_entries (
          entry_date, account_code, source_book, reference_id, reference_type,
          debit_amount, credit_amount, description, fiscal_year, created_by
        ) values (
          coalesce(v_shu.distribution_date, current_date),
          '3118', 'savings', v_shu.id, 'shu_distribution',
          v_per_member, 0,
          'Dividen SHU ' || v_shu.fiscal_year || ' — ' || v_active_member.name,
          v_year, auth.uid()
        ),
        (
          coalesce(v_shu.distribution_date, current_date),
          '3118', 'savings', v_shu.id, 'shu_distribution',
          0, v_per_member,
          'Dividen SHU ' || v_shu.fiscal_year || ' — ' || v_active_member.name,
          v_year, auth.uid()
        );
      end loop;
    end if;
  end if;

  update public.shu_distributions set
    status = 'distributed',
    distribution_date = coalesce(distribution_date, current_date)
  where id = p_distribution_id;
end;
$$;

revoke all on function public.distribute_shu(uuid) from anon, public;
grant execute on function public.distribute_shu(uuid) to authenticated;

-- 5. Updated cancel_shu_distribution: cabut dana + dividen + ledger
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

  -- Cabut alokasi dana
  delete from public.fund_transactions
   where reference_id = p_distribution_id
     and source_type = 'shu_allocation';

  -- Cabut transaksi simpanan dividen
  delete from public.savings_transactions
   where reference_id = p_distribution_id
     and reference_type = 'shu_distribution';

  -- Cabut posting ledger
  delete from public.ledger_entries
   where reference_id = p_distribution_id
     and reference_type = 'shu_distribution';

  update public.shu_distributions set
    status = 'draft',
    distribution_date = null
  where id = p_distribution_id;
end;
$$;

revoke all on function public.cancel_shu_distribution(uuid) from anon, public;
grant execute on function public.cancel_shu_distribution(uuid) to authenticated;
