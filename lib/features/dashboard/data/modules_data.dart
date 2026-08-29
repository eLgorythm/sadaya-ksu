import 'package:flutter/material.dart';

/// Kategori filter tab 15 modul di dashboard.
enum ModuleCategory {
  all('all', 'Semua'),
  utama('utama', 'Utama & Kas'),
  simpanan('simpanan', 'Simpan Pinjam'),
  dana('dana', 'Dana & SHU'),
  aset('aset', 'Aset & Usaha');

  const ModuleCategory(this.id, this.label);

  final String id;
  final String label;
}

/// Satu kartu modul di dashboard (15 modul koperasi).
class ModuleItem {
  const ModuleItem({
    required this.id,
    required this.title,
    required this.category,
    required this.icon,
    required this.description,
    this.postsToLedger = true,
  });

  final String id;
  final String title;
  final ModuleCategory category;
  final IconData icon;
  final String description;

  /// Apakah modul mem-posting jurnal ke buku besar (terhubung ke Neraca).
  /// Modul laporan (neraca) tidak mem-posting.
  final bool postsToLedger;
}

/// Daftar 15 modul master sesuai dokumen redesign.
const List<ModuleItem> kModules = [
  ModuleItem(
    id: 'kas',
    title: 'Buku Kas',
    category: ModuleCategory.utama,
    icon: Icons.receipt_long_outlined,
    description: 'Arus uang tunai',
  ),
  ModuleItem(
    id: 'bank',
    title: 'Buku Bank',
    category: ModuleCategory.utama,
    icon: Icons.account_balance_outlined,
    description: 'Rekening bank',
  ),
  ModuleItem(
    id: 'pajak',
    title: 'Buku Pajak',
    category: ModuleCategory.utama,
    icon: Icons.request_quote_outlined,
    description: 'PPh & PPN',
  ),
  ModuleItem(
    id: 'pokok',
    title: 'Simpanan Pokok',
    category: ModuleCategory.simpanan,
    icon: Icons.shield_outlined,
    description: 'Modal awal anggota',
  ),
  ModuleItem(
    id: 'wajib',
    title: 'Simpanan Wajib',
    category: ModuleCategory.simpanan,
    icon: Icons.savings_outlined,
    description: 'Iuran berkala',
  ),
  ModuleItem(
    id: 'manasuka',
    title: 'Simpanan Mana Suka',
    category: ModuleCategory.simpanan,
    icon: Icons.wallet_outlined,
    description: 'Tabungan sukarela',
  ),
  ModuleItem(
    id: 'pinjaman',
    title: 'Pinjaman Anggota',
    category: ModuleCategory.simpanan,
    icon: Icons.handshake_outlined,
    description: 'Piutang & angsuran',
  ),
  ModuleItem(
    id: 'shu',
    title: 'Penerimaan SHU',
    category: ModuleCategory.dana,
    icon: Icons.pie_chart_outline,
    description: 'Hasil usaha berjalan',
  ),
  ModuleItem(
    id: 'dansos',
    title: 'Dana Sosial',
    category: ModuleCategory.dana,
    icon: Icons.volunteer_activism_outlined,
    description: 'Cadangan kegiatan sosial',
  ),
  ModuleItem(
    id: 'danpend',
    title: 'Dana Pendidikan',
    category: ModuleCategory.dana,
    icon: Icons.school_outlined,
    description: 'Pelatihan & SDM',
  ),
  ModuleItem(
    id: 'dankes',
    title: 'Dana Kesejahteraan',
    category: ModuleCategory.dana,
    icon: Icons.favorite_outline,
    description: 'Manfaat anggota',
  ),
  ModuleItem(
    id: 'neraca',
    title: 'Komposisi Keuangan',
    category: ModuleCategory.utama,
    icon: Icons.bar_chart,
    description: 'Laporan Neraca Realtime',
    postsToLedger: false,
  ),
  ModuleItem(
    id: 'inventaris',
    title: 'Buku Inventaris',
    category: ModuleCategory.aset,
    icon: Icons.inventory_2_outlined,
    description: 'Aset tetap fisik',
  ),
  ModuleItem(
    id: 'penyusutan',
    title: 'Penyusutan Aset',
    category: ModuleCategory.aset,
    icon: Icons.trending_down,
    description: 'Depresiasi periodik',
  ),
  ModuleItem(
    id: 'keripik',
    title: 'Unit Keripik',
    category: ModuleCategory.aset,
    icon: Icons.cookie_outlined,
    description: 'POS & Stok Keripik',
  ),
];