import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../../../core/responsive/responsive_scaffold.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../domain/usecases/tax_usecases.dart';
import '../cubits/pajak_cubit.dart';
import '../widgets/pajak_form_sheet.dart';

class PajakPage extends StatefulWidget {
  const PajakPage({super.key});

  @override
  State<PajakPage> createState() => _PajakPageState();
}

class _PajakPageState extends State<PajakPage> {
  late final PajakCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = GetIt.I<PajakCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cubit.load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modul Pajak')),
      body: MaxWidthBox(
        maxWidth: 720,
        child: BlocBuilder<PajakCubit, PajakState>(
          bloc: _cubit,
          builder: (context, state) {
            if (state.loading && state.taxes.isEmpty) {
              return const LoadingView();
            }
            if (state.error != null && state.taxes.isEmpty) {
              return ErrorStateView(
                message: state.error!,
                onRetry: () => _cubit.load(),
              );
            }
            return _PajakView(state: state);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final saved = await PajakFormSheet.show(context);
          if (saved) _cubit.load(silent: true);
        },
        icon: const Icon(Icons.receipt_long_outlined),
        label: const Text('Tambah Pajak'),
      ),
    );
  }
}

class _PajakView extends StatelessWidget {
  const _PajakView({required this.state});

  final PajakState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Summary cards
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _SummaryCard(
                title: 'Sudah Dibayar',
                amount: state.totalPaid,
                color: Colors.green,
              ),
              const SizedBox(width: 12),
              _SummaryCard(
                title: 'Belum Dibayar',
                amount: state.totalUnpaid,
                color: Colors.orange,
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: state.taxes.isEmpty
              ? const EmptyStateView(
                  icon: Icons.receipt_long_outlined,
                  message: 'Belum ada data pajak',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.taxes.length,
                  itemBuilder: (context, index) {
                    final tax = state.taxes[index];
                    return _TaxCard(tax: tax);
                  },
                ),
        ),
        // Messages
        if (state.successMessage != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Expanded(child: Text(state.successMessage!)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
  });

  final String title;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                AppFormatters.rupiah(amount),
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaxCard extends StatelessWidget {
  const _TaxCard({required this.tax});

  final dynamic tax;

  @override
  Widget build(BuildContext context) {
    final cubit = GetIt.I<PajakCubit>();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: tax.isPaid ? Colors.green[100] : Colors.orange[100],
          child: Icon(
            tax.isPaid ? Icons.check_circle : Icons.pending,
            color: tax.isPaid ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          tax.taxType,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tax.description != null && tax.description!.isNotEmpty)
              Text(tax.description!, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd MMM yyyy').format(tax.taxDate),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: tax.isPaid ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: tax.isPaid
                          ? Colors.green[200]!
                          : Colors.orange[200]!,
                    ),
                  ),
                  child: Text(
                    tax.isPaid ? 'Dibayar' : 'Belum',
                    style: TextStyle(
                      fontSize: 10,
                      color: tax.isPaid
                          ? Colors.green[700]
                          : Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          itemBuilder: (context) => [
            if (!tax.isPaid)
              const PopupMenuItem(
                value: 'pay',
                child: Row(
                  children: [
                    Icon(Icons.payment, size: 16),
                    SizedBox(width: 8),
                    Text('Tandai Dibayar'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Hapus', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            if (value == 'pay') {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Tandai Dibayar?'),
                  content: const Text(
                    'Status pajak akan diubah menjadi "Dibayar" dan jurnal akan diposting ke buku besar.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Ya, Bayar'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await cubit.update(
                  InsertTaxParams(
                    taxType: tax.taxType,
                    description: tax.description,
                    amount: tax.amount,
                    date: tax.taxDate,
                    status: 'paid',
                    referenceNumber: tax.referenceNumber,
                    notes: tax.notes,
                  ),
                  tax.id,
                );
              }
            } else if (value == 'edit') {
              final saved = await PajakFormSheet.show(context, tax: tax);
              if (saved) cubit.load(silent: true);
            } else if (value == 'delete') {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Hapus Pajak?'),
                  content: const Text(
                    'Data pajak dan jurnal terkait akan dihapus permanen.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Hapus'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await cubit.delete(tax.id);
              }
            }
          },
        ),
        isThreeLine: true,
      ),
    );
  }
}
