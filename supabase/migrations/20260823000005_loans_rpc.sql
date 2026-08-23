-- =============================================================
-- Sadaya — Migrasi 05: RPC Pinjaman
-- 1) create_loan      : buat pinjaman + generate jadwal cicilan
--                       bulanan (flat) + jurnal pencairan
-- 2) pay_installment  : bayar cicilan + distribusi jasa ke 7 pos
--                       (20 bagian) + SWK otomatis + jurnal atomik
--
-- Aturan bisnis (RAB 2026):
--   Tenor 10-50 bulan -> bunga 2%/bulan; <10 bulan -> 3%/bulan
--   Administrasi pinjaman 3% (dipotong saat pencairan, TADP ditiadakan)
--   Distribusi jasa per pembayaran:
--     Japinup 55% (11/20), Dana Kesra 25% (5/20), SWK 10% (2/20),
--     Dana Sosial 2.5%, Dana Pendidikan 2.5%, Dana CRK 2.5%,
--     Dana Pembangunan 2.5%
--
-- COA: 1111 Kas, 1113 Pinjaman diberikan, 2113 Simp. Wajib Kredit,
--      2114 Dana Sosial, 2115 Dana Pendidikan, 2119 Dana Kesejahteraan,
--      3114 Dana Pembangunan, 3115 Dana CRK, 4111 Japinup, 4112 Adm.
-- =============================================================

-- Helper tahun buku dari tanggal
create or replace function public.v_year_of(d date)
returns integer language sql immutable as $$
  select extract(year from d)::integer
$$;

create or replace function public.create_loan(
  p_member_id uuid,
  p_principal numeric,
  p_tenor integer,
  p_disbursement_date date default current_date,
  p_notes text default null
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
  v_i integer;
  v_loan public.loans;
begin
  if auth.uid() is null then
    raise exception 'Tidak memiliki akses. Silakan login ulang';
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

  v_rate := case when p_tenor < 10 then 0.03 else 0.02 end;
  v_admin := round(p_principal * 0.03, 2);

  insert into public.loans (
    member_id, principal_amount, tenor, interest_rate, admin_fee_rate,
    admin_fee_amount, disbursement_date, remaining_balance, notes, created_by
  ) values (
    p_member_id, p_principal, p_tenor, v_rate, 0.03,
    v_admin, p_disbursement_date, p_principal, p_notes, auth.uid()
  )
  returning * into v_loan;

  -- Jadwal cicilan bulanan flat: pokok merata (cicilan terakhir menyerap
  -- sisa pembulatan), jasa tetap = pokok x rate per bulan.
  v_principal_per := round(p_principal / p_tenor, 2);
  v_interest_per := round(p_principal * v_rate, 2);

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
      v_interest_per,
      case when v_i = p_tenor
           then p_principal - v_principal_per * (p_tenor - 1) + v_interest_per
           else v_principal_per + v_interest_per end
    );
  end loop;

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
    round(v_i * 0.10, 2),
    coalesce(p_notes, 'Angsuran ke-' || v_sched.installment_number),
    auth.uid()
  )
  returning * into v_pay;

  -- Distribusi jasa (20 bagian); Japinup menyerap selisih pembulatan
  if v_i > 0 then
    v_swk := round(v_i * 0.10, 2);
    v_kesra := round(v_i * 0.25, 2);
    v_sosial := round(v_i * 0.025, 2);
    v_pendidikan := round(v_i * 0.025, 2);
    v_crk := round(v_i * 0.025, 2);
    v_pembangunan := round(v_i * 0.025, 2);
    v_japinup := v_i - (v_swk + v_kesra + v_sosial + v_pendidikan + v_crk + v_pembangunan);

    insert into public.interest_distributions (
      payment_id, distribution_date, total_interest, japinup_amount,
      social_fund_amount, education_fund_amount, crk_amount,
      development_fund_amount, swk_amount, welfare_fund_amount
    ) values (
      v_pay.id, current_date, v_i, v_japinup,
      v_sosial, v_pendidikan, v_crk,
      v_pembangunan, v_swk, v_kesra
    );

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

revoke execute on function public.create_loan(uuid, numeric, integer, date, text) from anon;
grant execute on function public.create_loan(uuid, numeric, integer, date, text) to authenticated;
revoke execute on function public.pay_installment(uuid, numeric, numeric, text) from anon;
grant execute on function public.pay_installment(uuid, numeric, numeric, text) to authenticated;
