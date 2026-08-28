import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../anggota/domain/entities/member_entity.dart';
import '../../../simpanan/presentation/pages/savings_page.dart'
    show MemberSavingsTarget;
import '../../../pinjaman/presentation/pages/loans_page.dart'
    show MemberLoanTarget;
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _kasBank = 0;
  double _piutang = 0;
  double _stokKeripik = 0;
  bool _balanced = false;
  bool _loadingSummary = true;

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sadaya'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSummary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Selamat datang,', style: Theme.of(context).textTheme.bodyMedium),
            Text(email, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            // Summary indicators
            _loadingSummary
                ? const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _SummaryIndicators(
                    kasBank: _kasBank,
                    piutang: _piutang,
                    stokKeripik: _stokKeripik,
                    balanced: _balanced,
                  ),
            const SizedBox(height: 16),

            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
              children: [
                _MenuTile(
                  icon: Icons.group_outlined,
                  label: 'Anggota',
                  onTap: () => context.push('/anggota'),
                ),
                _MenuTile(
                  icon: Icons.savings_outlined,
                  label: 'Simpanan',
                  onTap: () => _openWithPickedMember(
                    context,
                    pickerTitle: 'Pilih Anggota — Simpanan',
                    onPicked: (member) => context.push(
                      '/simpanan/${member.id}',
                      extra: MemberSavingsTarget(
                        id: member.id,
                        name: member.name,
                        memberNumber: member.memberNumber,
                      ),
                    ),
                  ),
                ),
                _MenuTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Pinjaman',
                  onTap: () => _openWithPickedMember(
                    context,
                    pickerTitle: 'Pilih Anggota — Pinjaman',
                    onPicked: (member) => context.push(
                      '/pinjaman/${member.id}',
                      extra: MemberLoanTarget(
                        id: member.id,
                        name: member.name,
                        memberNumber: member.memberNumber,
                      ),
                    ),
                  ),
                ),
                _MenuTile(
                  icon: Icons.receipt_long_outlined,
                  label: 'Kas Umum',
                  onTap: () => context.push('/keuangan'),
                ),
                _MenuTile(
                  icon: Icons.volunteer_activism_outlined,
                  label: 'Dana & SHU',
                  onTap: () => context.push('/dana'),
                ),
                _MenuTile(
                  icon: Icons.inventory_2_outlined,
                  label: 'Aset',
                  onTap: () => context.push('/aset'),
                ),
                _MenuTile(
                  icon: Icons.cookie_outlined,
                  label: 'Usaha Keripik',
                  onTap: () => context.push('/usaha'),
                ),
                _MenuTile(
                  icon: Icons.receipt_outlined,
                  label: 'Pajak',
                  onTap: () => context.push('/pajak'),
                ),
                _MenuTile(
                  icon: Icons.account_balance_outlined,
                  label: 'Neraca',
                  onTap: () => context.push('/laporan/neraca'),
                ),
                const _MenuTile(
                  icon: Icons.settings_outlined,
                  label: 'Pengaturan',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openWithPickedMember(
    BuildContext context, {
    required String pickerTitle,
    required ValueChanged<MemberEntity> onPicked,
  }) async {
    final member = await context.push<MemberEntity>(
      '/pilih-anggota',
      extra: {'title': pickerTitle},
    );
    if (member != null && context.mounted) onPicked(member);
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.negativeRed),
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

class _SummaryIndicators extends StatelessWidget {
  const _SummaryIndicators({
    required this.kasBank,
    required this.piutang,
    required this.stokKeripik,
    required this.balanced,
  });

  final double kasBank;
  final double piutang;
  final double stokKeripik;
  final bool balanced;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.account_balance_wallet,
                label: 'Kas & Bank',
                value: AppFormatters.rupiah(kasBank),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                icon: Icons.request_quote,
                label: 'Piutang',
                value: AppFormatters.rupiah(piutang),
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.cookie_outlined,
                label: 'Stok Keripik',
                value: '${stokKeripik.toStringAsFixed(1)} kg',
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                icon: balanced ? Icons.check_circle : Icons.warning,
                label: 'Neraca',
                value: balanced ? 'Seimbang' : 'Tidak Seimbang',
                color: balanced ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: enabled
                    ? AppColors.primaryGreen
                    : Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: enabled
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
