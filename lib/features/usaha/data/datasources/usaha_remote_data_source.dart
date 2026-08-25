import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@lazySingleton
class UsahaRemoteDataSource {
  UsahaRemoteDataSource(this._client);

  final SupabaseClient _client;

  // ---------- Bahan baku ----------
  Future<List<Map<String, dynamic>>> fetchMaterials() async {
    final rows = await _client
        .from('chip_raw_materials')
        .select()
        .order('name');
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Daftarkan jenis bahan baru (master data, stok mulai 0).
  Future<void> insertMaterial({
    required String name,
    required String unit,
  }) async {
    await _client.from('chip_raw_materials').insert({
      'name': name,
      'unit': unit,
    });
  }

  /// Catat beli/pakai + sesuaikan stok (atomik di server).
  Future<double> rpcRecordMaterialTransaction({
    required String materialId,
    required String type,
    required double quantity,
    double? unitPrice,
    required DateTime date,
    String? notes,
  }) async {
    final result = await _client.rpc(
      'record_material_transaction',
      params: {
        'p_material_id': materialId,
        'p_type': type,
        'p_quantity': quantity,
        'p_unit_price': ?unitPrice,
        'p_date': date.toIso8601String().substring(0, 10),
        if (notes != null && notes.isNotEmpty) 'p_notes': notes,
      },
    );
    return (result as num).toDouble();
  }

  Future<List<Map<String, dynamic>>> fetchMaterialTransactions() async {
    final rows = await _client
        .from('chip_material_transactions')
        .select('*, chip_raw_materials(name)')
        .order('transaction_date', ascending: false)
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(rows);
  }

  // ---------- Produksi ----------
  Future<List<Map<String, dynamic>>> fetchProductions() async {
    final rows = await _client
        .from('chip_productions')
        .select()
        .order('production_date', ascending: false)
        .limit(100);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> insertProduction({
    required String productType,
    required DateTime date,
    required double quantity,
    required String unit,
    double? quantityPack,
    double? cost,
    String? notes,
  }) async {
    await _client.from('chip_productions').insert({
      'product_type': productType,
      'production_date': date.toIso8601String().substring(0, 10),
      'quantity_produced': quantity,
      'unit': unit,
      'quantity_pack': ?quantityPack,
      'production_cost': ?cost,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'created_by': _client.auth.currentUser?.id,
    });
  }

  // ---------- Penjualan ----------
  Future<List<Map<String, dynamic>>> fetchSales() async {
    final rows = await _client
        .from('chip_sales')
        .select()
        .order('sale_date', ascending: false)
        .limit(100);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> insertSale({
    required String productType,
    required DateTime date,
    required double quantity,
    required String unit,
    required double unitPrice,
    String? buyer,
    String? notes,
  }) async {
    await _client.from('chip_sales').insert({
      'product_type': productType,
      'sale_date': date.toIso8601String().substring(0, 10),
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice,
      'total_price': quantity * unitPrice,
      if (buyer != null && buyer.isNotEmpty) 'buyer': buyer,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'created_by': _client.auth.currentUser?.id,
    });
  }

  Future<void> deleteSale(String id) async {
    await _client.from('chip_sales').delete().eq('id', id);
  }
}
