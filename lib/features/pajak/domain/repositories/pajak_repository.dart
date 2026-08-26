import '../entities/tax_entities.dart';

import '../../../../core/utils/result.dart';

abstract class PajakRepository {
  Future<Result<List<TaxItem>>> getTaxes();
  Future<Result<void>> insertTax({
    required String taxType,
    String? description,
    required double amount,
    required DateTime date,
    required String status,
    String? referenceNumber,
    String? notes,
  });
  Future<Result<void>> updateTax({
    required String id,
    required String taxType,
    String? description,
    required double amount,
    required DateTime date,
    required String status,
    String? referenceNumber,
    String? notes,
  });
  Future<Result<void>> deleteTax(String id);
}
