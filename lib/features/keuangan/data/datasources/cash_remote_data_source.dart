import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@Injectable()
class CashRemoteDataSource {
  CashRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchEntries(String book) async {
    final rows = book == 'cash'
        ? await _client
            .from('cash_transactions')

            /// Embed nama kategori via FK category_id.
            .select('*, transaction_categories(code, name)')
            .eq('is_void', false)
            .order('transaction_date', ascending: false)
            .order('created_at', ascending: false)
        : await _client
            .from('bank_transactions')
            .select()
            .eq('is_void', false)
            .order('transaction_date', ascending: false)
            .order('created_at', ascending: false);
    return rows.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final rows = await _client
        .from('transaction_categories')
        .select('code, name, category_type')
        .order('code');
    return rows.cast<Map<String, dynamic>>();
  }

  /// Ringkasan buku kas dari buku besar: total aset lancar + rincian per akun.
  Future<Map<String, dynamic>> fetchLedgerSummary(int year) async {
    final result = await _client.rpc(
      'get_aset_lancar_summary',
      params: {'p_year': year},
    );
    return result as Map<String, dynamic>;
  }

  Future<void> rpcCreateEntry({
    required String book,
    required String direction,
    required String counterAccount,
    required double amount,
    required DateTime date,
    required String description,
  }) async {
    await _client.rpc('create_cash_book_transaction', params: {
      'p_book': book,
      'p_direction': direction,
      'p_counter_account': counterAccount,

      /// PENTING: key bernilai null eksplisit menimpa DEFAULT Postgres;
      /// tanggal selalu diisi sehingga tidak jadi masalah di sini.
      'p_amount': amount,
      'p_description': description,
      'p_date': date.toIso8601String().substring(0, 10),
    });
  }

  /// Membuat kategori baru + kode COA otomatis di server.
  /// Mengembalikan kode baru.
  Future<String> rpcCreateCategory({
    required String name,
    required bool isIncome,
  }) async {
    final code = await _client.rpc('create_transaction_category', params: {
      'p_name': name,
      'p_type': isIncome ? 'income' : 'expense',
    });
    return code as String;
  }
}
