import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@lazySingleton
class LaporanRemoteDataSource {
  LaporanRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> getBalanceSheetData(int fiscalYear) async {
    final result = await _client.rpc(
      'get_balance_sheet_data',
      params: {'p_fiscal_year': fiscalYear},
    );
    final data = result as Map<String, dynamic>;
    final accounts = data['accounts'] as List<dynamic>? ?? [];
    return accounts.cast<Map<String, dynamic>>();
  }

  /// Daftar lengkap Chart of Accounts (untuk dropdown Buku Besar),
  /// apa pun status aktivitas jurnalnya.
  Future<List<Map<String, dynamic>>> getAllAccounts() async {
    final rows = await _client
        .from('chart_of_accounts')
        .select('code,name,account_type')
        .order('code');
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Baris jurnal buku besar untuk tahun fiskal (opsional per akun,
  /// jenis buku, dan rentang tanggal), diurutkan dari tanggal terlama
  /// kemudian waktu dibuat.
  Future<List<Map<String, dynamic>>> getLedgerEntries({
    required int fiscalYear,
    String? accountCode,
    String? sourceBook,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    var query = _client
        .from('ledger_entries')
        .select()
        .eq('is_void', false)
        .eq('fiscal_year', fiscalYear);
    if (accountCode != null) {
      query = query.eq('account_code', accountCode);
    }
    if (sourceBook != null && sourceBook.isNotEmpty) {
      query = query.eq('source_book', sourceBook);
    }
    if (fromDate != null) {
      query = query.gte(
        'entry_date',
        fromDate.toIso8601String().substring(0, 10),
      );
    }
    if (toDate != null) {
      query = query.lte(
        'entry_date',
        toDate.toIso8601String().substring(0, 10),
      );
    }
    final rows = await query
        .order('entry_date', ascending: true)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }
}
