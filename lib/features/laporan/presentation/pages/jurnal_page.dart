import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../data/datasources/laporan_remote_data_source.dart';

/// Jurnal Umum — log kronologis seluruh transaksi buku besar.
///
/// Berbeda dengan Buku Besar (yang mengelompokkan per akun), Jurnal Umum
/// menampilkan seluruh baris jurnal secara kronologis sehingga terlihat
/// urutan terjadinya transaksi. Dapat difilter berdasarkan:
/// - Tahun buku
/// - Akun
/// - Jenis buku (source_book: kas, bank, simpanan, dll)
/// - Rentang tanggal
class JurnalPage extends StatefulWidget {
  const JurnalPage({super.key});

  @override
  State<JurnalPage> createState() => _JurnalPageState();
}

class _JurnalPageState extends State<JurnalPage> {
  int _year = DateTime.now().year;
  String? _selectedCode;
  String? _selectedBook;
  DateTime? _fromDate;
  DateTime? _toDate;
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
        ds.getLedgerEntries(
          fiscalYear: _year,
          accountCode: _selectedCode,
          sourceBook: _selectedBook,
          fromDate: _fromDate,
          toDate: _toDate,
        ),
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

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime(_year, 1, 1),
      firstDate: DateTime(_year - 10, 1, 1),
      lastDate: DateTime(_year + 1, 12, 31),
      helpText: 'Pilih tanggal awal',
    );
    if (picked == null) return;
    setState(() {
      _fromDate = picked;
      if (_toDate != null && _toDate!.isBefore(picked)) _toDate = null;
    });
    _loadData();
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime(_year, 12, 31),
      firstDate: DateTime(_year - 10, 1, 1),
      lastDate: DateTime(_year + 1, 12, 31),
      helpText: 'Pilih tanggal akhir',
    );
    if (picked == null) return;
    setState(() {
      _toDate = picked;
      if (_fromDate != null && _fromDate!.isAfter(picked)) _fromDate = null;
    });
    _loadData();
  }

  void _clearDateRange() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    _loadData();
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
              'Jurnal',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              'Log transaksi kronologis (real-time)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
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
                    child: _JournalView(
                      year: _year,
                      accountCode: _selectedCode,
                      sourceBook: _selectedBook,
                      fromDate: _fromDate,
                      toDate: _toDate,
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
                      onBookChanged: (book) {
                        setState(() => _selectedBook = book);
                        _loadData();
                      },
                      onPickFrom: _pickFromDate,
                      onPickTo: _pickToDate,
                      onClearDate: _clearDateRange,
                    ),
                  ),
      ),
    );
  }
}

class _JournalView extends StatelessWidget {
  const _JournalView({
    required this.year,
    required this.accountCode,
    required this.sourceBook,
    required this.fromDate,
    required this.toDate,
    required this.accounts,
    required this.entries,
    required this.onYearChanged,
    required this.onAccountChanged,
    required this.onBookChanged,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onClearDate,
  });

  final int year;
  final String? accountCode;
  final String? sourceBook;
  final DateTime? fromDate;
  final DateTime? toDate;
  final List<Map<String, dynamic>> accounts;
  final List<Map<String, dynamic>> entries;
  final ValueChanged<int> onYearChanged;
  final ValueChanged<String?> onAccountChanged;
  final ValueChanged<String?> onBookChanged;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onClearDate;

  @override
  Widget build(BuildContext context) {
    final accountMap = {
      for (final a in accounts) a['code'] as String: a,
    };

    // Kelompokkan baris per tanggal jurnal (kronologis).
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final e in entries) {
      final d = (e['entry_date'] as String?) ?? '';
      groups.putIfAbsent(d, () => []).add(e);
    }
    final dates = groups.keys.toList()..sort();

    double totalDebit = 0;
    double totalCredit = 0;
    for (final e in entries) {
      totalDebit += ((e['debit_amount'] as num?)?.toDouble() ?? 0);
      totalCredit += ((e['credit_amount'] as num?)?.toDouble() ?? 0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filter baris: tahun + akun + jenis buku
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Periode ',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                _YearStepper(year: year, onChanged: onYearChanged),
              ],
            ),
            SizedBox(
              width: 190,
              child: _AccountDropdown(
                accounts: accounts,
                selectedCode: accountCode,
                onChanged: onAccountChanged,
              ),
            ),
            SizedBox(
              width: 150,
              child: _BookDropdown(
                selectedBook: sourceBook,
                onChanged: onBookChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Rentang tanggal + tombol reset
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _DateChip(
                label: fromDate == null
                    ? 'Dari tgl'
                    : 'Dari ${AppFormatters.date(fromDate!)}',
                onTap: onPickFrom,
              ),
              Text('-', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              _DateChip(
                label: toDate == null
                    ? 's/d tgl'
                    : 's/d ${AppFormatters.date(toDate!)}',
                onTap: onPickTo,
              ),
              if (fromDate != null || toDate != null)
                InkWell(
                  onTap: onClearDate,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      'Reset rentang',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.brand700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        _SummaryBar(totalDebit: totalDebit, totalCredit: totalCredit),
        const SizedBox(height: 12),

        if (dates.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              'Belum ada jurnal untuk filter ini.',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          )
        else
          ...dates.map((date) {
            final rows = groups[date] ?? [];
            return _DateSection(
              date: date,
              accountMap: accountMap,
              rows: rows,
            );
          }),
        if (dates.isNotEmpty) const SizedBox(height: 8),
      ],
    );
  }
}

/// Satu kelompok jurnal per tanggal: header tanggal + baris debit/kredit.
class _DateSection extends StatelessWidget {
  const _DateSection({
    required this.date,
    required this.accountMap,
    required this.rows,
  });

  final String date;
  final Map<String, dynamic> accountMap;
  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    final parsed = DateTime.tryParse(date);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 0, 4),
          child: Text(
            parsed != null ? AppFormatters.date(parsed) : date,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        Container(
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
            children: rows.map((r) => _JournalRow(entry: r, accountMap: accountMap)).toList(),
          ),
        ),
      ],
    );
  }
}

class _JournalRow extends StatelessWidget {
  const _JournalRow({required this.entry, required this.accountMap});

  final Map<String, dynamic> entry;
  final Map<String, dynamic> accountMap;

  @override
  Widget build(BuildContext context) {
    final code = (entry['account_code'] as String?) ?? '';
    final account = accountMap[code] ?? {};
    final name = (account['name'] as String?) ?? code;
    final type = (account['account_type'] as String?) ?? 'asset';
    final debit = (entry['debit_amount'] as num?)?.toDouble() ?? 0;
    final credit = (entry['credit_amount'] as num?)?.toDouble() ?? 0;
    final description = (entry['description'] as String?)?.trim() ?? '—';
    final source = (entry['source_book'] as String?) ?? '';
    final refType = (entry['reference_type'] as String?) ?? '';

    final amountColor = AppColors.brand900;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: _typeColor(type).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              code,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _typeColor(type),
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
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
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
                    if (refType.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.brand50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            refType,
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
                  AppFormatters.rupiah(debit),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: amountColor,
                  ),
                )
              else
                Text(
                  AppFormatters.rupiah(credit),
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

  Color _typeColor(String type) {
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
        return book.isNotEmpty ? book : '—';
    }
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

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 13, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[800]),
            ),
          ],
        ),
      ),
    );
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
        a['code'] as String:
            '${a['code']} — ${a['name']}',
    };

    return DropdownButtonFormField<String>(
      key: ValueKey(selectedCode),
      initialValue: selectedCode ?? '',
      isExpanded: false,
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
          .map((e) => DropdownMenuItem<String>(
                value: e.key,
                child: Text(
                  e.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: (v) => onChanged(v == null || v.isEmpty ? null : v),
    );
  }
}

class _BookDropdown extends StatelessWidget {
  const _BookDropdown({required this.selectedBook, required this.onChanged});

  final String? selectedBook;
  final ValueChanged<String?> onChanged;

  static const _books = <String, String>{
    '': 'Semua Buku',
    'cash': 'Kas',
    'bank': 'Bank',
    'savings': 'Simpanan',
    'loan': 'Pinjaman',
    'installment': 'Angsuran',
    'fund': 'Dana & SHU',
    'asset': 'Aset',
    'chip_business': 'Usaha',
    'tax': 'Pajak',
    'opening': 'Saldo Awal',
  };

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey(selectedBook),
      initialValue: selectedBook ?? '',
      isExpanded: false,
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
      items: _books.entries
          .map((e) => DropdownMenuItem<String>(
                value: e.key,
                child: Text(e.value),
              ))
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