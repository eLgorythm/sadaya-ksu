import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/sadaya_message.dart';
import '../../domain/entities/aset_entities.dart';
import '../../domain/usecases/create_asset.dart';
import '../cubit/aset_cubit.dart';
import '../widgets/asset_form_sheet.dart';

class AsetPage extends StatelessWidget {
  const AsetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = GetIt.I<AsetCubit>();
    return Scaffold(
      appBar: AppBar(title: const Text('Aset Koperasi')),
      body: BlocBuilder<AsetCubit, AsetState>(
        bloc: cubit..load(),
        builder: (context, state) {
          switch (state) {
            case AsetLoadInProgress() || AsetInitial():
              return const LoadingView();
            case AsetFailure(:final message):
              return ErrorStateView(message: message, onRetry: () => cubit.load());
            case AsetLoaded():
              return _AsetView(
                  state: state, onReload: (year) => cubit.load(year: year));
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final saved = await AssetFormSheet.show(context);
          if (saved) cubit.load();
        },
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Tambah Aset'),
      ),
    );
  }
}

class _AsetView extends StatelessWidget {
  const _AsetView({required this.state, required this.onReload});

  final AsetLoaded state;
  final ValueChanged<int?> onReload;

  Future<void> _recalculate(BuildContext context, int year) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Hitung Penyusutan $year?'),
        content: Text('Buku penyusutan tahun $year akan dibuat ulang '
            'dari seluruh aset aktif (garis lurus, proporsional bulan '
            'perolehan).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hitung'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await GetIt.I<AsetCubit>().recalculate();
    if (!context.mounted) return;
    switch (result) {
      case Ok(:final value):
        SadayaMessage.success(
            context, '$value baris penyusutan tahun $year dihitung');
      case Err(:final failure):
        SadayaMessage.error(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final year = state.selectedYear;
    final rows = state.depreciationRows;
    final assets = state.assets;
    const green = AppColors.primaryGreen;

    return RefreshIndicator(
      onRefresh: () async => onReload(null),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          // ---- Ringkasan ----
          Card(
            margin: EdgeInsets.zero,
            color: AppColors.primaryGreen.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Nilai Buku per $year',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      PopupMenuButton<int>(
                        initialValue: year,
                        onSelected: onReload,
                        itemBuilder: (_) => [
                          for (var y = DateTime.now().year; y >= 2020; y--)
                            PopupMenuItem(value: y, child: Text('$y')),
                        ],
                        icon: const Icon(Icons.calendar_month_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InfoRow(
                      label: 'Nilai Perolehan (aktif)',
                      value: AppFormatters.rupiah(state.totalCost)),
                  InfoRow(
                      label: 'Akumulasi Penyusutan',
                      value: '- ${AppFormatters.rupiah(state.totalAccumulated)}'),
                  InfoRow(
                    label: 'Nilai Buku',
                    value: AppFormatters.rupiah(state.totalBookValue),
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // ---- Hitung penyusutan ----
          OutlinedButton.icon(
            onPressed: () => _recalculate(context, year),
            icon: const Icon(Icons.calculate_outlined, size: 18),
            label: Text(rows.isEmpty
                ? 'Hitung Penyusutan $year'
                : 'Hitung Ulang Penyusutan $year'),
          ),
          const SizedBox(height: 8),
          // ---- Buku penyusutan tahun terpilih ----
          if (rows.isNotEmpty) ...[
            Text('Buku Penyusutan $year',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            for (final row in rows)
              Card(
                margin: const EdgeInsets.only(top: 8),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  leading: CircleAvatar(
                    radius: 17,
                    backgroundColor: green.withValues(alpha: 0.15),
                    child: const Icon(Icons.trending_down,
                        size: 18, color: green),
                  ),
                  title: Text(row.assetName,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('Akumulasi ${AppFormatters.rupiah(row.accumulated)}'
                      ' • NBV ${AppFormatters.rupiah(row.bookValue)}'),
                  trailing: Text(
                    '- ${AppFormatters.rupiah(row.amount)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.negativeRed),
                  ),
                ),
              ),
          ],
          // ---- Daftar aset ----
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 4),
            child: Text('Buku Inventaris (${assets.length})',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          if (assets.isEmpty)
            EmptyStateView(
              icon: Icons.inventory_2_outlined,
              message:
                  'Belum ada aset.\nTekan "Tambah Aset" untuk mendaftarkan.',
            )
          else
            for (final asset in assets)
              _AssetCard(asset: asset, onChanged: () => onReload(null)),
        ],
      ),
    );
  }
}

class _AssetCard extends StatelessWidget {
  const _AssetCard({required this.asset, required this.onChanged});

  final AssetItem asset;
  final VoidCallback onChanged;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Aset?'),
        content: Text(
            '"${asset.name}" akan dihapus dari buku inventaris beserta '
            'seluruh riwayat penyusutannya. Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.negativeRed),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await GetIt.I<DeleteAsset>()(asset.id);
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        SadayaMessage.success(context, 'Aset "${asset.name}" dihapus');
        onChanged();
      case Err(:final failure):
        SadayaMessage.error(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (asset.status) {
      'disposed' => 'Dilepas',
      'written_off' => 'Dihapuskan',
      _ => null,
    };
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(asset.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold)),
                ),
                if (statusLabel != null) ...[
                  StatusBadge(label: statusLabel, status: 'inactive'),
                  const SizedBox(width: 8),
                ],
                if (asset.isActive)
                  IconButton(
                    tooltip: 'Ubah',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () async {
                      final saved =
                          await AssetFormSheet.show(context, asset: asset);
                      if (saved) onChanged();
                    },
                  ),
                IconButton(
                  tooltip: 'Hapus',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.delete_outline,
                      size: 20, color: AppColors.negativeRed),
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
            if ((asset.description ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(asset.description!,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
            const Divider(height: 20),
            InfoRow(
              label: 'Perolehan',
              value:
                  '${AppFormatters.date(asset.acquisitionDate)} • ${AppFormatters.rupiah(asset.cost)}',
            ),
            if (asset.isActive) ...[
              InfoRow(
                label: 'Umur Pakai',
                value: '${asset.usefulLifeYears} tahun'
                    ' • residu ${AppFormatters.rupiah(asset.salvageValue)}',
              ),
              InfoRow(
                label: 'Penyusutan / tahun',
                value: AppFormatters.rupiah(asset.annualDepreciation),
                bold: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
