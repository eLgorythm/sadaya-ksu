import 'package:equatable/equatable.dart';

class TaxItem extends Equatable {
  const TaxItem({
    required this.id,
    required this.taxType,
    this.description,
    required this.amount,
    required this.taxDate,
    required this.status,
    this.referenceNumber,
    this.notes,
  });

  final String id;
  final String taxType;
  final String? description;
  final double amount;
  final DateTime taxDate;
  final String status;
  final String? referenceNumber;
  final String? notes;

  bool get isPaid => status == 'paid';

  @override
  List<Object?> get props => [
        id, taxType, description, amount, taxDate, status,
        referenceNumber, notes,
      ];
}
