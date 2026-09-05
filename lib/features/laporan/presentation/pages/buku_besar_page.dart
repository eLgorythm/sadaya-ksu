import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/responsive/responsive_scaffold.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../data/datasources/laporan_remote_data_source.dart';

/// Buku Besar (General Ledger) — daftar jurnal rinci per akun,
/// real-time dari tabel `ledger_entries`.
///
/// Fitur:
/// - Filter tahun buku dan pilihan akun (default menampilkan semua akun).
/// - Per akun diperlihatkan saldo berjalan (running balance) tiap baris.
/// - Ringkasan total debit & kredit dari jurnal yang terfilter.
class BukuBesarPage extends StatefulWidget {
  const BukuBesarPage({super.key});

  @override
  State<BukuBesarPage> createState() => _BukuBesarPageState();
}

class _BukuBesarPageState extends State<BukuBesarPage> {
  int _year = DateTime.now().year;
  String? _selectedCode;
  List<Map<String, dynamic>> _allAccounts = [];
  List<Map<String, dynamic>> _entries = [];
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
      final results = await Future.wait([
        ds.getAllAccounts(),
        ds.getLedgerEntries(fiscalYear: _year, accountCode: _selectedCode),
      ]);
      if (!mounted) return;
      setState(() {
        _allAccounts = results[0].cast<Map<String, dynamic>>();
        _entries = results[1].cast<Map<String, dynamic>>();
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
              'Buku Besar',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Jurnal rinci per akun (real-time)',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
        actions: [
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
      body: MaxWidthBox(
        maxWidth: 1200,
        child: RefreshIndicator(
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
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
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
                  child: _LedgerView(
                    year: _year,
                    accountCode: _selectedCode,
                    accounts: _allAccounts,
                    entries: _entries,
                    onYearChanged: (y) {
                      setState(() => _year = y);
                      _loadData();
                    },
                    onAccountChanged: (code) {
                      setState(() => _selectedCode = code);
                      _loadData();
                    },
                  ),
                ),
        ),
      ),
    );
  }
}

class _LedgerView extends StatelessWidget {
  const _LedgerView({
    required this.year,
    required this.accountCode,
    required this.accounts,
    required this.entries,
    required this.onYearChanged,
    required this.onAccountChanged,
  });

  final int year;
  final String? accountCode;
  final List<Map<String, dynamic>> accounts;
  final List<Map<String, dynamic>> entries;
  final ValueChanged<int> onYearChanged;
  final ValueChanged<String?> onAccountChanged;

  @override
  Widget build(BuildContext context) {
    // Peta akun lengkap (Chart of Accounts): kode -> {name, account_type}.
    final accountMap = {for (final a in accounts) a['code'] as String: a};

    // Kelompokkan baris per akun (urutan akun mengikuti kode).
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final e in entries) {
      final code = (e['account_code'] as String?) ?? '';
      groups.putIfAbsent(code, () => []).add(e);
    }
    final displayedCodes = accountCode != null
        ? [accountCode!]
        : (groups.keys.toList()..sort());

    double totalDebit = 0;
    double totalCredit = 0;
    for (final e in entries) {
      totalDebit += ((e['debit_amount'] as num?)?.toDouble() ?? 0);
      totalCredit += ((e['credit_amount'] as num?)?.toDouble() ?? 0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Periode + filter akun
        Row(
          children: [
            Text(
              'Periode ',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            _YearStepper(year: year, onChanged: onYearChanged),
            const Spacer(),
            Flexible(
              child: _AccountDropdown(
                accounts: accounts,
                selectedCode: accountCode,
                onChanged: onAccountChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Ringkasan total jurnal terfilter
        _SummaryBar(totalDebit: totalDebit, totalCredit: totalCredit),
        const SizedBox(height: 12),

        // Bagian per akun
        if (displayedCodes.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              'Belum ada jurnal untuk $year.',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          )
        else
          ...displayedCodes.map((code) {
            final rows = groups[code] ?? [];
            final account = accountMap[code] ?? {};
            return _AccountSection(
              code: code,
              name: (account['name'] as String?) ?? code,
              type: (account['account_type'] as String?) ?? 'asset',
              rows: rows,
            );
          }),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.totalDebit, required this.totalCredit});

  final double totalDebit;
  final double totalCredit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.brand50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brand100),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: 'Total Debit',
              value: AppFormatters.rupiah(totalDebit),
              color: AppColors.brand800,
            ),
          ),
          Container(width: 1, height: 24, color: AppColors.brand100),
          Expanded(
            child: _SummaryItem(
              label: 'Total Kredit',
              value: AppFormatters.rupiah(totalCredit),
              color: const Color(0xFFB45309),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// Kartu satu akun: header (kode, nama, jenis, saldo akhir) + daftar jurnal.
class _AccountSection extends StatelessWidget {
  const _AccountSection({
    required this.code,
    required this.name,
    required this.type,
    required this.rows,
  });

  final String code;
  final String name;
  final String type;
  final List<Map<String, dynamic>> rows;

  Color get _typeColor {
    switch (type) {
      case 'asset':
        return AppColors.brand700;
      case 'liability':
        return const Color(0xFFB45309);
      case 'equity':
        return const Color(0xFF2563EB);
      case 'revenue':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFFDC2626);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Saldo berjalan (debit - kredit) sesuai urutan jurnal.
    double balance = 0;
    for (final r in rows) {
      balance += ((r['debit_amount'] as num?)?.toDouble() ?? 0);
      balance -= ((r['credit_amount'] as num?)?.toDouble() ?? 0);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header akun
          Container(
            color: _typeColor.withValues(alpha: 0.06),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _typeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    code,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            _typeLabel,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: _typeColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            rows.isEmpty
                                ? 'Tidak ada jurnal'
                                : '${rows.length} jurnal',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Saldo',
                      style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                    ),
                    Text(
                      AppFormatters.rupiah(balance),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: balance >= 0
                            ? AppColors.brand800
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Baris jurnal
          ...rows.map((r) => _LedgerRow(entry: r)),
        ],
      ),
    );
  }

  String get _typeLabel {
    switch (type) {
      case 'asset':
        return 'ASET';
      case 'liability':
        return 'KEWAJIBAN';
      case 'equity':
        return 'EKUITAS';
      case 'revenue':
        return 'PENDAPATAN';
      default:
        return 'BEBAN';
    }
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry});

  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final dateRaw = entry['entry_date'] as String? ?? '';
    final date = DateTime.tryParse(dateRaw);
    final debit = (entry['debit_amount'] as num?)?.toDouble() ?? 0;
    final credit = (entry['credit_amount'] as num?)?.toDouble() ?? 0;
    final description = (entry['description'] as String?)?.trim() ?? '—';
    final source = (entry['source_book'] as String?) ?? '';

    final amountColor = AppColors.brand900;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            child: Text(
              date != null ? AppFormatters.date(date) : dateRaw,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF374151),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _sourceLabel(source),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    if (entry['reference_type'] != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brand50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            entry['reference_type'] as String,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brand700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (debit > 0)
                Text(
                  'D ${AppFormatters.rupiah(debit)}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: amountColor,
                  ),
                )
              else
                Text(
                  'K ${AppFormatters.rupiah(credit)}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFB45309),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _sourceLabel(String book) {
    switch (book) {
      case 'cash':
        return 'Kas';
      case 'bank':
        return 'Bank';
      case 'savings':
        return 'Simpanan';
      case 'loan':
        return 'Pinjaman';
      case 'installment':
        return 'Angsuran';
      case 'fund':
        return 'Dana & SHU';
      case 'asset':
        return 'Aset';
      case 'chip_business':
      case 'usaha':
        return 'Usaha';
      case 'tax':
      case 'pajak':
        return 'Pajak';
      case 'opening':
        return 'Saldo Awal';
      case 'closing':
        return 'Penutup';
      default:
        return book;
    }
  }
}

class _AccountDropdown extends StatelessWidget {
  const _AccountDropdown({
    required this.accounts,
    required this.selectedCode,
    required this.onChanged,
  });

  final List<Map<String, dynamic>> accounts;
  final String? selectedCode;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = <String, String>{
      '': 'Semua Akun',
      for (final a in accounts)
        a['code'] as String: '${a['code']} — ${a['name']}',
    };

    return DropdownButtonFormField<String>(
      key: ValueKey(selectedCode),
      initialValue: selectedCode ?? '',
      isExpanded: false,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.grey[800],
      ),
      borderRadius: BorderRadius.circular(10),
      dropdownColor: Colors.white,
      items: items.entries
          .map(
            (e) => DropdownMenuItem<String>(
              value: e.key,
              child: Text(
                e.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (v) => onChanged(v == null || v.isEmpty ? null : v),
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
        Text('$year', style: const TextStyle(fontWeight: FontWeight.bold)),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => onChanged(year + 1),
          icon: const Icon(Icons.chevron_right, size: 20),
        ),
      ],
    );
  }
}
