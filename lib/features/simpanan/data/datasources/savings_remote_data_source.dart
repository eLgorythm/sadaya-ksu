import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@lazySingleton
class SavingsRemoteDataSource {
  SavingsRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchTypes() async {
    final rows = await _client.from('savings_types').select().order('code');
    return rows.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchMemberTransactions(
    String memberId,
  ) async {
    PostgrestFilterBuilder<List<dynamic>> query = _client
        .from('savings_transactions')
        .select('*, savings_types(code, name)')
        .eq('member_id', memberId);
    final rows = await query.order('transaction_date', ascending: false);
    return rows.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> rpcCreateTransaction({
    required String memberId,
    required String typeCode,
    required String transactionType,
    required double amount,
    String? description,
  }) {
    return _client
        .rpc(
          'create_savings_transaction',
          params: {
            'p_member_id': memberId,
            'p_savings_type_code': typeCode,
            'p_transaction_type': transactionType,
            'p_amount': amount,
            'p_description': description,
          },
        )
        .select()
        .single();
  }
}
