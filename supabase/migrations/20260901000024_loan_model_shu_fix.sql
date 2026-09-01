-- =============================================================
-- Sadaya — Migrasi 24: Penerapan kembali perubahan Iterasi 27–28
--   (model pinjaman: admin 3%, bunga = jasa 2%/3% flat dari pokok;
--    distribusi 7 pos membagi 100% bunga; Dapin basis SWK)
--
-- Idempotent: semua fungsi memakai CREATE OR REPLACE,
--   seed app_settings memakai UPSERT / on conflict.
-- Berlaku walau migrasi 00005/00023 sudah pernah diterapkan.
-- =============================================================

-- ---------------------------------------------------------------
-- 1. create_loan (model terbaru)
--    Admin = 3% x pokok semua jenis.
--    Bunga = jasa, flat dari total pokok:
--      angsur 2% x pokok (merata per bulan); cepat 3% x pokok.
-- ---------------------------------------------------------------
create or replace function public.create_loan(
  p_member_id uuid,
  p_principal numeric,
  p_tenor integer,
  p_disbursement_date date default current_date,
  p_notes text default null,
  p_loan_type text default 'regular'
)
returns public.loans
language plpgsql
set search_path = public
as $$
declare
  v_rate numeric;
  v_admin numeric;
  v_principal_per numeric(15,2);
  v_interest_per numeric(15,2);
  v_total_interest numeric(15,2);
  v_i integer;
  v_loan public.loans;
begin
  if auth.uid() is null then
    raise exception 'Tidak memiliki akses. Silakan login ulang';
  end if;

  if p_loan_type not in ('regular', 'fast') then
    raise exception 'Tipe pinjaman tidak valid';
  end if;

  if not exists (
    select 1 from public.members where id = p_member_id and status = 'active'
  ) then
    raise exception 'Anggota tidak ditemukan atau tidak aktif';
  end if;

  if p_principal is null or p_principal <= 0 then
    raise exception 'Jumlah pinjaman harus lebih dari 0';
  end if;

  if p_tenor is null or p_tenor < 1 or p_tenor > 50 then
    raise exception 'Tenor harus antara 1 sampai 50 bulan';
  end if;

  -- Bunga/jasa: flat dari total pokok pinjaman.
  --   Pinjaman angsur (regular) = 2% x pokok  (dibayar merata per angsuran)
  --   Pinjaman cepat (fast)     = 3% x pokok  (dibayar sekali di akhir tenor)
  --   Admin = 3% x pokok (30rb/1jt) dipotong saat pencairan untuk SEMUA jenis.
  v_rate := case when p_loan_type = 'fast' then 0.03 else 0.02 end;
  v_admin := round(p_principal * 0.03, 2);

  insert into public.loans (
    member_id, principal_amount, tenor, interest_rate, admin_fee_rate,
    admin_fee_amount, disbursement_date, loan_type, remaining_balance,
    notes, created_by
  ) values (
    p_member_id, p_principal, p_tenor, v_rate,
    0.03,
    v_admin, p_disbursement_date, p_loan_type, p_principal, p_notes,
    auth.uid()
  )
  returning * into v_loan;

  if p_loan_type = 'fast' then
    -- PINJAMAN CEPAT: tidak mengangsur. Satu jadwal jatuh tempo di akhir
    -- tenor, pokok full + bunga 3% x pokok (bukan per bulan).
    v_total_interest := round(p_principal * v_rate, 2);
    insert into public.installment_schedules (
      loan_id, installment_number, due_date, principal_amount,
      interest_amount, total_amount
    ) values (
      v_loan.id, 1,
      p_disbursement_date + make_interval(months => p_tenor),
      p_principal, v_total_interest, p_principal + v_total_interest
    );
  else
    -- PINJAMAN BIASA: angsur bulanan flat, pokok merata (cicilan terakhir
    -- menyerap sisa pembulatan). Total bunga = 2% x pokok, dibayar merata
    -- per bulan = (2% x pokok) / tenor.
    v_principal_per := round(p_principal / p_tenor, 2);
    v_interest_per := round(p_principal * v_rate / p_tenor, 2);

    for v_i in 1..p_tenor loop
      insert into public.installment_schedules (
        loan_id, installment_number, due_date, principal_amount,
        interest_amount, total_amount
      ) values (
        v_loan.id,
        v_i,
        p_disbursement_date + make_interval(months => v_i),
        case when v_i = p_tenor
             then p_principal - v_principal_per * (p_tenor - 1)
             else v_principal_per end,
        case when v_i = p_tenor
             then p_principal * v_rate - v_interest_per * (p_tenor - 1)
             else v_interest_per end,
        case when v_i = p_tenor
             then p_principal - v_principal_per * (p_tenor - 1)
                  + p_principal * v_rate - v_interest_per * (p_tenor - 1)
             else v_principal_per + v_interest_per end
      );
    end loop;
  end if;

  -- JURNAL PENCAIRAN: kas diterima bersih (pokok - administrasi 3%)
  insert into public.ledger_entries (
    entry_date, account_code, source_book, reference_id, reference_type,
    debit_amount, credit_amount, description, fiscal_year, created_by
  ) values
    (p_disbursement_date, '1113', 'loan', v_loan.id, 'loan_disbursement',
     p_principal, 0,
     'Pencairan pinjaman #' || v_loan.loan_number, v_year_of(p_disbursement_date), auth.uid()),
    (p_disbursement_date, '1111', 'loan', v_loan.id, 'loan_disbursement',
     0, p_principal - v_admin,
     'Pencairan pinjaman #' || v_loan.loan_number, v_year_of(p_disbursement_date), auth.uid()),
    (p_disbursement_date, '4112', 'loan', v_loan.id, 'loan_disbursement',
     0, v_admin,
     'Administrasi pinjaman #' || v_loan.loan_number, v_year_of(p_disbursement_date), auth.uid());

  return v_loan;
end;
$$;

create or replace function public.pay_installment(
  p_schedule_id uuid,
  p_principal_paid numeric default null,
  p_interest_paid numeric default null,
  p_notes text default null
)
returns public.installment_payments
language plpgsql
set search_path = public
as $$
declare
  v_sched public.installment_schedules;
  v_loan public.loans;
  v_prev_p numeric;
  v_prev_i numeric;
  v_p numeric;
  v_i numeric;
  v_swk numeric;
  v_kesra numeric;
  v_sosial numeric;
  v_pendidikan numeric;
  v_crk numeric;
  v_pembangunan numeric;
  v_japinup numeric;
  v_remaining numeric;
  v_pay public.installment_payments;
  v_sched_status text;
begin
  if auth.uid() is null then
    raise exception 'Tidak memiliki akses. Silakan login ulang';
  end if;

  select * into v_sched from public.installment_schedules
    where id = p_schedule_id for update;
  if v_sched.id is null then
    raise exception 'Jadwal cicilan tidak ditemukan';
  end if;

  select * into v_loan from public.loans where id = v_sched.loan_id for update;
  if v_loan.status <> 'active' then
    raise exception 'Pinjaman ini sudah lunas atau tidak aktif';
  end if;

  select coalesce(sum(principal_paid), 0), coalesce(sum(interest_paid), 0)
    into v_prev_p, v_prev_i
    from public.installment_payments
   where schedule_id = p_schedule_id and is_void = false;

  v_p := coalesce(p_principal_paid, v_sched.principal_amount - v_prev_p);
  v_i := coalesce(p_interest_paid, v_sched.interest_amount - v_prev_i);

  if v_p is null or v_p < 0 or v_i is null or v_i < 0 then
    raise exception 'Nominal pembayaran tidak valid';
  end if;
  if v_p > v_sched.principal_amount - v_prev_p + 0.005 then
    raise exception 'Pokok melebihi sisa jadwal (%. Maksimum: %)',
      to_char(v_p, 'FM999999999999'), to_char(v_sched.principal_amount - v_prev_p, 'FM999999999999');
  end if;
  if v_i > v_sched.interest_amount - v_prev_i + 0.005 then
    raise exception 'Jasa melebihi sisa jadwal (%. Maksimum: %)',
      to_char(v_i, 'FM999999999999'), to_char(v_sched.interest_amount - v_prev_i, 'FM999999999999');
  end if;
  if v_p + v_i <= 0 then
    raise exception 'Nominal pembayaran harus lebih dari 0';
  end if;

  v_remaining := v_loan.remaining_balance - v_p;

  insert into public.installment_payments (
    loan_id, schedule_id, payment_date, principal_paid, interest_paid,
    total_paid, remaining_balance, swk_amount, notes, created_by
  ) values (
    v_loan.id, p_schedule_id, current_date, v_p, v_i,
    v_p + v_i, v_remaining,
    round(v_i * case when v_loan.loan_type = 'fast' then 0.20/3.00 else 0.20/2.00 end, 2),
    coalesce(p_notes, 'Angsuran ke-' || v_sched.installment_number),
    auth.uid()
  )
  returning * into v_pay;

  -- Distribusi jasa ke 7 pos: membagi 100% BUNGA (jasa) yang dibayar (v_i).
  --   Total bunga pinjaman: angsur = 2% x pokok; cepat = 3% x pokok.
  --   Nilai bunga tsb lalu dibagi ke pos dengan fraksi (penyebut dasar):
  --   Angsur (dasar 2,00): Japinup 1,10/2 ; Kesra 0,50/2 ; SWK 0,20/2 ;
  --     Sosial/Pendidikan/CRK/Pembangunan masing 0,05/2.
  --   Cepat (dasar 3,00): Japinup 2,10/3 ; Kesra 0,50/3 ; SWK 0,20/3 ;
  --     lainnya masing 0,05/3.
  --   Japinup menyerap sisa pembulatan agar total = v_i.
  if v_i > 0 then
    if v_loan.loan_type = 'fast' then
      -- dasar 3,00; Japinup menyerap sisa pembulatan
      v_swk     := round(v_i * 0.20 / 3.00, 2);
      v_kesra   := round(v_i * 0.50 / 3.00, 2);
      v_sosial      := round(v_i * 0.05 / 3.00, 2);
      v_pendidikan  := round(v_i * 0.05 / 3.00, 2);
      v_crk         := round(v_i * 0.05 / 3.00, 2);
      v_pembangunan := round(v_i * 0.05 / 3.00, 2);
      v_japinup := v_i - (v_kesra + v_swk + v_sosial + v_pendidikan + v_crk + v_pembangunan);
    else
      -- dasar 2,00; Japinup menyerap sisa pembulatan
      v_kesra   := round(v_i * 0.50 / 2.00, 2);
      v_swk     := round(v_i * 0.20 / 2.00, 2);
      v_sosial      := round(v_i * 0.05 / 2.00, 2);
      v_pendidikan  := round(v_i * 0.05 / 2.00, 2);
      v_crk         := round(v_i * 0.05 / 2.00, 2);
      v_pembangunan := round(v_i * 0.05 / 2.00, 2);
      v_japinup := v_i - (v_kesra + v_swk + v_sosial + v_pendidikan + v_crk + v_pembangunan);
    end if;

    insert into public.interest_distributions (
      payment_id, distribution_date, total_interest, japinup_amount,
      social_fund_amount, education_fund_amount, crk_amount,
      development_fund_amount, swk_amount, welfare_fund_amount
    ) values (
      v_pay.id, current_date, v_i, v_japinup,
      v_sosial, v_pendidikan, v_crk,
      v_pembangunan, v_swk, v_kesra
    );

    -- Pemasukan otomatis ke Buku Dana (sesuai jenis dana)
    insert into public.fund_transactions (
      fund_type, transaction_type, transaction_date, amount,
      description, source_type, reference_id, created_by
    ) values
      ('welfare', 'income', current_date, v_kesra,
       'Distribusi jasa angsuran', 'interest_distribution', v_pay.id, auth.uid()),
      ('social', 'income', current_date, v_sosial,
       'Distribusi jasa angsuran', 'interest_distribution', v_pay.id, auth.uid()),
      ('education', 'income', current_date, v_pendidikan,
       'Distribusi jasa angsuran', 'interest_distribution', v_pay.id, auth.uid()),
      ('crk', 'income', current_date, v_crk,
       'Distribusi jasa angsuran', 'interest_distribution', v_pay.id, auth.uid()),
      ('development', 'income', current_date, v_pembangunan,
       'Distribusi jasa angsuran', 'interest_distribution', v_pay.id, auth.uid());

    -- SWK masuk saldo simpanan anggota (jurnal sudah tercakup jurnal utama)
    if v_swk > 0 then
      insert into public.savings_transactions (
        member_id, savings_type_id, transaction_type, amount,
        transaction_date, description, reference_id, reference_type, created_by
      ) values (
        v_loan.member_id,
        (select id from public.savings_types where code = 'SWK'),
        'deposit', v_swk, current_date,
        'SWK dari angsuran ke-' || v_sched.installment_number,
        v_pay.id, 'installment_payment', auth.uid()
      );
    end if;
  else
    v_japinup := 0;
  end if;

  if v_p >= v_sched.principal_amount - v_prev_p - 0.005
     and v_i >= v_sched.interest_amount - v_prev_i - 0.005 then
    v_sched_status := 'paid';
  else
    v_sched_status := 'partial';
  end if;

  update public.installment_schedules set status = v_sched_status
    where id = p_schedule_id;

  update public.loans set
    total_paid_principal = total_paid_principal + v_p,
    total_paid_interest = total_paid_interest + v_i,
    remaining_balance = v_remaining,
    status = case when v_remaining <= 0.005 then 'paid_off' else 'active' end
  where id = v_loan.id;

  -- JURNAL PEMBAYARAN CICILAN (kas, pelunasan pokok)
  insert into public.ledger_entries (
    entry_date, account_code, source_book, reference_id, reference_type,
    debit_amount, credit_amount, description, fiscal_year, created_by
  ) values
    (current_date, '1111', 'installment', v_pay.id, 'installment_payment',
     v_p + v_i, 0, v_pay.notes, extract(year from current_date)::int, auth.uid()),
    (current_date, '1113', 'installment', v_pay.id, 'installment_payment',
     0, v_p, v_pay.notes, extract(year from current_date)::int, auth.uid());

  -- JURNAL DISTRIBUSI JASA (7 pos)
  if v_i > 0 then
    insert into public.ledger_entries (
      entry_date, account_code, source_book, reference_id, reference_type,
      debit_amount, credit_amount, description, fiscal_year, created_by
    ) values
      (current_date, '4111', 'installment', v_pay.id, 'installment_payment',
       0, v_japinup, v_pay.notes, extract(year from current_date)::int, auth.uid()),
      (current_date, '2119', 'installment', v_pay.id, 'installment_payment',
       0, v_kesra, v_pay.notes, extract(year from current_date)::int, auth.uid()),
      (current_date, '2114', 'installment', v_pay.id, 'installment_payment',
       0, v_sosial, v_pay.notes, extract(year from current_date)::int, auth.uid()),
      (current_date, '2115', 'installment', v_pay.id, 'installment_payment',
       0, v_pendidikan, v_pay.notes, extract(year from current_date)::int, auth.uid()),
      (current_date, '3115', 'installment', v_pay.id, 'installment_payment',
       0, v_crk, v_pay.notes, extract(year from current_date)::int, auth.uid()),
      (current_date, '3114', 'installment', v_pay.id, 'installment_payment',
       0, v_pembangunan, v_pay.notes, extract(year from current_date)::int, auth.uid()),
      (current_date, '2113', 'installment', v_pay.id, 'installment_payment',
       0, v_swk, v_pay.notes, extract(year from current_date)::int, auth.uid());
  end if;

  return v_pay;
end;
$$;

revoke execute on function public.create_loan(uuid, numeric, integer, date, text, text) from anon;
grant execute on function public.create_loan(uuid, numeric, integer, date, text, text) to authenticated;
revoke execute on function public.pay_installment(uuid, numeric, numeric, text) from anon;
grant execute on function public.pay_installment(uuid, numeric, numeric, text) to authenticated;

-- ---------------------------------------------------------------
-- 2. distribute_shu (Dapin basis SWK tahun buku; Dasim basis SWB 31-12)
-- ---------------------------------------------------------------
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

  v_reserve     := round(v_shu.net_shu * coalesce(v_shu.reserve_fund_pct, 0), 2);
  v_social      := round(v_shu.net_shu * coalesce(v_shu.social_fund_pct, 0), 2);
  v_education   := round(v_shu.net_shu * coalesce(v_shu.education_fund_pct, 0), 2);
  v_development := round(v_shu.net_shu * coalesce(v_shu.development_pct, 0), 2);
  v_management  := round(v_shu.net_shu * coalesce(v_shu.management_pct, 0), 2);
  v_staff       := round(v_shu.net_shu * coalesce(v_shu.staff_pct, 0), 2);
  v_member_savings  := round(v_shu.net_shu * coalesce(v_shu.member_savings_pct, 0), 2);
  v_member_service  := round(v_shu.net_shu * coalesce(v_shu.member_service_pct, 0), 2);

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

  -- Dasim: proporsional SALDO SWB per 31-12 tahun SHU
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

  -- Dapin: proporsional jumlah SWK anggota tahun buku
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

-- ---------------------------------------------------------------
-- 3. app_settings — sinkronkan nilai tarif terbaru (upsert)
-- ---------------------------------------------------------------
insert into public.app_settings (key, value, description) values
  ('interest_rate_normal', '0.02', 'Bunga/jasa pinjaman angsur (2% x pokok, flat)'),
  ('interest_rate_fast',   '0.03', 'Bunga/jasa pinjaman cepat (3% x pokok, flat)'),
  ('admin_fee_rate',       '0.03', 'Biaya administrasi pinjaman (3% x pokok, semua jenis)'),
  ('japinup_ratio',        '1.10', 'Japinup (% pokok, pinjaman angsur; sisa pembulatan)'),
  ('fast_japinup_ratio',   '2.10', 'Japinup (% pokok, pinjaman cepat; sisa pembulatan)'),
  ('social_fund_ratio',    '0.05', 'Dana Sosial (fraksi dasar 2/3)'),
  ('education_fund_ratio', '0.05', 'Dana Pendidikan (fraksi dasar 2/3)'),
  ('crk_ratio',            '0.05', 'Dana CRK (fraksi dasar 2/3)'),
  ('development_fund_ratio','0.05','Dana Pembangunan (fraksi dasar 2/3)'),
  ('swk_ratio',            '0.20', 'SWK (fraksi dasar 2/3)'),
  ('welfare_fund_ratio',   '0.50', 'Dana Kesejahteraan (fraksi dasar 2/3)'),
  ('total_ratio_parts',    '2',    'Basis distribusi jasa angsur (total 2% pokok)'),
  ('fast_total_ratio_parts','3',   'Basis distribusi jasa cepat (total 3% pokok)')
on conflict (key) do update
  set value = excluded.value, description = excluded.description;

-- Hapus kunci usang (tidak lagi dipakai; model tidak dibedakan tenor)
delete from public.app_settings
 where key in ('interest_rate_short');

-- ---------------------------------------------------------------
-- 4. Backfill public.users dari auth.users (memperbaiki loans.created_by)
-- ---------------------------------------------------------------
insert into public.users (id, email, full_name, is_active, created_at)
select
  u.id,
  u.email,
  coalesce(u.raw_user_meta_data->>'full_name', split_part(u.email, '@', 1)),
  true,
  u.created_at
from auth.users u
on conflict (id) do nothing;