import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/sadaya_message.dart';
import '../../domain/entities/usaha_entities.dart';
import '../../domain/usecases/sale_usecases.dart';
import '../cubit/usaha_cubit.dart';
import '../widgets/material_sheets.dart';
import '../widgets/production_sale_sheets.dart';

class UsahaPage extends StatefulWidget {
  const UsahaPage({super.key});

  @override
  State<UsahaPage> createState() => _UsahaPageState();
}

class _UsahaPageState extends State<UsahaPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 3, vsync: this);
  late final UsahaCubit _cubit = GetIt.I<UsahaCubit>();

  @override
  void initState() {
    super.initState();
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {}); // FAB label mengikuti tab aktif
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _cubit.load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openFabAction() async {
    final state = _cubit.state;
    if (state is! UsahaLoaded) return;
    var saved = false;
    switch (_tabController.index) {
      case 0:
        saved = await MaterialFormSheet.show(context);
      case 1:
        saved = await ProductionSheet.show(context);
      case 2:
        saved = await SaleSheet.show(context);
    }
    if (saved) _cubit.load(silent: true);
  }

  String get _fabLabel => switch (_tabController.index) {
        0 => 'Bahan Baru',
        1 => 'Catat Produksi',
        _ => 'Catat Penjualan',
      };

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UsahaCubit>.value(
      value: _cubit,
      child: BlocBuilder<UsahaCubit, UsahaState>(
        builder: (context, state) {
          final loaded = state is UsahaLoaded ? state : null;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Unit Usaha Keripik'),
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Bahan Baku'),
                  Tab(text: 'Produksi'),
                  Tab(text: 'Penjualan'),
                ],
              ),
            ),
            body: switch (state) {
              UsahaLoadInProgress() || UsahaInitial() => const LoadingView(),
              UsahaFailure(:final message) =>
                ErrorStateView(message: message, onRetry: () => _cubit.load()),
              UsahaLoaded() => TabBarView(
                  controller: _tabController,
                  children: [
                    _MaterialsTab(state: state),
                    _ProductionsTab(state: state),
                    _SalesTab(state: state),
                  ],
                ),
            },
            floatingActionButton: FloatingActionButton.extended(
              onPressed:
                  loaded == null ? null : () => _openFabAction(),
              icon: const Icon(Icons.add),
              label: Text(_fabLabel),
            ),
          );
        },
      ),
    );
  }
}

// ===========================================================================
// TAB 1 — BAHAN BAKU
// ===========================================================================
class _MaterialsTab extends StatelessWidget {
  const _MaterialsTab({required this.state});

  final UsahaLoaded state;

  @override
  Widget build(BuildContext context) {
    final materials = state.materials;
    final txs = state.materialTransactions;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
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
                  const Icon(Icons.egg_alt_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        '${materials.length} jenis bahan • '
                        '${txs.where((t) => t.isPurchase).length} pembelian / '
                        '${txs.where((t) => !t.isPurchase).length} pemakaian tercatat'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '"Bahan Baru" = mendaftarkan jenis bahan saja.\n'
                'Tombol Beli (stok masuk + harga) / Pakai (stok keluar) di kartu.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[700]),
              ),
            ],
          ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Text('Stok Bahan',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        if (materials.isEmpty)
          EmptyStateView(
            icon: Icons.inventory_outlined,
            message:
                'Belum ada bahan baku.\nTekan "Bahan Baru" untuk memulai.',
          )
        else
          for (final m in materials)
            Card(
              margin: const EdgeInsets.only(top: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 2),
                leading: CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.15),
                  child: Text(m.unit.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen)),
                ),
                title: Text(m.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${AppFormatters.number(m.currentStock)} ${m.unit}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            final cubit = context.read<UsahaCubit>();
                            final saved = await MaterialTxSheet.show(context,
                                materials: materials,
                                isPurchase: true,
                                initialMaterialId: m.id);
                            if (saved) cubit.load(silent: true);
                          },
                          icon: const Icon(Icons.add_shopping_cart,
                              size: 15),
                          label: const Text('Beli', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6)),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final cubit = context.read<UsahaCubit>();
                            final saved = await MaterialTxSheet.show(context,
                                materials: materials,
                                isPurchase: false,
                                initialMaterialId: m.id);
                            if (saved) cubit.load(silent: true);
                          },
                          icon: const Icon(Icons.outbound_outlined, size: 15),
                          label: const Text('Pakai',
                              style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.deepOrange,
                              visualDensity: VisualDensity.compact,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Text('Transaksi Terakhir',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        if (txs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Belum ada transaksi bahan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
          )
        else
          for (final tx in txs.take(15))
            Card(
              margin: const EdgeInsets.only(top: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 2),
                leading: CircleAvatar(
                  radius: 17,
                  backgroundColor: tx.isPurchase
                      ? Colors.green.withValues(alpha: 0.12)
                      : Colors.orange.withValues(alpha: 0.12),
                  child: Icon(
                      tx.isPurchase
                          ? Icons.shopping_cart_outlined
                          : Icons.outbound_outlined,
                      size: 18,
                      color: tx.isPurchase ? Colors.green : Colors.orange),
                ),
                title: Text(tx.materialName,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(AppFormatters.date(tx.date)),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${tx.isPurchase ? '+' : '-'}'
                      '${AppFormatters.number(tx.quantity)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: tx.isPurchase
                            ? Colors.green
                            : Colors.deepOrange,
                      ),
                    ),
                    if (tx.totalPrice != null)
                      Text(AppFormatters.rupiah(tx.totalPrice!),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

// ===========================================================================
// TAB 2 — PRODUKSI
// ===========================================================================
class _ProductionsTab extends StatelessWidget {
  const _ProductionsTab({required this.state});

  final UsahaLoaded state;

  @override
  Widget build(BuildContext context) {
    final productions = state.productions;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        Card(
          margin: EdgeInsets.zero,
          color: AppColors.primaryGreen.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total produksi bulan ini'),
                const SizedBox(height: 4),
                Text(
                  '${AppFormatters.number(state.monthProductionKg)} kg'
                  '${state.monthProductionGram > 0 ? ' • ${AppFormatters.number(state.monthProductionGram)} gram' : ''}'
                  ' • ${AppFormatters.number(state.monthProductionPack)} pack',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Text('Riwayat Produksi',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        if (productions.isEmpty)
          EmptyStateView(
            icon: Icons.factory_outlined,
            message:
                'Belum ada catatan produksi.\nTekan "Catat Produksi".',
          )
        else
          for (final p in productions)
            Card(
              margin: const EdgeInsets.only(top: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 2),
                leading: CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.15),
                  child: const Icon(Icons.cookie_outlined,
                      size: 18, color: AppColors.primaryGreen),
                ),
                title: Text(p.productLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(AppFormatters.date(p.date)),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                        '${AppFormatters.number(p.quantityProduced)} ${p.unit}'
                        '${p.quantityPack == null ? '' : ' • ${AppFormatters.number(p.quantityPack!)} pack'}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    if (p.productionCost != null)
                      Text('biaya ${AppFormatters.rupiah(p.productionCost!)}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

// ===========================================================================
// TAB 3 — PENJUALAN
// ===========================================================================
class _SalesTab extends StatelessWidget {
  const _SalesTab({required this.state});

  final UsahaLoaded state;

  @override
  Widget build(BuildContext context) {
    final sales = state.sales;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        Card(
          margin: EdgeInsets.zero,
          color: AppColors.primaryGreen.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: InfoRow(
              label: 'Omzet penjualan bulan ini',
              value: AppFormatters.rupiah(state.monthRevenue),
              bold: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Text('Riwayat Penjualan',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        if (sales.isEmpty)
          EmptyStateView(
            icon: Icons.sell_outlined,
            message:
                'Belum ada catatan penjualan.\nTekan "Catat Penjualan".',
          )
        else
          for (final s in sales)
            _SaleTile(
              sale: s,
              onDelete: () => _confirmDeleteSale(context, s),
            ),
      ],
    );
  }

  Future<void> _confirmDeleteSale(BuildContext context, SaleRecord sale) async {
    final cubit = context.read<UsahaCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Penjualan?'),
        content: Text('Catatan penjualan ${sale.productLabel} tanggal '
            '${AppFormatters.date(sale.date)} sebesar '
            '${AppFormatters.rupiah(sale.totalPrice)} akan dihapus.'),
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
    if (confirmed != true) return;

    final result = await GetIt.I<DeleteSale>()(sale.id);
    switch (result) {
      case Ok():
        cubit.removeSale(sale.id);
        if (!context.mounted) return;
        SadayaMessage.success(context, 'Penjualan dihapus');
      case Err(:final failure):
        if (!context.mounted) return;
        SadayaMessage.error(context, failure.message);
    }
  }
}

class _SaleTile extends StatelessWidget {
  const _SaleTile({required this.sale, required this.onDelete});

  final SaleRecord sale;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: CircleAvatar(
          radius: 17,
          backgroundColor: Colors.amber.withValues(alpha: 0.2),
          child:
              const Icon(Icons.sell_outlined, size: 18, color: Colors.amber),
        ),
        title: Text(sale.productLabel,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${AppFormatters.date(sale.date)} • '
            '${AppFormatters.number(sale.quantity)} ${sale.unit} @ '
            '${AppFormatters.rupiah(sale.unitPrice)}'
            '${sale.buyer == null || sale.buyer!.isEmpty ? '' : ' • ${sale.buyer}'}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppFormatters.rupiah(sale.totalPrice),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
            IconButton(
              tooltip: 'Hapus',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: AppColors.negativeRed),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
