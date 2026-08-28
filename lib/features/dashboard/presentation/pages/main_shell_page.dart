import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../anggota/domain/entities/member_entity.dart';
import '../../../laporan/presentation/pages/balance_sheet_page.dart';
import '../../../pinjaman/presentation/pages/loans_page.dart'
    show MemberLoanTarget;
import '../../../simpanan/presentation/pages/savings_page.dart'
    show MemberSavingsTarget;
import '../pages/home_page.dart';

/// Cangkang utama aplikasi setelah login.
///
/// Bottom navigation: Beranda | Neraca | [Input] | Pengaturan. Tombol tengah
/// (Input) membuka bottom sheet aksi cepat transaksi.
class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _index = 0;

  void _switchToNeraca() => setState(() => _index = 1);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onOpenNeraca: _switchToNeraca),
      const BalanceSheetPage(),
      const _SettingsPage(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: _BottomNav(
        index: _index,
        onTap: (i) => setState(() => _index = i),
        onInputTap: () {
          if (_index == 0) {
            HomePage.openQuickActions(context);
          } else {
            setState(() => _index = 0);
          }
        },
      ),
    );
  }
}

/// Bar navigasi bawah (desain redesign): Beranda, Neraca, [FAB Input], Pengaturan.
class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.index,
    required this.onTap,
    required this.onInputTap,
  });

  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onInputTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Beranda',
                active: index == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart,
                label: 'Neraca',
                active: index == 1,
                onTap: () => onTap(1),
              ),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: onInputTap,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: AppColors.brand600,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brand600,
                            blurRadius: 12,
                            spreadRadius: 0,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: 'Pengaturan',
                active: index == 2,
                onTap: () => onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? activeIcon : icon,
              size: 22,
              color: active ? AppColors.brand700 : Colors.grey.shade500,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? AppColors.brand700 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  void _go(BuildContext context, String route) => context.push(route);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.brand800,
                child: const Text(
                  'CDP',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              title: const Text('KSU Cahaya Dhamma Phala'),
              subtitle: const Text('Sadaya — Sistem Informasi Koperasi'),
            ),
          ),
          const SizedBox(height: 8),
          _SettingTile(
            icon: Icons.group_outlined,
            label: 'Anggota',
            onTap: () => _go(context, '/anggota'),
          ),
          _SettingTile(
            icon: Icons.person_add_alt_1_outlined,
            label: 'Pilih Anggota',
            onTap: () => _go(context, '/pilih-anggota'),
          ),
          _SettingTile(
            icon: Icons.calculate_outlined,
            label: 'Buka Pinjaman Anggota',
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
          _SettingTile(
            icon: Icons.savings_outlined,
            label: 'Buka Simpanan Anggota',
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
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.brand700),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}