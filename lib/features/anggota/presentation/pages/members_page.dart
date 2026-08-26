import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../pinjaman/presentation/pages/loans_page.dart'
    show MemberLoanTarget;
import '../../../simpanan/presentation/pages/savings_page.dart'
    show MemberSavingsTarget;
import '../../domain/entities/member_entity.dart';
import '../cubit/members_cubit.dart';
import '../widgets/member_form_sheet.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  late final MembersCubit _cubit = GetIt.I<MembersCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cubit.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MembersCubit>.value(
      value: _cubit,
      child: const _MembersView(),
    );
  }
}

class _MembersView extends StatefulWidget {
  const _MembersView();

  @override
  State<_MembersView> createState() => _MembersViewState();
}

class _MembersViewState extends State<_MembersView> {
  final _searchController = TextEditingController();
  String _lastSearch = '';

  @override
  void dispose() {
    if (_lastSearch.isNotEmpty) {
      GetIt.I<MembersCubit>().searchChanged('');
    }
    _searchController.dispose();
    super.dispose();
  }

  void _confirmStatusChange(BuildContext context, MemberEntity member) {
    final deactivate = member.isActive;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(deactivate ? 'Nonaktifkan Anggota?' : 'Aktifkan Anggota?'),
        content: Text(deactivate
            ? 'Anggota ${member.name} akan ditandai nonaktif. Riwayat transaksinya tetap tersimpan.'
            : 'Anggota ${member.name} akan kembali aktif dan bisa bertransaksi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: deactivate
                ? FilledButton.styleFrom(
                    backgroundColor: AppColors.negativeRed)
                : null,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              GetIt.I<MembersCubit>().changeStatus(
                id: member.id,
                status: deactivate ? 'inactive' : 'active',
              );
            },
            child: Text(deactivate ? 'Nonaktifkan' : 'Aktifkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Anggota')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => MemberFormSheet.show(context).then((saved) {
          if (saved) GetIt.I<MembersCubit>().load();
        }),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Anggota Baru'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama anggota...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (context, value, _) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        _searchController.clear();
                        GetIt.I<MembersCubit>().searchChanged('');
                      },
                    );
                  },
                ),
              ),
              onChanged: (value) {
                _lastSearch = value;
                GetIt.I<MembersCubit>().searchChanged(value);
              },
            ),
          ),
          SizedBox(
            height: 56,
            child: BlocBuilder<MembersCubit, MembersState>(
              builder: (context, state) {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  children: [
                    _FilterChip(
                      label: 'Semua',
                      selected: state.statusFilter == null,
                      onTap: () =>
                          GetIt.I<MembersCubit>().filterChanged(null),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Aktif',
                      selected: state.statusFilter == 'active',
                      onTap: () =>
                          GetIt.I<MembersCubit>().filterChanged('active'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Nonaktif',
                      selected: state.statusFilter == 'inactive',
                      onTap: () =>
                          GetIt.I<MembersCubit>().filterChanged('inactive'),
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<MembersCubit, MembersState>(
              builder: (context, state) {
                switch (state) {
                  case MembersLoadInProgress():
                    return const LoadingView();
                  case MembersFailure(:final message):
                    return ErrorStateView(
                      message: message,
                      onRetry: () => GetIt.I<MembersCubit>().load(),
                    );
                  case MembersLoadSuccess(:final members):
                    if (members.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () async =>
                          await GetIt.I<MembersCubit>().load(silent: true),
                      child: const EmptyStateView(
                          icon: Icons.group_outlined,
                          message:
                              'Belum ada anggota.\nTekan tombol "Anggota Baru" untuk menambah.',
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async =>
                          await GetIt.I<MembersCubit>().load(silent: true),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        itemCount: members.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final member = members[index];
                          return _MemberCard(
                            member: member,
                            onEdit: () => MemberFormSheet.show(context,
                                    member: member)
                                .then((saved) {
          if (saved) GetIt.I<MembersCubit>().load(silent: true);
                            }),
                            onToggleStatus: () =>
                                _confirmStatusChange(context, member),
                            onViewSavings: () => context.push(
                              '/simpanan/${member.id}',
                              extra: MemberSavingsTarget(
                                id: member.id,
                                name: member.name,
                                memberNumber: member.memberNumber,
                              ),
                            ),
                            onViewLoans: () => context.push(
                              '/pinjaman/${member.id}',
                              extra: MemberLoanTarget(
                                id: member.id,
                                name: member.name,
                                memberNumber: member.memberNumber,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryGreen.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primaryGreen,
      labelStyle: TextStyle(
        color: selected ? AppColors.primaryGreen : null,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      showCheckmark: false,
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onViewSavings,
    required this.onViewLoans,
  });

  final MemberEntity member;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onViewSavings;
  final VoidCallback onViewLoans;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: member.isActive
              ? AppColors.primaryGreen.withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.2),
          child: Text(
            '${member.memberNumber}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: member.isActive
                  ? AppColors.primaryGreen
                  : Colors.grey.shade600,
            ),
          ),
        ),
        title: Text(
          member.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (member.phone?.isNotEmpty ?? false)
              Text(member.phone!, maxLines: 1),
            Text('Masuk: ${AppFormatters.date(member.joinDate)}',
                style: const TextStyle(fontSize: 12)),
            if (member.notes?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    Icon(Icons.notes, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(member.notes!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontStyle: FontStyle.italic)),
                    ),
                  ],
                ),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusBadge(
              label: member.isActive ? 'Aktif' : 'Nonaktif',
              status: member.isActive ? 'active' : 'inactive',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'toggle') {
                  onToggleStatus();
                } else if (value == 'savings') {
                  onViewSavings();
                } else if (value == 'loans') {
                  onViewLoans();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'savings',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.savings_outlined),
                    title: Text('Simpanan'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'loans',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.account_balance_outlined),
                    title: Text('Pinjaman'),
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      member.isActive
                          ? Icons.block_outlined
                          : Icons.check_circle_outline,
                    ),
                    title:
                        Text(member.isActive ? 'Nonaktifkan' : 'Aktifkan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
