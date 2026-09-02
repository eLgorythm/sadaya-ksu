import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../domain/entities/cash_entities.dart';
import '../cubit/keuangan_cubit.dart';
import '../widgets/cash_form_sheet.dart';

class KeuanganPage extends StatefulWidget {
  const KeuanganPage({super.key});

  @override
  State<KeuanganPage> createState() => _KeuanganPageState();
}

class _KeuanganPageState extends State<KeuanganPage> {
  late final KeuanganCubit _cubit = GetIt.I<KeuanganCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cubit.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<KeuanganCubit>.value(
      value: _cubit,
      child: const _KeuanganView(),
    );
  }
}

class _KeuanganView extends StatelessWidget {
  const _KeuanganView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kas Umum & Bank'),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Buku Kas'),
              Tab(text: 'Buku Bank'),
            ],
          ),
        ),
        floatingActionButton: Builder(
          /// Builder agar context FAB berada DI BAWAH
          /// DefaultTabController — DefaultTabController.of(context)
          /// hanya bisa menemukan controller dari leluhur.
          builder: (fabContext) => FloatingActionButton.extended(
            onPressed: () => _openForm(fabContext),
            icon: const Icon(Icons.add_chart_outlined),
            label: const Text('Catat Transaksi'),
          ),
        ),
        body: BlocBuilder<KeuanganCubit, KeuanganState>(
          builder: (context, state) {
            switch (state) {
              case KeuanganLoadInProgress():
                return const LoadingView();
              case KeuanganFailure(:final message):
                return ErrorStateView(
                  message: message,
                  onRetry: () => GetIt.I<KeuanganCubit>().load(),
                );
              case KeuanganLoaded():
                return TabBarView(
                  children: [
                    RefreshIndicator(
                      onRefresh: () async =>
                          await GetIt.I<KeuanganCubit>().load(silent: true),
                      child: _BookListView(
                        entries: state.cashEntries,
                        balance: state.summary?.total ?? state.cashBalance,
                        accounts: state.summary?.accounts ?? const [],
                        showRincian: true,
                        emptyMessage:
                            'Belum ada transaksi kas.\nTekan "Catat Transaksi" untuk mulai.',
                        onAdd: () => _openForm(context),
                      ),
                    ),
                    RefreshIndicator(
                      onRefresh: () async =>
                          await GetIt.I<KeuanganCubit>().load(silent: true),
                      child: _BookListView(
                        entries: state.bankEntries,
                        balance: state.bankBalance,
                        accounts: const [],
                        emptyMessage:
                            'Belum ada mutasi bank.\nTekan "Catat Transaksi" untuk mulai.',
                        onAdd: () => _openForm(context),
                      ),
                    ),
                  ],
                );
              case KeuanganInitial():
                return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context) async {
    final book = DefaultTabController.of(context).index == 0 ? 'cash' : 'bank';
    final saved = await CashFormSheet.show(context, initialBook: book);
    if (saved && context.mounted) {
      GetIt.I<KeuanganCubit>().load(silent: true);
    }
  }
}

class _BookListView extends StatelessWidget {
  const _BookListView({
    required this.entries,
    required this.balance,
    required this.accounts,
    required this.emptyMessage,
    required this.onAdd,
    this.showRincian = false,
  });

  final List<CashBookEntry> entries;
  final double balance;
  final List<CashLedgerAccount> accounts;
  final String emptyMessage;
  final VoidCallback onAdd;
  final bool showRincian;

  @override
  Widget build(BuildContext context) {
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BalanceCard(balance: balance),
        if (showRincian) ...[
          const SizedBox(height: 12),
          _RincianCard(accounts: accounts),
        ],
        const SizedBox(height: 12),
      ],
    );

    if (entries.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _BalanceCard(balance: balance),
          if (showRincian) ...[
            const SizedBox(height: 12),
            _RincianCard(accounts: accounts),
          ],
          const SizedBox(height: 16),
          EmptyStateView(icon: Icons.receipt_long_outlined, message: emptyMessage),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Catat Sekarang'),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return header;
        }
        return _EntryTile(entry: entries[index - 1]);
      },
    );
  }
}

/// Ringkasan rincian saldo per akun (kas + bank + dana + Japinup).
class _RincianCard extends StatelessWidget {
  const _RincianCard({required this.accounts});

  final List<CashLedgerAccount> accounts;

  /// Urutan & label akun yang selalu ditampilkan di Buku Kas.
  static const List<({String code, String label})> _rows = [
    (code: '1111', label: 'Buku Harian Kas'),
    (code: '1112', label: 'Buku Bank'),
    (code: '2114', label: 'Dana Sosial'),
    (code: '2115', label: 'Dana Pendidikan'),
    (code: '2119', label: 'Dana Kesejahteraan'),
    (code: '3114', label: 'Dana Pembangunan'),
    (code: '3115', label: 'Dana CRK'),
    (code: '3116', label: 'Dana Cadangan'),
    (code: '4111', label: 'Japinup (Jasa Pinjaman)'),
  ];

  double _balanceOf(String code) {
    for (final a in accounts) {
      if (a.code == code) return a.balance;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rincian Saldo',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            for (var i = 0; i < _rows.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        _rows[i].label,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppFormatters.rupiah(_balanceOf(_rows[i].code)),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final double balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Saldo Berjalan',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
          const SizedBox(height: 4),
          Text(AppFormatters.rupiah(balance),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final CashBookEntry entry;

  @override
  Widget build(BuildContext context) {
    final isIncoming = entry.isIncoming;
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: CircleAvatar(
          radius: 17,
          backgroundColor: isIncoming
              ? AppColors.primaryGreen.withValues(alpha: 0.15)
              : AppColors.negativeRed.withValues(alpha: 0.15),
          child: Icon(
            isIncoming ? Icons.south_west : Icons.north_east,
            size: 18,
            color: isIncoming ? AppColors.primaryGreen : AppColors.negativeRed,
          ),
        ),
        title: Text(
          entry.categoryName ?? 'Transfer',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.description,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              AppFormatters.date(entry.date),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Text(
          '${isIncoming ? '+' : '-'} ${AppFormatters.rupiah(entry.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isIncoming ? AppColors.primaryGreen : AppColors.negativeRed,
          ),
        ),
      ),
    );
  }
}
