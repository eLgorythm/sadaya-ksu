import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/responsive/responsive_scaffold.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../cubit/members_cubit.dart';

/// Halaman untuk MEMILIH anggota (dipakai menu Simpanan/Pinjaman di home).
/// Mengembalikan MemberEntity via Navigator.pop.
class MemberPickerPage extends StatelessWidget {
  const MemberPickerPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MembersCubit>.value(
      value: GetIt.I<MembersCubit>()..load(),
      child: _PickerView(title: title),
    );
  }
}

class _PickerView extends StatefulWidget {
  const _PickerView({required this.title});

  final String title;

  @override
  State<_PickerView> createState() => _PickerViewState();
}

class _PickerViewState extends State<_PickerView> {
  final _searchController = TextEditingController();
  String _lastSearch = '';

  @override
  void dispose() {
    if (_lastSearch.isNotEmpty) {
      GetIt.I<MembersCubit>().searchChanged('');
    }
    if (GetIt.I<MembersCubit>().currentStatusFilter != null) {
      GetIt.I<MembersCubit>().filterChanged(null);
    }
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: MaxWidthBox(
        maxWidth: 720,
        child: Column(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    children: [
                      _PickerFilterChip(
                        label: 'Semua',
                        selected: state.statusFilter == null,
                        onTap: () =>
                            GetIt.I<MembersCubit>().filterChanged(null),
                      ),
                      const SizedBox(width: 8),
                      _PickerFilterChip(
                        label: 'Aktif',
                        selected: state.statusFilter == 'active',
                        onTap: () =>
                            GetIt.I<MembersCubit>().filterChanged('active'),
                      ),
                      const SizedBox(width: 8),
                      _PickerFilterChip(
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
                        return const EmptyStateView(
                          icon: Icons.group_outlined,
                          message: 'Tidak ada anggota yang cocok.',
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () async =>
                            await GetIt.I<MembersCubit>().load(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: members.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final member = members[index];
                            return _PickerMemberCard(
                              memberNumber: member.memberNumber,
                              name: member.name,
                              phone: member.phone,
                              joinDate: member.joinDate,
                              isActive: member.isActive,
                              onTap: () => Navigator.of(context).pop(member),
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
      ),
    );
  }
}

class _PickerMemberCard extends StatelessWidget {
  const _PickerMemberCard({
    required this.memberNumber,
    required this.name,
    required this.phone,
    required this.joinDate,
    required this.isActive,
    required this.onTap,
  });

  final int memberNumber;
  final String name;
  final String? phone;
  final DateTime joinDate;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: isActive
              ? AppColors.primaryGreen.withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.2),
          child: Text(
            '$memberNumber',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isActive ? AppColors.primaryGreen : Colors.grey.shade600,
            ),
          ),
        ),
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (phone?.isNotEmpty ?? false) Text(phone!, maxLines: 1),
            Text(
              'Masuk: ${AppFormatters.date(joinDate)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusBadge(
              label: isActive ? 'Aktif' : 'Nonaktif',
              status: isActive ? 'active' : 'inactive',
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _PickerFilterChip extends StatelessWidget {
  const _PickerFilterChip({
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
