-- =============================================================
-- ITERASI 11 — Produksi & Penjualan Multi-Satuan
-- Produksi: kolom baru quantity_pack (hasil packing, opsional,
-- terpisah dari quantity_produced yang ber-satuan bebas).
-- Penjualan: kolom baru unit ('kg' | 'pack') agar harga mengikuti
-- satuan jual. Data lama otomatis 'kg'.
-- =============================================================

alter table public.chip_productions
  add column if not exists quantity_pack numeric;

alter table public.chip_sales
  add column if not exists unit text not null default 'kg';
