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
}
