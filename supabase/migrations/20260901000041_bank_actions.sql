-- =============================================================
-- Sadaya — Migrasi 41: Aksi khusus Buku Bank
--  1) bank_dana_masuk : dana masuk ke rekening dari luar
--                       (investor/dll), TANPA kategori.
--                       Jurnal: Debit 1112 Bank / Kredit 3117 Modal Penyertaan
--  2) bank_cair_ke_kas: tarik tunai dari rekening ke kas.
--                       Jurnal: Debit 1111 Kas / Kredit 1112 Bank
--                       + validasi sisa saldo bank tidak minus.
--
-- Keduanya memakai create_cash_book_transaction yang sudah ada
-- (migration 00006) untuk autoposting jurnal 2 baris.
-- =============================================================

-- ---------- 1) Dana masuk ke bank -----------------------------
create or replace function public.bank_dana_masuk(
  p_amount numeric,
  p_description text,
  p_date date default current_date
)
returns uuid
language plpgsql
set search_path = public
as $$
begin
  return public.create_cash_book_transaction(
    p_book            => 'bank',
    p_direction       => 'in',
    p_counter_account => '3117',
    p_amount          => p_amount,
    p_description     => p_description,
    p_date            => p_date
  );
end;
$$;

-- ---------- 2) Cairkan dari bank ke kas -----------------------
create or replace function public.bank_cair_ke_kas(
  p_amount numeric,
  p_description text,
  p_date date default current_date
)
returns uuid
language plpgsql
set search_path = public
as $$
declare
  v_bank_balance numeric;
begin
  -- Jumlah uang di rekening = seluruh pemasukan Bank (debit 1112)
  -- dikurangi penarikan (kredit 1112) yang belum dibatalkan.
  select coalesce(sum(le.debit_amount - le.credit_amount), 0)
  into v_bank_balance
  from public.ledger_entries le
  where le.account_code = '1112'
    and le.is_void = false;

  if p_amount is null or p_amount <= 0 then
    raise exception 'Nominal harus lebih dari 0';
  end if;

  if v_bank_balance < p_amount then
    raise exception 'Saldo bank tidak mencukupi (sisa %.2f)', v_bank_balance;
  end if;

  return public.create_cash_book_transaction(
    p_book            => 'bank',
    p_direction       => 'out',
    p_counter_account => '1111',
    p_amount          => p_amount,
    p_description     => p_description,
    p_date            => p_date
  );
end;
$$;

revoke all on function public.bank_dana_masuk(numeric, text, date) from public, anon;
revoke all on function public.bank_cair_ke_kas(numeric, text, date) from public, anon;
grant execute on function public.bank_dana_masuk(numeric, text, date) to authenticated;
grant execute on function public.bank_cair_ke_kas(numeric, text, date) to authenticated;