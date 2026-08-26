import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/utils/app_formatters.dart';
import '../../data/datasources/laporan_remote_data_source.dart';

class BalanceSheetPage extends StatefulWidget {
  const BalanceSheetPage({super.key});

  @override
  State<BalanceSheetPage> createState() => _BalanceSheetPageState();
}

class _BalanceSheetPageState extends State<BalanceSheetPage> {
  int _selectedYear = DateTime.now().year;
  List<Map<String, dynamic>> _accounts = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ds = GetIt.I<LaporanRemoteDataSource>();
      final data = await ds.getBalanceSheetData(_selectedYear);
      setState(() {
        _accounts = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Komposisi Keuangan'),
        actions: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() => _selectedYear--);
                  _loadData();
                },
              ),
              Text(
                '$_selectedYear',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() => _selectedYear++);
                  _loadData();
                },
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loadData,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : _BalanceSheetView(
                  accounts: _accounts,
                  year: _selectedYear,
                ),
    );
  }
}

class _BalanceSheetView extends StatelessWidget {
  const _BalanceSheetView({
    required this.accounts,
    required this.year,
  });

  final List<Map<String, dynamic>> accounts;
  final int year;

  @override
  Widget build(BuildContext context) {
    // Group accounts
    final assets = accounts
        .where((a) => a['account_type'] == 'asset')
        .toList()
      ..sort((a, b) => (a['code'] as String).compareTo(b['code'] as String));
    final liabilities = accounts
        .where((a) => a['account_type'] == 'liability')
        .toList()
      ..sort((a, b) => (a['code'] as String).compareTo(b['code'] as String));
    final equity = accounts
        .where((a) => a['account_type'] == 'equity')
        .toList()
      ..sort((a, b) => (a['code'] as String).compareTo(b['code'] as String));
    final revenue = accounts
        .where((a) => a['account_type'] == 'revenue')
        .toList()
      ..sort((a, b) => (a['code'] as String).compareTo(b['code'] as String));
    final expense = accounts
        .where((a) => a['account_type'] == 'expense')
        .toList()
      ..sort((a, b) => (a['code'] as String).compareTo(b['code'] as String));

    // Calculate totals
    // For asset: balance = debit - credit (positive = asset)
    // For liability/equity: balance = credit - debit (positive = balance)
    // For revenue: balance = credit - debit
    // For expense: balance = debit - credit
    double sumAccountType(List<Map<String, dynamic>> list, String type) {
      return list.fold(0.0, (sum, a) {
        final debit = (a['debit_total'] as num?)?.toDouble() ?? 0;
        final credit = (a['credit_total'] as num?)?.toDouble() ?? 0;
        switch (type) {
          case 'asset':
            return sum + (debit - credit);
          case 'expense':
            return sum + (debit - credit);
          default: // liability, equity, revenue
            return sum + (credit - debit);
        }
      });
    }

    final totalAsset = sumAccountType(assets, 'asset');
    final totalLiability = sumAccountType(liabilities, 'liability');
    final totalEquity = sumAccountType(equity, 'equity');
    final totalRevenue = sumAccountType(revenue, 'revenue');
    final totalExpense = sumAccountType(expense, 'expense');
    final labaRugi = totalRevenue - totalExpense;
    final totalPasiva = totalLiability + totalEquity + labaRugi;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'KSU Cahaya Dhamma Phala',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Laporan Komposisi Keuangan',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Per 31 Desember $year',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // AKTIVA
          _SectionHeader(title: 'AKTIVA (Aset)', color: Colors.blue),
          const SizedBox(height: 8),
          ...assets.map((a) => _AccountRow(
                code: a['code'] as String,
                name: a['name'] as String,
                debit: (a['debit_total'] as num?)?.toDouble() ?? 0,
                credit: (a['credit_total'] as num?)?.toDouble() ?? 0,
                isDebit: true,
              )),
          _TotalRow(
            label: 'Total Aktiva',
            amount: totalAsset,
            color: Colors.blue,
          ),
          const SizedBox(height: 24),

          // PASIVA
          _SectionHeader(title: 'PASIVA', color: Colors.green),
          const SizedBox(height: 8),

          // Liabilitas
          if (liabilities.isNotEmpty) ...[
            _SubSectionHeader(title: 'Liabilitas'),
            ...liabilities.map((a) => _AccountRow(
                  code: a['code'] as String,
                  name: a['name'] as String,
                  debit: (a['debit_total'] as num?)?.toDouble() ?? 0,
                  credit: (a['credit_total'] as num?)?.toDouble() ?? 0,
                  isDebit: false,
                )),
            _TotalRow(
              label: 'Total Liabilitas',
              amount: totalLiability,
              color: Colors.green[700]!,
            ),
            const SizedBox(height: 12),
          ],

          // Ekuitas
          if (equity.isNotEmpty) ...[
            _SubSectionHeader(title: 'Ekuitas'),
            ...equity.map((a) => _AccountRow(
                  code: a['code'] as String,
                  name: a['name'] as String,
                  debit: (a['debit_total'] as num?)?.toDouble() ?? 0,
                  credit: (a['credit_total'] as num?)?.toDouble() ?? 0,
                  isDebit: false,
                )),
            _TotalRow(
              label: 'Total Ekuitas',
              amount: totalEquity,
              color: Colors.green[700]!,
            ),
            const SizedBox(height: 12),
          ],

          // Laba Rugi
          _SubSectionHeader(title: 'Laba / Rugi Bersih'),
          ...revenue.map((a) => _AccountRow(
                code: a['code'] as String,
                name: a['name'] as String,
                debit: (a['debit_total'] as num?)?.toDouble() ?? 0,
                credit: (a['credit_total'] as num?)?.toDouble() ?? 0,
                isDebit: false,
              )),
          ...expense.map((a) => _AccountRow(
                code: a['code'] as String,
                name: a['name'] as String,
                debit: (a['debit_total'] as num?)?.toDouble() ?? 0,
                credit: (a['credit_total'] as num?)?.toDouble() ?? 0,
                isDebit: true,
              )),
          _TotalRow(
            label: 'Laba / Rugi Bersih',
            amount: labaRugi,
            color: labaRugi >= 0 ? Colors.green[700]! : Colors.red,
          ),
          const SizedBox(height: 16),

          _TotalRow(
            label: 'Total Pasiva',
            amount: totalPasiva,
            color: Colors.green,
          ),
          const SizedBox(height: 16),

          // Verification
          Card(
            color: (totalAsset - totalPasiva).abs() < 0.01
                ? Colors.green[50]
                : Colors.red[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    (totalAsset - totalPasiva).abs() < 0.01
                        ? Icons.check_circle
                        : Icons.error,
                    color: (totalAsset - totalPasiva).abs() < 0.01
                        ? Colors.green
                        : Colors.red,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (totalAsset - totalPasiva).abs() < 0.01
                        ? 'Neraca Seimbang'
                        : 'Neraca Tidak Seimbang (Selisih: ${AppFormatters.rupiah((totalAsset - totalPasiva).abs())})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: (totalAsset - totalPasiva).abs() < 0.01
                          ? Colors.green[700]
                          : Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubSectionHeader extends StatelessWidget {
  const _SubSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 8, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
          fontSize: 13,
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.code,
    required this.name,
    required this.debit,
    required this.credit,
    required this.isDebit,
  });

  final String code;
  final String name;
  final double debit;
  final double credit;
  final bool isDebit;

  @override
  Widget build(BuildContext context) {
    final balance = isDebit ? (debit - credit) : (credit - debit);
    if (balance == 0) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        leading: Container(
          width: 48,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            code,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontSize: 13),
        ),
        trailing: Text(
          AppFormatters.rupiah(balance),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: balance >= 0 ? Colors.green[700] : Colors.red,
          ),
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              AppFormatters.rupiah(amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
