-- =============================================================
-- ITERASI 22/23 — Alokasi SHU 8 pos (sesuai AD/ART) + distribusi
-- proporsional ke anggota
--
-- 1. Kolom persen baru di shu_distributions:
--    member_savings_pct (Dasim — Dana Anggota dari Simpanan, basis SWB),
--    member_service_pct (Dapin — Dana Anggota dari Pinjaman),
--    staff_pct (Pegawai/Karyawan),
--    development_pct (Dana Pembangunan).
--    (reserve/social/education/management tetap dipakai)
-- 2. distribute_shu ditulis ulang:
--    - Jurnal SHU: Dr 3118 SHU dibagikan, Cr akun dana yang benar
--      (3116 Cadangan, 2114 Sosial, 2115 Pendidikan, 3114
--      Pembangunan, 2121 Pengurus&Pengawas+Pegawai, 2120 Anggota)
--    - Buku Dana: income social/education/reserve/development
--    - Distribusi dividen proporsional per anggota:
--        Dasim = proporsional saldo SWB (per 31-12) anggota
--        Dapin = proporsional jumlah SWK anggota tahun buku
-- 3. create_savings_transaction: DIV dipetakan ke 2120 (bukan 3118)
--    agar penarikan dividen mengurangi akrual Dana Anggota.
-- =============================================================

-- 1. Kolom persen baru (idempotent)
alter table public.shu_distributions
  add column if not exists member_savings_pct numeric(5,4),
  add column if not exists member_service_pct numeric(5,4),
  add column if not exists staff_pct numeric(5,4),
  add column if not exists development_pct numeric(5,4);

-- 2. distribusi SHU 8 pos + proporsional
create or replace function public.distribute_shu(
  p_distribution_id uuid
)
returns void
language plpgsql
set search_path = public
as $$
declare
  v_shu public.shu_distributions;
  v_year integer;
  v_dist_date date;
  v_div_type_id uuid;

  v_reserve numeric;
  v_social numeric;
  v_education numeric;
  v_development numeric;
  v_management numeric;
  v_staff numeric;
  v_member_savings numeric;
  v_member_service numeric;
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
  v_dist_date := coalesce(v_shu.distribution_date, current_date);
  v_div_type_id := (select id from public.savings_types where code = 'DIV');

  -- Nilai rupiah tiap pos alokasi (net SHU x persen)
  v_reserve     := round(v_shu.net_shu * coalesce(v_shu.reserve_fund_pct, 0), 2);
  v_social      := round(v_shu.net_shu * coalesce(v_shu.social_fund_pct, 0), 2);
  v_education   := round(v_shu.net_shu * coalesce(v_shu.education_fund_pct, 0), 2);
  v_development := round(v_shu.net_shu * coalesce(v_shu.development_pct, 0), 2);
  v_management  := round(v_shu.net_shu * coalesce(v_shu.management_pct, 0), 2);
  v_staff       := round(v_shu.net_shu * coalesce(v_shu.staff_pct, 0), 2);
  v_member_savings  := round(v_shu.net_shu * coalesce(v_shu.member_savings_pct, 0), 2);
  v_member_service  := round(v_shu.net_shu * coalesce(v_shu.member_service_pct, 0), 2);

  -- Buku Dana: pemasukan otomatis per jenis dana
  insert into public.fund_transactions (
    fund_type, transaction_type, transaction_date, amount,
    description, source_type, reference_id, created_by
  )
  select t.fund_type, 'income', v_dist_date,
         t.amount,
         'Alokasi SHU tahun fiskal ' || v_year,
         'shu_allocation', v_shu.id, auth.uid()
  from (values
    ('reserve', v_reserve),
    ('social', v_social),
    ('education', v_education),
    ('development', v_development)
  ) as t(fund_type, amount)
  where t.amount > 0;

  -- Jurnal pembagian SHU (balanced: Dr 3118 = jumlah seluruh pos)
  insert into public.ledger_entries (
    entry_date, account_code, source_book, reference_id, reference_type,
    debit_amount, credit_amount, description, fiscal_year, created_by
  )
  select
    v_dist_date,
    t.account_code, 'fund', v_shu.id, 'shu_distribution',
    t.debit, t.credit,
    'Alokasi SHU ' || v_year || ' — ' || t.label,
    v_year, auth.uid()
  from (values
    ('3118', 'SHU dibagikan',
       v_reserve + v_social + v_education + v_development + v_management + v_staff + v_member_savings + v_member_service, 0),
    ('3116', 'Dana Cadangan',             0, v_reserve),
    ('2114', 'Dana Sosial',               0, v_social),
    ('2115', 'Dana Pendidikan',           0, v_education),
    ('3114', 'Dana Pembangunan',          0, v_development),
    ('2121', 'Pengurus & Pengawas',       0, v_management),
    ('2121', 'Pegawai/Karyawan',          0, v_staff),
    ('2120', 'Dasim + Dapin (Anggota)', 0, v_member_savings + v_member_service)
  ) as t(account_code, label, debit, credit)
  where t.debit > 0 or t.credit > 0;

  -- Dasim (Dana Anggota dari Simpanan): proporsional SALDO SWB per 31-12 tahun SHU
  if v_member_savings > 0 and v_div_type_id is not null then
    insert into public.savings_transactions (
      member_id, savings_type_id, transaction_type, amount,
      transaction_date, description, reference_id, reference_type, created_by
    )
    with basis as (
      select st.member_id,
             coalesce(sum(case when st.transaction_type = 'deposit' then st.amount else -st.amount end), 0) as bal
        from public.savings_transactions st
        join public.savings_types s on s.id = st.savings_type_id
       where st.is_void = false
         and s.code = 'SWB'
         and st.transaction_date <= make_date(v_year, 12, 31)
       group by st.member_id
      having coalesce(sum(case when st.transaction_type = 'deposit' then st.amount else -st.amount end), 0) > 0
    ),
    totals as (select sum(bal) as total from basis),
    raw as (
      select b.member_id, b.bal,
             round(v_member_savings * b.bal / t.total, 2) as amt,
             row_number() over (order by b.bal desc) as rn
        from basis b cross join totals t
    ),
    sums as (select sum(amt) as s from raw),
    alloc as (
      select r.member_id,
             case when r.rn = 1 then r.amt + (v_member_savings - sums.s) else r.amt end as amt
        from raw r cross join sums
    )
    select a.member_id, v_div_type_id, 'deposit', a.amt, v_dist_date,
           'Dasim (Dana Anggota dari Simpanan) SHU ' || v_year,
           v_shu.id, 'shu_distribution', auth.uid()
      from alloc a
     where a.amt > 0;
  end if;

  -- Dana Anggota Dapin: proporsional jumlah SWK anggota tahun SHU
  --   Dapin_anggota = (SWK_anggota / SWK_total) x v_member_service x SHU_bersih
  if v_member_service > 0 and v_div_type_id is not null then
    insert into public.savings_transactions (
      member_id, savings_type_id, transaction_type, amount,
      transaction_date, description, reference_id, reference_type, created_by
    )
    with basis as (
      select st.member_id, sum(st.amount) as swk
        from public.savings_transactions st
        join public.savings_types s on s.id = st.savings_type_id
       where st.is_void = false
         and s.code = 'SWK'
         and st.transaction_type = 'deposit'
         and extract(year from st.transaction_date) = v_year
       group by st.member_id
      having sum(st.amount) > 0
    ),
    totals as (select sum(swk) as total from basis),
    raw as (
      select b.member_id, b.swk,
             round(v_member_service * b.swk / t.total, 2) as amt,
             row_number() over (order by b.swk desc) as rn
        from basis b cross join totals t
    ),
    sums as (select sum(amt) as s from raw),
    alloc as (
      select r.member_id,
             case when r.rn = 1 then r.amt + (v_member_service - sums.s) else r.amt end as amt
        from raw r cross join sums
    )
    select a.member_id, v_div_type_id, 'deposit', a.amt, v_dist_date,
           'Dapin (Dana Anggota dari Pinjaman) SHU ' || v_year,
           v_shu.id, 'shu_distribution', auth.uid()
      from alloc a
     where a.amt > 0;
  end if;

  update public.shu_distributions set
    status = 'distributed',
    distribution_date = coalesce(distribution_date, v_dist_date)
  where id = p_distribution_id;
end;
$$;

revoke all on function public.distribute_shu(uuid) from anon, public;
grant execute on function public.distribute_shu(uuid) to authenticated;

-- 3. Mapping DIV -> 2120 (akrual Dana-dana untuk Anggota)
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
    when 'DIV' then '2120'
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