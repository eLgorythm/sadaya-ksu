import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../anggota/domain/entities/member_entity.dart';
import '../../../simpanan/presentation/pages/savings_page.dart'
    show MemberSavingsTarget;
import '../../../pinjaman/presentation/pages/loans_page.dart'
    show MemberLoanTarget;
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Selamat datang,', style: Theme.of(context).textTheme.bodyMedium),
          Text(email, style: Theme.of(context).textTheme.titleLarge),
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
              const _MenuTile(
                icon: Icons.receipt_long_outlined,
                label: 'Kas Umum',
              ),
              const _MenuTile(
                icon: Icons.insights_outlined,
                label: 'Keuangan',
              ),
              const _MenuTile(
                icon: Icons.settings_outlined,
                label: 'Pengaturan',
              ),
            ],
          ),
        ],
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
