import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/result.dart';
import '../entities/tax_entities.dart';
import '../repositories/pajak_repository.dart';

@injectable
class GetTaxes {
  GetTaxes(this._repository);

  final PajakRepository _repository;

  Future<Result<List<TaxItem>>> call() => _repository.getTaxes();
}

class InsertTaxParams extends Equatable {
  const InsertTaxParams({
    required this.taxType,
    this.description,
    required this.amount,
    required this.date,
    required this.status,
    this.referenceNumber,
    this.notes,
  });

  final String taxType;
  final String? description;
  final double amount;
  final DateTime date;
  final String status;
  final String? referenceNumber;
  final String? notes;

  @override
  List<Object?> get props => [
        taxType, description, amount, date, status,
        referenceNumber, notes,
      ];
}

@injectable
class InsertTax {
  InsertTax(this._repository);

  final PajakRepository _repository;

  Future<Result<void>> call(InsertTaxParams params) =>
      _repository.insertTax(
        taxType: params.taxType,
        description: params.description,
        amount: params.amount,
        date: params.date,
        status: params.status,
        referenceNumber: params.referenceNumber,
        notes: params.notes,
      );
}

@injectable
class UpdateTax {
  UpdateTax(this._repository);

  final PajakRepository _repository;

  Future<Result<void>> call(InsertTaxParams params, String id) =>
      _repository.updateTax(
        id: id,
        taxType: params.taxType,
        description: params.description,
        amount: params.amount,
        date: params.date,
        status: params.status,
        referenceNumber: params.referenceNumber,
        notes: params.notes,
      );
}

@injectable
class DeleteTax {
  DeleteTax(this._repository);

  final PajakRepository _repository;

  Future<Result<void>> call(String id) =>
      _repository.deleteTax(id);
}
