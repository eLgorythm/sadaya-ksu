import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../anggota/domain/entities/member_entity.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../pinjaman/presentation/pages/loans_page.dart'
    show MemberLoanTarget;
import '../../../simpanan/presentation/pages/savings_page.dart'
    show MemberSavingsTarget;
import '../../data/modules_data.dart';

/// Halaman Beranda (tab pertama MainShellPage).
///
/// Menampilkan hero financial card real-time, aksi cepat transaksi, dan
/// grid 15 modul koperasi yang bisa difilter per kategori.
class HomePage extends StatefulWidget {
  const HomePage({super.key, this.onOpenNeraca});

  /// Dipanggil saat user membuka modul "Komposisi Keuangan" (alih tab Neraca).
  final VoidCallback? onOpenNeraca;

  /// Bottom sheet aksi cepat dari tombol [MainShellPage] (FAB Input).
  static Future<void> openQuickActions(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (_) => const _QuickActionsSheet(),
    );
  }

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _kasBank = 0;
  double _piutang = 0;
  double _ekuitas = 0;
  double _stokKeripik = 0;
  bool _balanced = false;
  bool _loadingSummary = true;
  ModuleCategory _selectedCategory = ModuleCategory.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSummary());
  }

  Future<void> _loadSummary() async {
    try {
      final result = await GetIt.I<SupabaseClient>()
          .rpc('get_dashboard_summary');
      if (result != null && mounted) {
        final data = result as Map<String, dynamic>;
        setState(() {
          _kasBank = (data['kas_bank'] as num?)?.toDouble() ?? 0;
          _piutang = (data['piutang'] as num?)?.toDouble() ?? 0;
          _ekuitas = (data['ekuitas'] as num?)?.toDouble() ?? 0;
          _stokKeripik = (data['stok_keripik'] as num?)?.toDouble() ?? 0;
          _balanced = data['balanced'] as bool? ?? false;
          _loadingSummary = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSummary = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthCubit>().state;
    final email = switch (state) {
      AuthAuthenticated(:final user) => user.email,
      _ => '-',
    };

    final filtered = _selectedCategory == ModuleCategory.all
        ? kModules
        : kModules
            .where((m) => m.category == _selectedCategory)
            .toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.brand800,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.brand500, width: 2),
              ),
              child: const Center(
                child: Text(
                  'SD',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sadaya',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    email,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Notifikasi',
              onPressed: () {},
              icon: Stack(
                children: [
                  Icon(Icons.notifications_none, color: Colors.grey[700]),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Keluar',
            onPressed: () => _confirmSignOut(context),
            icon: Icon(Icons.logout, color: Colors.grey[700]),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSummary,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            Text(
              'KSU Cahaya Dhamma Phala',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.brand700,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
            ),
            const SizedBox(height: 12),

            // Hero financial card
            if (_loadingSummary)
              const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              )
            else
              _HeroCard(
                kasBank: _kasBank,
                piutang: _piutang,
                ekuitas: _ekuitas,
                stokKeripik: _stokKeripik,
                balanced: _balanced,
              ),
            const SizedBox(height: 16),

            // Quick actions
            Text(
              'Aksi Cepat Transaksi',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: 8),
            const _QuickActionsRow(),
            const SizedBox(height: 16),

            // Module grid header
            Row(
              children: [
                Text(
                  '15 Modul Koperasi',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                ),
                const Spacer(),
                Text(
                  'Terhubung ke Neraca',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brand600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Filter tabs
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ModuleCategory.values.map((cat) {
                  final selected = cat == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(
                        '${cat.label} (${_countFor(cat)})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                      selected: selected,
                      selectedColor: AppColors.brand800,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade200),
                      onSelected: (_) =>
                          setState(() => _selectedCategory = cat),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),

            // Module grid
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.05,
              children: filtered
                  .map((m) => _ModuleCard(
                        item: m,
                        onTap: () => _handleModuleTap(context, m),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  int _countFor(ModuleCategory cat) =>
      cat == ModuleCategory.all ? kModules.length : kModules.where((m) => m.category == cat).length;

  void _handleModuleTap(BuildContext context, ModuleItem m) {
    switch (m.id) {
      case 'kas' || 'bank':
        context.push('/keuangan');
      case 'pajak':
        context.push('/pajak');
      case 'neraca':
        widget.onOpenNeraca?.call();
      case 'shu' || 'dansos' || 'danpend' || 'dankes':
        context.push('/dana');
      case 'inventaris' || 'penyusutan':
        context.push('/aset');
      case 'keripik':
        context.push('/usaha');
      case 'pokok' || 'wajib' || 'manasuka':
        _openMemberPickerAndGo(context, 'Simpanan');
      case 'pinjaman':
        _openMemberPickerAndGo(context, 'Pinjaman');
      default:
        break;
    }
  }

  /// Buka pemilih anggota lalu lanjut ke halaman simpanan/pinjaman anggota
  /// setelah anggota dipilih.
  Future<void> _openMemberPickerAndGo(BuildContext context, String mode) async {
    final title = mode == 'Pinjaman'
        ? 'Pilih Anggota — Pinjaman'
        : 'Pilih Anggota — Simpanan';
    final member = await context.push<MemberEntity>(
      '/pilih-anggota',
      extra: {'title': title},
    );
    if (member == null || !context.mounted) return;
    if (mode == 'Pinjaman') {
      context.push(
        '/pinjaman/${member.id}',
        extra: MemberLoanTarget(
          id: member.id,
          name: member.name,
          memberNumber: member.memberNumber,
        ),
      );
    } else {
      context.push(
        '/simpanan/${member.id}',
        extra: MemberSavingsTarget(
          id: member.id,
          name: member.name,
          memberNumber: member.memberNumber,
        ),
      );
    }
  }

  void _confirmSignOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.negativeRed),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthCubit>().signOut();
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

/// Hero financial card (Laporan Neraca Real-Time).
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.kasBank,
    required this.piutang,
    required this.ekuitas,
    required this.stokKeripik,
    required this.balanced,
  });

  final double kasBank;
  final double piutang;
  final double ekuitas;
  final double stokKeripik;
  final bool balanced;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brand900,
            AppColors.brand800,
            Color(0xFF0F172A),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand900.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.brand700.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.brand500.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'LAPORAN NERACA REAL-TIME',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: AppColors.brand100,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      balanced ? Icons.check_circle : Icons.warning,
                      size: 10,
                      color: balanced ? Colors.lightGreenAccent : Colors.amber,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      balanced ? 'Balanced' : 'Tidak Seimbang',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: balanced
                            ? Colors.lightGreenAccent
                            : Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Total Kas & Aset Lancar',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.brand100,
            ),
          ),
          Text(
            AppFormatters.rupiah(kasBank),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Piutang Pinjaman',
                  value: AppFormatters.rupiah(piutang),
                ),
              ),
              Expanded(
                child: _HeroMetric(
                  label: 'Total Ekuitas/Modal',
                  value: AppFormatters.rupiah(ekuitas),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Stok Keripik',
                  value: '${stokKeripik.toStringAsFixed(1)} kg',
                ),
              ),
              Expanded(
                child: _HeroMetric(
                  label: 'Status Neraca',
                  value: balanced ? 'Seimbang' : 'Selisih',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: AppColors.brand100,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Deret 4 tombol aksi cepat.
class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickAction(
          icon: Icons.savings_outlined,
          label: 'Setor\nSimpanan',
          bg: AppColors.brand50,
          fg: AppColors.brand600,
          onTap: () async {
            final member = await context.push<MemberEntity>(
              '/pilih-anggota',
              extra: {'title': 'Pilih Anggota — Simpanan'},
            );
            if (member != null && context.mounted) {
              context.push(
                '/simpanan/${member.id}',
                extra: MemberSavingsTarget(
                  id: member.id,
                  name: member.name,
                  memberNumber: member.memberNumber,
                ),
              );
            }
          },
        ),
        const SizedBox(width: 8),
        _QuickAction(
          icon: Icons.wallet_outlined,
          label: 'Cairkan\nPinjaman',
          bg: const Color(0xFFEFF6FF),
          fg: const Color(0xFF2563EB),
          onTap: () async {
            final member = await context.push<MemberEntity>(
              '/pilih-anggota',
              extra: {'title': 'Pilih Anggota — Pinjaman'},
            );
            if (member != null && context.mounted) {
              context.push(
                '/pinjaman/${member.id}',
                extra: MemberLoanTarget(
                  id: member.id,
                  name: member.name,
                  memberNumber: member.memberNumber,
                ),
              );
            }
          },
        ),
        const SizedBox(width: 8),
        _QuickAction(
          icon: Icons.cookie_outlined,
          label: 'POS\nKeripik',
          bg: const Color(0xFFFFFBEB),
          fg: const Color(0xFFD97706),
          onTap: () => context.push('/usaha'),
        ),
        const SizedBox(width: 8),
        _QuickAction(
          icon: Icons.receipt_long_outlined,
          label: 'Kas\nUmum',
          bg: const Color(0xFFFAF5FF),
          fg: const Color(0xFF9333EA),
          onTap: () => context.push('/keuangan'),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: fg),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu modul di grid 15 modul.
class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.item, required this.onTap});

  final ModuleItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  item.icon,
                  size: 16,
                  color: AppColors.brand700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                item.description,
                style: TextStyle(fontSize: 9, color: Colors.grey[400]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet aksi cepat (dibuka dari FAB Input bottom nav).
class _QuickActionsSheet extends StatelessWidget {
  const _QuickActionsSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pilih Modul Transaksi',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const _QuickActionsRow(),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }
}