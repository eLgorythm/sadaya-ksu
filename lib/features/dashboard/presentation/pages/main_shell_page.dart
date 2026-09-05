import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/responsive/responsive_context.dart';
import '../../../../core/responsive/responsive_scaffold.dart';
import '../../../anggota/domain/entities/member_entity.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../laporan/presentation/pages/balance_sheet_page.dart';
import '../../../pinjaman/presentation/pages/loans_page.dart'
    show MemberLoanTarget;
import '../../../simpanan/presentation/pages/savings_page.dart'
    show MemberSavingsTarget;
import '../pages/home_page.dart';

/// Cangkang utama aplikasi setelah login.
///
/// Navigasi adaptif:
/// - Desktop (>= 1024, Windows): [NavigationRail] kiri.
/// - Mobile: bottom navigation standar dengan tombol tengah [Input].
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
    final isDesktop = context.isDesktop;
    final pages = [
      HomePage(onOpenNeraca: _switchToNeraca),
      const BalanceSheetPage(),
      const _SettingsPage(),
    ];

    if (isDesktop) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Row(
          children: [
            _RailNav(
              index: _index,
              onSelect: (i) => setState(() => _index = i == 4 ? 2 : i),
              onInputTap: () {
                if (_index == 0) {
                  HomePage.openQuickActions(context);
                } else {
                  setState(() => _index = 0);
                }
              },
              onBukuBesarTap: () => context.push('/laporan/bukubesar'),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: IndexedStack(index: _index, children: pages),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: IndexedStack(index: _index, children: pages),
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
        onBukuBesarTap: () => context.push('/laporan/bukubesar'),
      ),
    );
  }
}

/// Navigation rail untuk desktop/Windows (>= 1024).
///
/// Beranda dan Neraca adalah destinasinya; Input dan Buku Besar bertindak
/// sebagai aksi (tidak pernah tampil terpilih).
class _RailNav extends StatelessWidget {
  const _RailNav({
    required this.index,
    required this.onSelect,
    required this.onInputTap,
    required this.onBukuBesarTap,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onInputTap;
  final VoidCallback onBukuBesarTap;

  @override
  Widget build(BuildContext context) {
    final labelType = context.screenWidth >= 1400
        ? NavigationRailLabelType.all
        : NavigationRailLabelType.none;
    return NavigationRail(
      extended: context.screenWidth >= 1400,
      backgroundColor: Colors.white,
      selectedIndex: index,
      labelType: labelType,
      onDestinationSelected: (i) {
        if (i == 2) {
          onInputTap();
        } else if (i == 3) {
          onBukuBesarTap();
        } else {
          onSelect(i);
        }
      },
      destinations: [
        const NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Beranda'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: Text('Neraca'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.add_circle_outline, color: AppColors.brand600),
          selectedIcon: Icon(Icons.add_circle, color: AppColors.brand600),
          label: Text('Input'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book),
          label: Text('Buku Besar'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Pengaturan'),
        ),
      ],
    );
  }
}

/// Bar navigasi bawah (desain redesign): Beranda, Neraca, [FAB Input],
/// Buku Besar, Pengaturan.
class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.index,
    required this.onTap,
    required this.onInputTap,
    required this.onBukuBesarTap,
  });

  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onInputTap;
  final VoidCallback onBukuBesarTap;

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
                icon: Icons.menu_book_outlined,
                activeIcon: Icons.menu_book,
                label: 'Buku Besar',
                active: false,
                onTap: onBukuBesarTap,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: MaxWidthBox(
        maxWidth: 720,
        child: ListView(
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
              onTap: () => context.push('/anggota'),
            ),
            _SettingTile(
              icon: Icons.person_add_alt_1_outlined,
              label: 'Pilih Anggota',
              onTap: () => context.push('/pilih-anggota'),
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
            const SizedBox(height: 8),
            _SettingTile(
              icon: Icons.info_outline,
              label: 'Tentang',
              onTap: () => context.push('/tentang'),
            ),
            const SizedBox(height: 16),
            _LogoutTile(),
          ],
        ),
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

class _LogoutTile extends StatelessWidget {
  const _LogoutTile();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(Icons.logout, color: AppColors.negativeRed),
        title: Text(
          'Keluar',
          style: TextStyle(
            color: AppColors.negativeRed,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _confirmSignOut(context),
      ),
    );
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
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.negativeRed,
            ),
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
