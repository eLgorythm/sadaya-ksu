import '../../domain/entities/dana_entities.dart';

class FundTransactionModel extends FundTransaction {
  const FundTransactionModel({
    required super.id,
    required super.fundType,
    required super.isIncoming,
    required super.date,
    required super.amount,
    required super.description,
    required super.sourceType,
  });

  factory FundTransactionModel.fromMap(Map<String, dynamic> map) {
    return FundTransactionModel(
      id: map['id'] as String,
      fundType: map['fund_type'] as String,
      isIncoming: map['transaction_type'] == 'income',
      date: DateTime.parse(map['transaction_date'] as String),
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      sourceType: map['source_type'] as String?,
    );
  }
}

class ShuDistributionModel extends ShuDistribution {
  const ShuDistributionModel({
    required super.id,
    required super.fiscalYear,
    required super.totalShu,
    required super.taxAmount,
    required super.netShu,
    required super.status,
    required super.reservePct,
    required super.socialPct,
    required super.educationPct,
    required super.memberSavingsPct,
    required super.memberServicePct,
    required super.managementPct,
    required super.staffPct,
    required super.developmentPct,
    required super.distributionDate,
    required super.notes,
  });

  factory ShuDistributionModel.fromMap(Map<String, dynamic> map) {
    return ShuDistributionModel(
      id: map['id'] as String,
      fiscalYear: map['fiscal_year'] as int,
      totalShu: (map['total_shu'] as num).toDouble(),
      taxAmount: (map['tax_amount'] as num).toDouble(),
      netShu: (map['net_shu'] as num).toDouble(),
      status: map['status'] as String,
      reservePct: _pct(map['reserve_fund_pct']),
      socialPct: _pct(map['social_fund_pct']),
      educationPct: _pct(map['education_fund_pct']),
      memberSavingsPct: _pct(map['member_savings_pct']),
      memberServicePct: _pct(map['member_service_pct']),
      managementPct: _pct(map['management_pct']),
      staffPct: _pct(map['staff_pct']),
      developmentPct: _pct(map['development_pct']),
      distributionDate: map['distribution_date'] == null
          ? null
          : DateTime.parse(map['distribution_date'] as String),
      notes: map['notes'] as String?,
    );
  }

  static double? _pct(Object? value) =>
      value == null ? null : (value as num).toDouble();
}
