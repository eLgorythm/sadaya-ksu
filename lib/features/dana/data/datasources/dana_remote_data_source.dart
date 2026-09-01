import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@lazySingleton
class DanaRemoteDataSource {
  DanaRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchFundTransactions() async {
    final rows = await _client
        .from('fund_transactions')
        .select()
        .eq('is_void', false)
        .order('transaction_date', ascending: false)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> insertFundTransaction({
    required String fundType,
    required bool isIncoming,
    required double amount,
    required String description,
    required DateTime date,
  }) async {
    await _client.from('fund_transactions').insert({
      'fund_type': fundType,
      'transaction_type': isIncoming ? 'income' : 'expense',
      'transaction_date': date.toIso8601String().substring(0, 10),
      'amount': amount,
      'description': description,
      'source_type': 'manual',
    });
  }

  Future<Map<String, dynamic>> fetchShuCalculation(int fiscalYear) async {
    final result = await _client
        .rpc('calculate_shu_for_year', params: {'p_year': fiscalYear});
    if (result == null || (result as List).isEmpty) {
      return {'total_revenue': 0, 'total_expense': 0, 'net_shu': 0};
    }
    return Map<String, dynamic>.from(result.first);
  }

  Future<List<Map<String, dynamic>>> fetchShuDistributions() async {
    final rows = await _client
        .from('shu_distributions')
        .select()
        .order('fiscal_year', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<String> insertShuDistribution({
    required int fiscalYear,
    required double totalShu,
    required double taxAmount,
    required double netShu,
    double? reservePct,
    double? socialPct,
    double? educationPct,
    double? memberSavingsPct,
    double? memberServicePct,
    double? managementPct,
    double? staffPct,
    double? developmentPct,
    String? notes,
  }) async {
    final row = await _client
        .from('shu_distributions')
        .insert({
          'fiscal_year': fiscalYear,
          'total_shu': totalShu,
          'tax_amount': taxAmount,
          'net_shu': netShu,
          'reserve_fund_pct': reservePct ?? 0,
          'social_fund_pct': socialPct ?? 0,
          'education_fund_pct': educationPct ?? 0,
          'member_savings_pct': memberSavingsPct ?? 0.30,
          'member_service_pct': memberServicePct ?? 0.25,
          'management_pct': managementPct ?? 0,
          'staff_pct': staffPct ?? 0,
          'development_pct': developmentPct ?? 0,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  /// Memperbarui hitungan SHU yang masih draft.
  Future<void> updateShuDistribution({
    required String id,
    required int fiscalYear,
    required double totalShu,
    required double taxAmount,
    required double netShu,
    double? reservePct,
    double? socialPct,
    double? educationPct,
    double? memberSavingsPct,
    double? memberServicePct,
    double? managementPct,
    double? staffPct,
    double? developmentPct,
    String? notes,
  }) async {
    await _client.from('shu_distributions').update({
      'fiscal_year': fiscalYear,
      'total_shu': totalShu,
      'tax_amount': taxAmount,
      'net_shu': netShu,
      'reserve_fund_pct': reservePct ?? 0,
      'social_fund_pct': socialPct ?? 0,
      'education_fund_pct': educationPct ?? 0,
'member_savings_pct': memberSavingsPct ?? 0.30,
'member_service_pct': memberServicePct ?? 0.25,
        'management_pct': managementPct ?? 0,
      'staff_pct': staffPct ?? 0,
      'development_pct': developmentPct ?? 0,
      'notes': (notes != null && notes.isNotEmpty) ? notes : null,
    }).eq('id', id);
  }

  Future<void> rpcDistributeShu(String distributionId) async {
    await _client.rpc(
      'distribute_shu',
      params: {'p_distribution_id': distributionId},
    );
  }

  /// Membatalkan distribusi: alokasi buku dana dicabut,
  /// status kembali ke draft.
  Future<void> rpcCancelShuDistribution(String distributionId) async {
    await _client.rpc(
      'cancel_shu_distribution',
      params: {'p_distribution_id': distributionId},
    );
  }

  /// Menyetujui draft SHU (RLS pengurus memperbolehkan update langsung).
  Future<void> updateShuStatus({
    required String distributionId,
    required String status,
  }) async {
    await _client.from('shu_distributions').update({
      'status': status,
    }).eq('id', distributionId);
  }

  /// Menghapus SHU yang belum terdistribusi.
  Future<void> deleteShu(String distributionId) async {
    await _client
        .from('shu_distributions')
        .delete()
        .eq('id', distributionId);
  }
}
