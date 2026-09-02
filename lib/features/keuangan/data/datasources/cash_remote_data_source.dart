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

  /// Ringkasan buku kas dari buku besar: total saldo koperasi +
  /// rincian per akun (kas + bank + piutang + dana + Japinup).
  Future<Map<String, dynamic>> fetchLedgerSummary(int year) async {
    final result = await _client.rpc(
      'get_cash_ledger_summary',
      params: {'p_year': year},
    );
    return result as Map<String, dynamic>;
  }

  /// Pemasukan Kas (akun 1111) per sumber (angsuran pinjaman, simpanan
  /// manasuka, cair dari bank) untuk tab Kas.
  Future<Map<String, dynamic>> fetchCashSources(int year) async {
    final result = await _client.rpc(
      'get_cash_sources',
      params: {'p_year': year},
    );
    return result as Map<String, dynamic>;
  }

  /// Dana masuk ke rekening dari luar (investor/dll), tanpa kategori.
  /// Debit Bank 1112 / Kredit Modal Penyertaan 3117.
  Future<void> rpcBankDanaMasuk({
    required double amount,
    required DateTime date,
    required String description,
  }) async {
    await _client.rpc('bank_dana_masuk', params: {
      'p_amount': amount,
      'p_description': description,
      'p_date': date.toIso8601String().substring(0, 10),
    });
  }

  /// Tarik tunai dari rekening ke kas. Debit Kas 1111 / Kredit Bank 1112.
  Future<void> rpcBankCairKas({
    required double amount,
    required DateTime date,
    required String description,
  }) async {
    await _client.rpc('bank_cair_ke_kas', params: {
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
