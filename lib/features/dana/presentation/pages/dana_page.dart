import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/responsive/responsive_scaffold.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/sadaya_message.dart';
import '../../../keuangan/domain/usecases/bank_action.dart';
import '../../../keuangan/presentation/widgets/bank_action_sheet.dart';
import '../../domain/entities/dana_entities.dart';
import '../cubit/dana_cubit.dart';
import '../widgets/fund_transaction_sheet.dart';
import '../widgets/shu_form_sheet.dart';

const _fundColors = <String, Color>{
  'social': Color(0xFF2E7D32),
  'education': Color(0xFF1565C0),
  'welfare': Color(0xFF6A1B9A),
  'crk': Color(0xFFEF6C00),
  'development': Color(0xFF00838F),
  'reserve': Color(0xFF5D4037),
  'japinup': Color(0xFFD84315),
  'swk': Color(0xFF2E7D32),
};

class DanaPage extends StatefulWidget {
  const DanaPage({super.key});

  @override
  State<DanaPage> createState() => _DanaPageState();
}

class _DanaPageState extends State<DanaPage>
    with SingleTickerProviderStateMixin {
  late final DanaCubit _cubit = GetIt.I<DanaCubit>();
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cubit.load();
    });
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (mounted && !_tabController.indexIsChanging) setState(() {});
  }

  Future<void> _openFundSheet() async {
    final saved = await FundTransactionSheet.show(context);
    if (saved && mounted) _cubit.load(silent: true);
  }

  Future<void> _openCairBank() async {
    final saved = await BankActionSheet.show(
      context,
      action: BankAction.cairKas,
    );
    if (saved && mounted) _cubit.load(silent: true);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isShuTab = _tabController.index == 1;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dana & SHU'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Buku Dana'),
            Tab(text: 'SHU'),
          ],
        ),
      ),
      body: MaxWidthBox(
        maxWidth: 1200,
        child: BlocBuilder<DanaCubit, DanaState>(
          bloc: _cubit,
          builder: (context, state) {
            switch (state) {
              case DanaLoadInProgress() || DanaInitial():
                return const LoadingView();
              case DanaFailure(:final message):
                return ErrorStateView(
                  message: message,
                  onRetry: () => _cubit.load(),
                );
              case DanaLoaded():
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _FundTab(
                      state: state,
                      onReload: () => _cubit.load(silent: true),
                      onCair: _openCairBank,
                    ),
                    _ShuTab(
                      state: state,
                      onReload: () => _cubit.load(silent: true),
                    ),
                  ],
                );
            }
          },
        ),
      ),
      floatingActionButton: isShuTab
          ? FloatingActionButton.extended(
              onPressed: () async {
                final saved = await ShuFormSheet.show(context);
                if (saved) _cubit.load(silent: true);
              },
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Hitung SHU'),
            )
          : FloatingActionButton.extended(
              onPressed: _openFundSheet,
              icon: const Icon(Icons.add_card_outlined),
              label: const Text('Catat Dana'),
            ),
    );
  }
}

class _FundTab extends StatelessWidget {
  const _FundTab({
    required this.state,
    required this.onReload,
    required this.onCair,
  });

  final DanaLoaded state;
  final VoidCallback onReload;
  final VoidCallback onCair;

  @override
  Widget build(BuildContext context) {
    final entries = state.fundEntries;
    return RefreshIndicator(
      onRefresh: () async => onReload(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          _TotalKasCard(balance: state.totalKas),
          const SizedBox(height: 12),
          ResponsiveGrid(
            children: [
              for (final type in kFundPosOrder)
                _FundBalanceCard(
                  fundType: type,
                  balance: state.ledgerBalanceOf(kFundPosAccounts[type]!),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _CairBankCard(total: state.cairBankTotal, onCair: onCair),
          const SizedBox(height: 16),
          Text('Transaksi', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Belum ada transaksi dana.\n'
                  'Pemasukan dari distribusi jasa masuk otomatis.\n'
                  'Tekan "Catat Dana" untuk kas masuk/keluar manual.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...entries.map((entry) => _FundTile(entry: entry)),
        ],
      ),
    );
  }
}

class _TotalKasCard extends StatelessWidget {
  const _TotalKasCard({required this.balance});

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
          Text(
            'Total Kas (7 Pos Dana)',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 4),
          Text(
            AppFormatters.rupiah(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CairBankCard extends StatelessWidget {
  const _CairBankCard({required this.total, required this.onCair});

  final double total;
  final VoidCallback onCair;

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
                  'Cair dari Bank',
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  AppFormatters.rupiah(total),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Total uang yang ditarik dari rekening ke kas.',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCair,
                icon: const Icon(Icons.currency_exchange, size: 18),
                label: const Text('Cair dari Bank'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FundBalanceCard extends StatelessWidget {
  const _FundBalanceCard({required this.fundType, required this.balance});

  final String fundType;
  final double balance;

  @override
  Widget build(BuildContext context) {
    final color = _fundColors[fundType] ?? AppColors.primaryGreen;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 5, backgroundColor: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    kFundPosLabels[fundType] ?? fundType,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppFormatters.rupiah(balance),
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _FundTile extends StatelessWidget {
  const _FundTile({required this.entry});

  final FundTransaction entry;

  @override
  Widget build(BuildContext context) {
    final isIncoming = entry.isIncoming;
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
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
          entry.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${entry.fundLabel} • ${AppFormatters.date(entry.date)}',
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

class _ShuTab extends StatelessWidget {
  const _ShuTab({required this.state, required this.onReload});

  final DanaLoaded state;
  final VoidCallback onReload;

  Future<void> _approve(BuildContext context, ShuDistribution shu) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Setujui SHU?'),
        content: Text(
          'SHU tahun ${shu.fiscalYear} akan berstatus '
          'disetujui dan siap didistribusikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await GetIt.I<DanaCubit>().approveShu(shu.id);
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        SadayaMessage.success(context, 'SHU ${shu.fiscalYear} disetujui');
        onReload();
      case Err(:final failure):
        SadayaMessage.error(context, failure.message);
    }
  }

  Future<void> _distribute(BuildContext context, ShuDistribution shu) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Distribusikan SHU?'),
        content: const Text(
          'Alokasi dana sosial/pendidikan/cadangan akan otomatis '
          'tercatat di Buku Dana. Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Distribusikan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await GetIt.I<DanaCubit>().distribute(shu.id);
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        SadayaMessage.success(context, 'SHU ${shu.fiscalYear} didistribusikan');
        onReload();
      case Err(:final failure):
        SadayaMessage.error(context, failure.message);
    }
  }

  Future<void> _edit(BuildContext context, ShuDistribution shu) async {
    final saved = await ShuFormSheet.show(context, existing: shu);
    if (saved) onReload();
  }

  Future<void> _cancelDistribution(
    BuildContext context,
    ShuDistribution shu,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Batalkan Distribusi?'),
        content: Text(
          'Alokasi SHU ${shu.fiscalYear} di Buku Dana akan '
          'dicabut dan status kembali menjadi draft. '
          'Setelah itu Anda bisa mengubah angka lalu mendistribusikan '
          'ulang, atau menghapusnya.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.negativeRed,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Batalkan Distribusi'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await GetIt.I<DanaCubit>().cancelDistribution(shu.id);
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        SadayaMessage.success(
          context,
          'Distribusi SHU ${shu.fiscalYear} dibatalkan, kembali jadi draft',
        );
        onReload();
      case Err(:final failure):
        SadayaMessage.error(context, failure.message);
    }
  }

  Future<void> _delete(BuildContext context, ShuDistribution shu) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus SHU?'),
        content: Text(
          'Perhitungan SHU tahun ${shu.fiscalYear} akan '
          'dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.negativeRed,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await GetIt.I<DanaCubit>().deleteShu(shu.id);
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        SadayaMessage.success(context, 'SHU ${shu.fiscalYear} dihapus');
        onReload();
      case Err(:final failure):
        SadayaMessage.error(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shuList = state.shuList;
    if (shuList.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => onReload(),
        child: const EmptyStateView(
          icon: Icons.calculate_outlined,
          message:
              'Belum ada perhitungan SHU.\nTekan "Hitung SHU" untuk mulai.',
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onReload(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          for (final shu in shuList)
            _ShuCard(
              shu: shu,
              onApprove: () => _approve(context, shu),
              onDistribute: () => _distribute(context, shu),
              onDelete: () => _delete(context, shu),
              onEdit: () => _edit(context, shu),
              onCancelDistribution: () => _cancelDistribution(context, shu),
            ),
        ],
      ),
    );
  }
}

class _ShuCard extends StatelessWidget {
  const _ShuCard({
    required this.shu,
    required this.onApprove,
    required this.onDistribute,
    required this.onDelete,
    required this.onEdit,
    required this.onCancelDistribution,
  });

  final ShuDistribution shu;
  final VoidCallback onApprove;
  final VoidCallback onDistribute;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onCancelDistribution;

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (shu.status) {
      'approved' => 'Disetujui',
      'distributed' => 'Terdistribusi',
      _ => 'Draft',
    };
    final statusColor = switch (shu.status) {
      'approved' => AppTheme.statusColor('partial'),
      'distributed' => AppTheme.statusColor('active'),
      _ => AppTheme.statusColor('inactive'),
    };

    final allocations = <String, double?>{
      'Cadangan': shu.reservePct,
      'Dana Sosial': shu.socialPct,
      'Dana Pendidikan': shu.educationPct,
      'Dasim (Dana Anggota Simpanan)': shu.memberSavingsPct,
      'Dapin (Dana Anggota Pinjaman)': shu.memberServicePct,
      'Pengurus & Pengawas': shu.managementPct,
      'Pegawai/Karyawan': shu.staffPct,
      'Dana Pembangunan': shu.developmentPct,
    };

    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'SHU ${shu.fiscalYear}',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                StatusBadge(
                  label: statusLabel,
                  status: switch (shu.status) {
                    'distributed' => 'active',
                    'approved' => 'partial',
                    _ => 'inactive',
                  },
                ),
              ],
            ),
            const Divider(height: 20),
            InfoRow(
              label: 'Total SHU',
              value: AppFormatters.rupiah(shu.totalShu),
            ),
            if (shu.taxAmount > 0)
              InfoRow(
                label: 'Pajak',
                value: '- ${AppFormatters.rupiah(shu.taxAmount)}',
              ),
            InfoRow(
              label: 'Net SHU',
              value: AppFormatters.rupiah(shu.netShu),
              bold: true,
            ),
            const Divider(height: 20),
            for (final a in allocations.entries)
              if ((a.value ?? 0) > 0)
                InfoRow(
                  label:
                      '${a.key} (${((a.value ?? 0) * 100).toStringAsFixed(a.value! * 100 == (a.value! * 100).roundToDouble() ? 0 : 2)}%)',
                  value: AppFormatters.rupiah(shu.allocationOf(a.value)),
                ),
            if ((shu.notes ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                shu.notes!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppTheme.statusColor('inactive'),
                ),
              ),
            ],
            if (shu.isDistributed && shu.distributionDate != null) ...[
              const Divider(height: 20),
              Text(
                'Didistribusikan pada ${AppFormatters.date(shu.distributionDate!)}',
                style: TextStyle(color: statusColor),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onCancelDistribution,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.negativeRed,
                  ),
                  icon: const Icon(Icons.undo, size: 18),
                  label: const Text('Batalkan Distribusi'),
                ),
              ),
            ] else ...[
              // Draft maupun disetujui: aksi utama selalu tampil
              // sebagai tombol penuh agar tidak terlewat.
              const Divider(height: 20),
              SizedBox(
                width: double.infinity,
                child: shu.isApproved
                    ? FilledButton.icon(
                        onPressed: onDistribute,
                        icon: const Icon(Icons.send_outlined),
                        label: const Text('Distribusikan SHU'),
                      )
                    : FilledButton.tonalIcon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.how_to_vote_outlined),
                        label: const Text('Setujui SHU'),
                      ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Ubah'),
                  ),
                  TextButton.icon(
                    onPressed: onDelete,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.negativeRed,
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Hapus'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
