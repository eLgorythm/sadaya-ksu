import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@lazySingleton
class AsetRemoteDataSource {
  AsetRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchAssets() async {
    final rows = await _client.from('assets').select().order('name');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> fetchDepreciations(int year) async {
    final rows = await _client
        .from('asset_depreciations')
        .select('*, assets(name)')
        .eq('fiscal_year', year)
        .order('book_value', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> insertAsset({
    required String name,
    String? description,
    required DateTime acquisitionDate,
    required double cost,
    required double salvageValue,
    required int usefulLifeYears,
  }) async {
    final row = await _client.from('assets').insert({
      'name': name,
      if (description != null && description.isNotEmpty)
        'description': description,
      'acquisition_date': acquisitionDate.toIso8601String().substring(0, 10),
      'acquisition_cost': cost,
      'salvage_value': salvageValue,
      'useful_life_years': usefulLifeYears,
    }).select('id').single();

    // Auto-post ke ledger: debit 1120 Inventaris / credit 1111 Kas
    await _client.rpc('post_asset_acquisition', params: {
      'p_asset_id': row['id'],
      'p_amount': cost,
      'p_date': acquisitionDate.toIso8601String().substring(0, 10),
      'p_description': 'Pembelian aset: $name',
    });
  }

  Future<void> updateAsset({
    required String id,
    required String name,
    String? description,
    required DateTime acquisitionDate,
    required double cost,
    required double salvageValue,
    required int usefulLifeYears,
  }) async {
    await _client.from('assets').update({
      'name': name,
      'description': (description != null && description.isNotEmpty)
          ? description
          : null,
      'acquisition_date': acquisitionDate.toIso8601String().substring(0, 10),
      'acquisition_cost': cost,
      'salvage_value': salvageValue,
      'useful_life_years': usefulLifeYears,
    }).eq('id', id);
  }

  /// Riwayat penyusutan terhapus otomatis (FK on delete cascade).
  Future<void> deleteAsset(String id) async {
    // Void jurnal ledger aset terlebih dahulu
    await _client.rpc('void_asset_ledger', params: {'p_asset_id': id});
    await _client.from('assets').delete().eq('id', id);
  }

  /// Regenerasi buku penyusutan tahun terpilih.
  /// Mengembalikan jumlah baris yang dibuat.
  Future<int> rpcRecalculateDepreciations(int year) async {
    final result = await _client.rpc(
      'recalculate_asset_depreciations',
      params: {'p_fiscal_year': year},
    );
    return (result as num).toInt();
  }
}
