-- =============================================================
-- Sadaya — Migrasi 44: Koreksi bunga pinjaman (per angsuran)
--
-- Sebelumnya (migrasi 05): bunga dihitung SEKALI dari total pokok.
--   2% x pokok dibagi rata per bulan utk angsur; 3% x pokok utk cepat.
--   Contoh 10jt/tenor10: bunga/angsuran 20rb, total 200rb.
--
-- Koreksi (RAB + arahan pengurus):
--   Bunga/jasa = PER ANGSURAN (flat dari pokok):
--     Pinjaman angsur (regular) = 2% x pokok PER ANGSURAN
--       10jt / tenor 10 -> 200rb per angsuran, total bunga 2jt (2% x pokok x tenor)
--     Pinjaman cepat (fast)     = 3% x pokok x tenor (dibayar sekali di akhir tenor)
--   Admin = 3% x pokok (30rb/1jt) dipotong saat pencairan utk SEMUA jenis.
--   Distribusi jasa per pembayaran tidak berubah (fraksi tetap):
--     Reguler (dasar 2,00): Japinup 1,10/2, Kesra 0,50/2, SWK 0,20/2,
--       Sosial 0,05/2, Pendidikan 0,05/2, CRK 0,05/2, Pembangunan 0,05/2
--     Cepat (dasar 3,00): Japinup 2,10/3, Kesra 0,50/3, SWK 0,20/3,
--       Sosial 0,05/3, Pendidikan 0,05/3, CRK 0,05/3, Pembangunan 0,05/3
-- =============================================================

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

  -- Bunga/jasa = PER ANGSURAN (flat dari pokok).
  --   Pinjaman angsur (regular) = 2% x pokok per angsuran
  --     -> total = 2% x pokok x tenor (contoh 10jt/tenor10: 200rb/angsuran, total 2jt)
  --   Pinjaman cepat (fast)     = 3% x pokok x tenor (dibayar sekali di akhir tenor)
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
    -- tenor, pokok full + total bunga 3% x pokok x tenor (bukan per bulan).
    v_total_interest := round(p_principal * v_rate * p_tenor, 2);
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
    -- menyerap sisa pembulatan). Bunga = 2% x pokok PER ANGSURAN
    -- (contoh 10jt -> 200rb/angsuran). Total = 2% x pokok x tenor.
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
        case when v_i = p_tenor
             then round(p_principal * v_rate * p_tenor, 2) - v_interest_per * (p_tenor - 1)
             else v_interest_per end,
        case when v_i = p_tenor
             then p_principal - v_principal_per * (p_tenor - 1)
                  + round(p_principal * v_rate * p_tenor, 2) - v_interest_per * (p_tenor - 1)
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

revoke execute on function public.create_loan(uuid, numeric, integer, date, text, text) from anon;
grant execute on function public.create_loan(uuid, numeric, integer, date, text, text) to authenticated;