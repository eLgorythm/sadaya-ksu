-- =============================================================
-- Sadaya — Migrasi 25: Data identitas untuk halaman Tentang (About)
-- Dibaca aplikasi dari app_settings agar bisa diubah pengurus
-- tanpa release. Idempotent: UPSERT on conflict (key).
-- =============================================================
insert into public.app_settings (key, value, description) values
  ('app_tagline',   'Sadaya — Sistem Informasi Koperasi', 'Tagline aplikasi'),
  ('app_motto',     '"Bersama dalam Cahaya, Tumbuh dalam Kebajikan"', 'Moto koperasi'),
  ('app_description',
   '"Sadaya" berasal dari bahasa Sunda "sadayana" yang berarti semua/bersama. '
   'Dimaknai sebagai wujud nyata dari Dana Paramita — kesempurnaan berbagi '
   'dalam ajaran Dhamma. Koperasi adalah tempat di mana kebajikan '
   'dipraktikkan bersama: setiap anggota saling menopang, hasil usaha '
   'dinikmati bersama, seperti Sangha yang tumbuh dalam cahaya kebenaran; '
   'selaras dengan nilai yang menerangi Koperasi Cahaya Dhamma Phala.',
   'Deskripsi/filosofi nama aplikasi')
on conflict (key) do update
  set value = excluded.value, description = excluded.description;