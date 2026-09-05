import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/tax_entities.dart';
import '../../domain/repositories/pajak_repository.dart';
import '../datasources/pajak_remote_data_source.dart';

@LazySingleton(as: PajakRepository)
class PajakRepositoryImpl implements PajakRepository {
  PajakRepositoryImpl(this._remoteDataSource);

  final PajakRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<TaxItem>>> getTaxes() async {
    try {
      final rows = await _remoteDataSource.fetchTaxes();
      final items = rows
          .map(
            (r) => TaxItem(
              id: r['id'] as String,
              taxType: r['tax_type'] as String,
              description: r['description'] as String?,
              amount: (r['amount'] as num).toDouble(),
              taxDate: DateTime.parse(r['tax_date'] as String),
              status: r['status'] as String,
              referenceNumber: r['reference_number'] as String?,
              notes: r['notes'] as String?,
            ),
          )
          .toList();
      return Ok(items);
    } catch (e) {
      return Err(Failure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> insertTax({
    required String taxType,
    String? description,
    required double amount,
    required DateTime date,
    required String status,
    String? referenceNumber,
    String? notes,
  }) async {
    try {
      await _remoteDataSource.insertTax(
        taxType: taxType,
        description: description,
        amount: amount,
        date: date,
        status: status,
        referenceNumber: referenceNumber,
        notes: notes,
      );
      return const Ok(null);
    } catch (e) {
      return Err(Failure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> updateTax({
    required String id,
    required String taxType,
    String? description,
    required double amount,
    required DateTime date,
    required String status,
    String? referenceNumber,
    String? notes,
  }) async {
    try {
      await _remoteDataSource.updateTax(
        id: id,
        taxType: taxType,
        description: description,
        amount: amount,
        date: date,
        status: status,
        referenceNumber: referenceNumber,
        notes: notes,
      );
      return const Ok(null);
    } catch (e) {
      return Err(Failure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteTax(String id) async {
    try {
      await _remoteDataSource.deleteTax(id);
      return const Ok(null);
    } catch (e) {
      return Err(Failure(message: e.toString()));
    }
  }
}
