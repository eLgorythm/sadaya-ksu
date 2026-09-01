-- =============================================================
-- Sadaya — Migrasi 26: Key tambahan untuk halaman Tentang (About)
-- app_name & app_developer (migrasi 00025 sudah ter-push sebelum
-- dua key ini ditambah). Idempotent: UPSERT on conflict (key).
-- =============================================================
insert into public.app_settings (key, value, description) values
  ('app_name',      'Sadaya', 'Nama aplikasi'),
  ('app_developer', 'Elfan Dwi Saputra', 'Pengembang aplikasi')
on conflict (key) do update
  set value = excluded.value, description = excluded.description;