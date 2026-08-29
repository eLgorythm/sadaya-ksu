import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../data/datasources/laporan_remote_data_source.dart';

/// Laporan Komposisi Keuangan (Neraca) — real-time dari buku besar.
///
/// Desain redesign: banner "Persamaan Akuntansi" + kartu kelompok
/// ASET / KEWAJIBAN / EKUITAS / Laba-Rugi.
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
      if (!mounted) return;
      setState(() {
        _accounts = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Komposisi Keuangan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              'Laporan Neraca Real-time (Automated)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brand100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Direct Posting',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brand800,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Perbarui',
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              )
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 120),
                      Icon(Icons.error_outline,
                          size: 48, color: Colors.red[300]),
                      const SizedBox(height: 12),
                      Center(child: Text(_error!)),
                      const SizedBox(height: 12),
                      Center(
                        child: FilledButton(
                          onPressed: _loadData,
                          child: const Text('Coba Lagi'),
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: _NeracaView(
                      accounts: _accounts,
                      year: _selectedYear,
                      onYearChanged: (y) {
                        setState(() => _selectedYear = y);
                        _loadData();
                      },
                    ),
                  ),
      ),
    );
  }
}

class _NeracaView extends StatelessWidget {
  const _NeracaView({
    required this.accounts,
    required this.year,
    required this.onYearChanged,
  });

  final List<Map<String, dynamic>> accounts;
  final int year;
  final ValueChanged<int> onYearChanged;

  @override
  Widget build(BuildContext context) {
    final groups = _buildGroups();

    final totalAset = groups['asset']!.balance;
    final totalKewajiban = groups['liability']!.balance;
    final totalEkuitas = groups['equity']!.balance;
    final totalPendapatan = groups['revenue']!.balance;
    final totalBeban = groups['expense']!.balance;
    final labaRugi = totalPendapatan - totalBeban;
    final totalPasiva = totalKewajiban + totalEkuitas + labaRugi;
    final balanced = (totalAset - totalPasiva).abs() < 0.01;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Periode ',
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            const Spacer(),
            _YearStepper(year: year, onChanged: onYearChanged),
          ],
        ),
        const SizedBox(height: 10),

        // Banner persamaan akuntansi
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.brand50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.brand100),
          ),
          child: Row(
            children: [
              Icon(Icons.scale, color: AppColors.brand600, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Persamaan Akuntansi',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brand900,
                      ),
                    ),
                    Text(
                      'Aset = Kewajiban + Ekuitas + (Pendapatan − Beban)',
                      style: TextStyle(fontSize: 10, color: AppColors.brand700),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.brand100),
                ),
                child: Text(
                  balanced ? 'SEIMBANG' : 'SELISIH',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: balanced ? AppColors.brand700 : Colors.red[600],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ASET
        _GroupCard(
          title: 'ASET (AKTIVA)',
          icon: Icons.trending_up,
          color: AppColors.brand700,
          totalText: AppFormatters.rupiah(totalAset),
          rows: groups['asset']!.rows,
        ),
        const SizedBox(height: 12),

        // KEWAJIBAN
        _GroupCard(
          title: 'KEWAJIBAN (PASIVA)',
          icon: Icons.shield_outlined,
          color: const Color(0xFFB45309),
          totalText: AppFormatters.rupiah(totalKewajiban),
          rows: groups['liability']!.rows,
        ),
        const SizedBox(height: 12),

        // EKUITAS
        _GroupCard(
          title: 'EKUITAS / MODAL',
          icon: Icons.pie_chart_outline,
          color: const Color(0xFF2563EB),
          totalText: AppFormatters.rupiah(totalEkuitas),
          rows: groups['equity']!.rows,
        ),
        const SizedBox(height: 12),

        // LABA RUGI
        _GroupCard(
          title: 'LABA / (RUGI) BERJALAN',
          icon: Icons.assessment_outlined,
          color: labaRugi >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          totalText: AppFormatters.rupiah(labaRugi),
          rows: [
            ...groups['revenue']!.rows,
            ...groups['expense']!.rows,
          ],
        ),
        const SizedBox(height: 14),

        // Verifikasi total
        _TotalBar(
          label: 'TOTAL AKTIVA',
          amount: totalAset,
          color: AppColors.brand800,
        ),
        const SizedBox(height: 6),
        _TotalBar(
          label: 'TOTAL PASIVA',
          amount: totalPasiva,
          color: const Color(0xFFB45309),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Map<String, _GroupData> _buildGroups() {
    double balanceOf(Map<String, dynamic> a) {
      final debit = (a['debit_total'] as num?)?.toDouble() ?? 0;
      final credit = (a['credit_total'] as num?)?.toDouble() ?? 0;
      return debit - credit; // saldo debit (untuk asset & beban)
    }

    double creditBalanceOf(Map<String, dynamic> a) {
      final debit = (a['debit_total'] as num?)?.toDouble() ?? 0;
      final credit = (a['credit_total'] as num?)?.toDouble() ?? 0;
      return credit - debit; // saldo kredit (untuk kewajiban, ekuitas, pendapatan)
    }

    List<_RowData> assetRows = [];
    double assetTotal = 0;
    List<_RowData> liabilityRows = [];
    double liabilityTotal = 0;
    List<_RowData> equityRows = [];
    double equityTotal = 0;
    List<_RowData> revenueRows = [];
    double revenueTotal = 0;
    List<_RowData> expenseRows = [];
    double expenseTotal = 0;

    for (final a in [...accounts]
      ..sort((x, y) => (x['code'] as String).compareTo(y['code'] as String))) {
      final type = a['account_type'] as String;
      final code = a['code'] as String;
      final name = a['name'] as String;

      switch (type) {
        case 'asset':
          final b = balanceOf(a);
          if (b == 0) break;
          assetRows.add(_RowData(label: _mapAccountLabel(code, name), value: b));
          assetTotal += b;
        case 'liability':
          final b = creditBalanceOf(a);
          if (b == 0) break;
          liabilityRows.add(_RowData(label: _mapAccountLabel(code, name), value: b));
          liabilityTotal += b;
        case 'equity':
          final b = creditBalanceOf(a);
          if (b == 0) break;
          equityRows.add(_RowData(label: _mapAccountLabel(code, name), value: b));
          equityTotal += b;
        case 'revenue':
          final b = creditBalanceOf(a);
          if (b == 0) break;
          revenueRows.add(_RowData(label: _mapAccountLabel(code, name), value: b));
          revenueTotal += b;
        case 'expense':
          final b = balanceOf(a);
          if (b == 0) break;
          expenseRows.add(_RowData(label: _mapAccountLabel(code, name), value: b));
          expenseTotal += b;
      }
    }

    return {
      'asset': _GroupData(rows: assetRows, balance: assetTotal),
      'liability': _GroupData(rows: liabilityRows, balance: liabilityTotal),
      'equity': _GroupData(rows: equityRows, balance: equityTotal),
      'revenue': _GroupData(rows: revenueRows, balance: revenueTotal),
      'expense': _GroupData(rows: expenseRows, balance: expenseTotal),
    };
  }

  /// Label ramah sesuai nama buku (desain redesign).
  String _mapAccountLabel(String code, String name) {
    switch (code) {
      case '1111':
        return 'Buku Harian Kas';
      case '1112':
        return 'Buku Bank';
      case '1113':
        return 'Buku Pinjaman (Piutang)';
      case '1130':
        return 'Persediaan Unit Keripik';
      case '1120' || '1121' || '1122' || '1123' || '1124' || '1125' || '1126' || '1131':
        return 'Buku Inventaris Aset ($name)';
      case '2111':
        return 'Simpanan Mana Suka';
      case '2114':
        return 'Buku Dana Sosial';
      case '2115':
        return 'Buku Dana Pendidikan';
      case '2119':
        return 'Buku Dana Kesejahteraan';
      case '2122':
        return 'Buku Pajak (Hutang)';
      case '3112':
        return 'Simpanan Pokok';
      case '3113':
        return 'Simpanan Wajib';
      case '3118':
        return 'Akumulasi SHU Berjalan';
      default:
        return name;
    }
  }
}

class _GroupData {
  const _GroupData({required this.rows, required this.balance});

  final List<_RowData> rows;
  final double balance;
}

class _RowData {
  const _RowData({required this.label, required this.value});

  final String label;
  final double value;
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.totalText,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String totalText;
  final List<_RowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Text(
                totalText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'Belum ada transaksi',
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            )
          else
            ...rows.map(
              (r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    Text(
                      AppFormatters.rupiah(r.value),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: r.value >= 0
                            ? Colors.grey[800]
                            : Colors.red[600],
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

class _TotalBar extends StatelessWidget {
  const _TotalBar({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            AppFormatters.rupiah(amount),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _YearStepper extends StatelessWidget {
  const _YearStepper({required this.year, required this.onChanged});

  final int year;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => onChanged(year - 1),
          icon: const Icon(Icons.chevron_left, size: 20),
        ),
        Text(
          '$year',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => onChanged(year + 1),
          icon: const Icon(Icons.chevron_right, size: 20),
        ),
      ],
    );
  }
}