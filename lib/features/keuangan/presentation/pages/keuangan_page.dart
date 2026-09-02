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
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kas Umum & Bank'),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Saldo Berjalan'),
              Tab(text: 'Kas'),
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
                      child: _SaldoBerjalanView(
                        balance: state.summary?.total ?? state.cashBalance,
                        accounts: state.summary?.accounts ?? const [],
                      ),
                    ),
                    RefreshIndicator(
                      onRefresh: () async =>
                          await GetIt.I<KeuanganCubit>().load(silent: true),
                      child: _KasSourceView(sources: state.cashSources),
                    ),
                    RefreshIndicator(
                      onRefresh: () async =>
                          await GetIt.I<KeuanganCubit>().load(silent: true),
                      child: _BookListView(
                        entries: state.bankEntries,
                        balance: state.bankBalance,
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
    final book = DefaultTabController.of(context).index == 2 ? 'bank' : 'cash';
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
    required this.emptyMessage,
    required this.onAdd,
  });

  final List<CashBookEntry> entries;
  final double balance;
  final String emptyMessage;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BalanceCard(balance: balance),
        const SizedBox(height: 12),
      ],
    );

    if (entries.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _BalanceCard(balance: balance),
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

/// Saldo Berjalan (tab 1): total + rincian sisi kredit.
class _SaldoBerjalanView extends StatelessWidget {
  const _SaldoBerjalanView({
    required this.balance,
    required this.accounts,
  });

  final double balance;
  final List<CashLedgerAccount> accounts;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _BalanceCard(balance: balance),
        if (accounts.isNotEmpty) ...[
          const SizedBox(height: 12),
          _RincianCard(accounts: accounts),
        ],
      ],
    );
  }
}

/// Kas (tab 2): pemasukan Kas (1111) dari angsuran pinjaman, simpanan
/// manasuka, dan cair dari bank.
class _KasSourceView extends StatelessWidget {
  const _KasSourceView({required this.sources});

  final CashSources? sources;

  static const _sources = [
    (key: 'pos_japinup', label: 'Japinup (Jasa Pinjaman)'),
    (key: 'pos_kesra', label: 'Kesra (Kesejahteraan)'),
    (key: 'pos_sosial', label: 'Dana Sosial'),
    (key: 'pos_pendidikan', label: 'Dana Pendidikan'),
    (key: 'pos_crk', label: 'CRK (Cadangan Risiko Kredit)'),
    (key: 'pos_pembangunan', label: 'Dana Pembangunan'),
    (key: 'pos_swk', label: 'SWK (Simpanan Wajib Kredit)'),
    (key: 'sms', label: 'SMS (Simpanan Manasuka)'),
    (key: 'cair_bank', label: 'Cair dari Bank'),
  ];

  double _totalOf(String key) {
    switch (key) {
      case 'pos_japinup':
        return sources?.posJapinup ?? 0;
      case 'pos_kesra':
        return sources?.posKesra ?? 0;
      case 'pos_sosial':
        return sources?.posSosial ?? 0;
      case 'pos_pendidikan':
        return sources?.posPendidikan ?? 0;
      case 'pos_crk':
        return sources?.posCrk ?? 0;
      case 'pos_pembangunan':
        return sources?.posPembangunan ?? 0;
      case 'pos_swk':
        return sources?.posSwk ?? 0;
      case 'sms':
        return sources?.totalSms ?? 0;
      case 'cair_bank':
        return sources?.totalCairBank ?? 0;
    }
    return 0;
  }

  /// Menyaring baris entries yang termasuk ke sebuah sumber kartu.
  /// Entries dari RPC memakai kode akun pos untuk tiap pos dana.
  static bool _entryMatches(CashSourceEntry e, String key) {
    switch (key) {
      case 'pos_japinup':
        return e.source == '4111';
      case 'pos_kesra':
        return e.source == '2119';
      case 'pos_sosial':
        return e.source == '2114';
      case 'pos_pendidikan':
        return e.source == '2115';
      case 'pos_crk':
        return e.source == '3115';
      case 'pos_pembangunan':
        return e.source == '3114';
      case 'pos_swk':
        return e.source == '2113';
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = sources?.entries ?? const <CashSourceEntry>[];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _BalanceCard(label: 'Kas', balance: sources?.total ?? 0),
        const SizedBox(height: 12),
        for (var i = 0; i < _sources.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _SourceCard(
            label: _sources[i].label,
            total: _totalOf(_sources[i].key),
            entries: list
                .where((e) => _entryMatches(e, _sources[i].key))
                .toList(),
          ),
        ],
      ],
    );
  }
}

/// Ringkasan rincian saldo berjalan sisi kredit (kewajiban + ekuitas +
/// pendapatan, kecuali Modal Tetap).
class _RincianCard extends StatelessWidget {
  const _RincianCard({required this.accounts});

  final List<CashLedgerAccount> accounts;

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
              'Saldo Berjalan (Sisi Kredit)',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            for (var i = 0; i < accounts.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        accounts[i].name,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppFormatters.rupiah(accounts[i].balance),
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
  const _BalanceCard({required this.balance, this.label = 'Saldo Berjalan'});

  final double balance;
  final String label;

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
          Text(label,
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

/// Kartu satu sumber pemasukan Kas (total + rincian barisnya).
class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.label,
    required this.total,
    required this.entries,
  });

  final String label;
  final double total;
  final List<CashSourceEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  AppFormatters.rupiah(total),
                  style:
                      const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Belum ada pemasukan dari sumber ini.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            for (var i = 0; i < entries.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        entries[i].description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppFormatters.rupiah(entries[i].amount),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          AppFormatters.date(entries[i].date),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
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
