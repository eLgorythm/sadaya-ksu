import 'package:equatable/equatable.dart';

/// Label tampilan untuk tiap jenis dana koperasi.
const Map<String, String> kFundLabels = {
  'social': 'Dana Sosial',
  'education': 'Dana Pendidikan',
  'welfare': 'Dana Kesejahteraan',
  'crk': 'Dana CRK',
  'development': 'Dana Pembangunan',
  'reserve': 'Dana Cadangan',
};

class FundTransaction extends Equatable {
  const FundTransaction({
    required this.id,
    required this.fundType,
    required this.isIncoming,
    required this.date,
    required this.amount,
    required this.description,
    this.sourceType,
  });

  final String id;
  final String fundType;
  final bool isIncoming;
  final DateTime date;
  final double amount;
  final String description;
  final String? sourceType;

  String get fundLabel => kFundLabels[fundType] ?? fundType;

  @override
  List<Object?> get props => [
        id,
        fundType,
        isIncoming,
        date,
        amount,
        description,
        sourceType,
      ];
}

/// Hasil perhitungan SHU dari buku besar (ledger).
class ShuCalculation extends Equatable {
  const ShuCalculation({
    required this.totalRevenue,
    required this.totalExpense,
    required this.netShu,
  });

  final double totalRevenue;
  final double totalExpense;
  final double netShu;

  @override
  List<Object?> get props => [totalRevenue, totalExpense, netShu];
}

class ShuDistribution extends Equatable {
  const ShuDistribution({
    required this.id,
    required this.fiscalYear,
    required this.totalShu,
    required this.taxAmount,
    required this.netShu,
    required this.status,
    this.reservePct,
    this.socialPct,
    this.educationPct,
    this.memberDividendPct,
    this.managementPct,
    this.distributionDate,
    this.notes,
  });

  final String id;
  final int fiscalYear;
  final double totalShu;
  final double taxAmount;
  final double netShu;
  final String status;
  final double? reservePct;
  final double? socialPct;
  final double? educationPct;
  final double? memberDividendPct;
  final double? managementPct;
  final DateTime? distributionDate;
  final String? notes;

  bool get isDraft => status == 'draft';
  bool get isApproved => status == 'approved';
  bool get isDistributed => status == 'distributed';

  double allocationOf(double? pct) => (netShu * (pct ?? 0));

  /// Total persentase alokasi yang sudah ditetapkan (fraksi 0..n).
  double get totalAllocatedPct =>
      (reservePct ?? 0) +
      (socialPct ?? 0) +
      (educationPct ?? 0) +
      (memberDividendPct ?? 0) +
      (managementPct ?? 0);

  @override
  List<Object?> get props => [
        id,
        fiscalYear,
        totalShu,
        taxAmount,
        netShu,
        status,
        reservePct,
        socialPct,
        educationPct,
        memberDividendPct,
        managementPct,
        distributionDate,
        notes,
      ];
}
