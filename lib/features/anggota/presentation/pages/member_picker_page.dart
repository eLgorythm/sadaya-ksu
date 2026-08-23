import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

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

  @override
  void dispose() {
    if (_searchController.text.isNotEmpty) {
      GetIt.I<MembersCubit>().searchChanged('');
    }
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama anggota...',
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) =>
                  GetIt.I<MembersCubit>().searchChanged(value),
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
                        padding: const EdgeInsets.all(16),
                        itemCount: members.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final member = members[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 16,
                                child: Text('${member.memberNumber}',
                                    style: const TextStyle(fontSize: 12)),
                              ),
                              title: Text(member.name),
                              subtitle: member.phone?.isNotEmpty ?? false
                                  ? Text(member.phone!)
                                  : null,
                              onTap: () =>
                                  Navigator.of(context).pop(member),
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
