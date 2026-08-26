import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@lazySingleton
class PajakRemoteDataSource {
  PajakRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchTaxes() async {
    final rows = await _client
        .from('taxes')
        .select()
        .order('tax_date', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<String> insertTax({
    required String taxType,
    String? description,
    required double amount,
    required DateTime date,
    required String status,
    String? referenceNumber,
    String? notes,
  }) async {
    final result = await _client.rpc('insert_tax', params: {
      'p_tax_type': taxType,
      'p_description': description,
      'p_amount': amount,
      'p_date': date.toIso8601String().substring(0, 10),
      'p_status': status,
      'p_reference_number': referenceNumber,
      'p_notes': notes,
    });
    return result as String;
  }

  Future<void> updateTax({
    required String id,
    required String taxType,
    String? description,
    required double amount,
    required DateTime date,
    required String status,
    String? referenceNumber,
    String? notes,
  }) async {
    await _client.rpc('update_tax', params: {
      'p_id': id,
      'p_tax_type': taxType,
      'p_description': description,
      'p_amount': amount,
      'p_date': date.toIso8601String().substring(0, 10),
      'p_status': status,
      'p_reference_number': referenceNumber,
      'p_notes': notes,
    });
  }

  Future<void> deleteTax(String id) async {
    await _client.rpc('delete_tax', params: {'p_id': id});
  }
}
