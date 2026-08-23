-- =============================================================
-- Sadaya — Migrasi 04: RPC Simpanan (transaksi + auto-posting ledger)
-- Setiap transaksi simpanan otomatis membuat 2 baris jurnal
-- (debit & kredit) dalam SATU transaksi database (atomik).
--
-- Pemetaan COA:
--   Setoran  : Debit  1111 Kas / Kredit akun simpanan
--   Penarikan: Debit akun simpanan / Kredit 1111 Kas
--   SP -> 3112 (Simpanan Pokok, ekuitas)
--   SWB -> 3113 (Simpanan Wajib, ekuitas)
--   SMS -> 2111 (Simpanan Mana Suka, liabilitas)
--   SWK -> 2113 (Simpanan Wajib Kredit, liabilitas)
-- =============================================================

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
