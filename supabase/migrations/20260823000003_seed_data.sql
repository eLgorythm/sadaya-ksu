-- =============================================================
-- Sadaya — Seed Data
-- Chart of accounts, jenis simpanan, kategori transaksi,
-- konfigurasi default, tahun buku 2026.
-- =============================================================

insert into public.chart_of_accounts (code, name, account_type) values
  ('1111', 'Kas', 'asset'),
  ('1112', 'Simpanan Di Bank', 'asset'),
  ('1113', 'Pinjaman yang diberikan', 'asset'),
  ('1121', 'Rumah Produksi', 'asset'),
  ('1122', 'Freezer', 'asset'),
  ('1123', 'Dastang', 'asset'),
  ('1124', 'Vacuum Frying', 'asset'),
  ('1125', 'Tabung Gas', 'asset'),
  ('1126', 'Gerabah', 'asset'),
  ('1131', 'Printer', 'asset'),
  ('2111', 'Simpanan Manasuka', 'liability'),
  ('2112', 'Tab. Anggota dari Pinjaman (TADP)', 'liability'),
  ('2113', 'Simpanan Wajib Kredit', 'liability'),
  ('2114', 'Dana Sosial', 'liability'),
  ('2115', 'Dana Pendidikan', 'liability'),
  ('2116', 'Penyisihan Biaya RAT', 'liability'),
  ('2117', 'Penyisihan Jasa SM', 'liability'),
  ('2118', 'Penyisihan Lain-lain', 'liability'),
  ('2119', 'Dana Kesejahteraan Anggota', 'liability'),
  ('2120', 'Dana-dana Untuk Anggota', 'liability'),
  ('2121', 'Dana-dana Untuk Pengurus/Pengawas/Karyawan', 'liability'),
  ('3111', 'Modal Tetap', 'equity'),
  ('3112', 'Simpanan Pokok', 'equity'),
  ('3113', 'Simpanan Wajib', 'equity'),
  ('3114', 'Dana Pembangunan', 'equity'),
  ('3115', 'Dana Cadangan Resiko Kredit', 'equity'),
  ('3116', 'Dana Cadangan', 'equity'),
  ('3117', 'Modal Penyertaan', 'equity'),
  ('3118', 'Sisa Hasil Usaha', 'equity'),
  ('4111', 'Jasa Pinjaman untuk Penghasilan (Japinup)', 'revenue'),
  ('4112', 'Administrasi dari pinjaman', 'revenue'),
  ('4113', 'Jasa Bank', 'revenue'),
  ('4114', 'Pendapatan Usaha Kopi', 'revenue'),
  ('4115', 'Pendapatan Keripik Kentang', 'revenue'),
  ('4116', 'Pendapatan Keripik Salak', 'revenue'),
  ('5111', 'Biaya Rapat Pengurus Rutin', 'expense'),
  ('5112', 'Biaya Rapat Pengawas', 'expense'),
  ('5113', 'Biaya Rapat Gabungan', 'expense'),
  ('5114', 'Biaya Lembur Pengurus', 'expense'),
  ('5115', 'Sarana Administrasi (ATK)', 'expense'),
  ('5116', 'Biaya Pembinaan dan Transportasi', 'expense'),
  ('5117', 'Jasa Simpanan Manasuka', 'expense'),
  ('5118', 'Penyusunan Laporan', 'expense'),
  ('5119', 'Konsumsi RAT', 'expense'),
  ('5120', 'Uang Sidang', 'expense'),
  ('5121', 'Akomodasi RAT', 'expense'),
  ('5122', 'Dekorasi RAT', 'expense'),
  ('5123', 'Dokumentasi RAT', 'expense')
on conflict (code) do nothing;

insert into public.savings_types (code, name, interest_rate, is_withdrawable, is_system_managed) values
  ('SP',  'Simpanan Pokok',            0.0000, false, false),
  ('SWB', 'Simpanan Wajib Bulanan',    0.0000, false, false),
  ('SMS', 'Simpanan Mana Suka',        0.0030, true,  false),
  ('SWK', 'Simpanan Wajib Kredit',     0.0000, false, true)
on conflict (code) do nothing;

insert into public.transaction_categories (code, name, category_type, parent_category) values
  ('4111', 'Jasa Pinjaman untuk Penghasilan (Japinup)', 'income', null),
  ('4112', 'Administrasi dari pinjaman',                'income', null),
  ('4113', 'Jasa Bank',                                 'income', null),
  ('4114', 'Pendapatan Usaha Kopi',                     'income', null),
  ('4115', 'Pendapatan Keripik Kentang',                'income', null),
  ('4116', 'Pendapatan Keripik Salak',                  'income', null),
  ('5111', 'Biaya Rapat Pengurus Rutin',      'expense', 'rapat'),
  ('5112', 'Biaya Rapat Pengawas',            'expense', 'rapat'),
  ('5113', 'Biaya Rapat Gabungan',            'expense', 'rapat'),
  ('5114', 'Biaya Lembur Pengurus',           'expense', 'lembur_atk'),
  ('5115', 'Sarana Administrasi (ATK)',       'expense', 'lembur_atk'),
  ('5116', 'Biaya Pembinaan dan Transportasi','expense', 'pembinaan'),
  ('5117', 'Jasa Simpanan Manasuka',          'expense', 'jasa_rat'),
  ('5118', 'Penyusunan Laporan',              'expense', 'jasa_rat'),
  ('5119', 'Konsumsi RAT',                    'expense', 'jasa_rat'),
  ('5120', 'Uang Sidang',                     'expense', 'jasa_rat'),
  ('5121', 'Akomodasi RAT',                   'expense', 'jasa_rat'),
  ('5122', 'Dekorasi RAT',                    'expense', 'jasa_rat'),
  ('5123', 'Dokumentasi RAT',                 'expense', 'jasa_rat')
on conflict (code) do nothing;

insert into public.app_settings (key, value, description) values
  ('koperasi_name',          'Cahaya Dhamma Phala', 'Nama koperasi'),
  ('interest_rate_normal',   '0.02',   'Bunga/jasa pinjaman angsur (2% x pokok, flat)'),
  ('interest_rate_fast',     '0.03',   'Bunga/jasa pinjaman cepat (3% x pokok, flat)'),
  ('admin_fee_rate',         '0.03',   'Biaya administrasi pinjaman (3% x pokok, semua jenis)'),
  ('sms_interest_rate',      '0.003',  'Jasa simpanan mana suka per bulan'),
  ('min_swb_amount',         '20000',  'Simpanan wajib bulanan minimum'),
  ('sp_amount',              '100000', 'Simpanan pokok saat mendaftar'),
  ('japinup_ratio',          '1.10',   'Japinup (% pokok, pinjaman angsur; sisa pembulatan)'),
  ('social_fund_ratio',      '0.05',   'Dana Sosial (% pokok, semua jenis)'),
  ('education_fund_ratio',   '0.05',   'Dana Pendidikan (% pokok, semua jenis)'),
  ('crk_ratio',              '0.05',   'Dana CRK (% pokok, semua jenis)'),
  ('development_fund_ratio', '0.05',   'Dana Pembangunan (% pokok, semua jenis)'),
  ('swk_ratio',              '0.20',   'SWK (% pokok, semua jenis)'),
  ('welfare_fund_ratio',     '0.50',   'Dana Kesejahteraan (% pokok, semua jenis)'),
  ('fast_japinup_ratio',     '2.10',   'Japinup (% pokok, pinjaman cepat; sisa pembulatan)'),
  ('total_ratio_parts',      '2',      'Basis distribusi jasa angsur (total 2% pokok)'),
  ('fast_total_ratio_parts', '3',      'Basis distribusi jasa cepat (total 3% pokok)'),
  ('bantuan_sakit',          '300000', 'Bantuan sakit/opname (1x per tahun)'),
  ('bantuan_melahirkan',     '400000', 'Bantuan melahirkan'),
  ('bantuan_meninggal',      '500000', 'Bantuan meninggal dunia'),
  ('crk_max',                '500000', 'CRK maksimal saat peminjam meninggal'),
  ('tax_rate_pph21',         '0.10',   'PPh 21 atas SHU')
on conflict (key) do nothing;

insert into public.fiscal_years (year, start_date, end_date, is_active, is_closed)
values (2026, '2026-01-01', '2026-12-31', true, false)
on conflict (year) do nothing;
