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

/// Label 7 pos dana (urutan tampil di Buku Dana & pilihan sumber kas
/// masuk/keluar). Inventaris tidak termasuk → tidak bisa jadi sumber.
const Map<String, String> kFundPosLabels = {
  'welfare': 'Kesra (Kesejahteraan)',
  'social': 'Dana Sosial',
  'education': 'Dana Pendidikan',
  'crk': 'Dana CRK',
  'development': 'Dana Pembangunan',
  'japinup': 'Japinup',
  'swk': 'SWK',
};

/// Kode akun buku besar untuk tiap pos dana.
const Map<String, String> kFundPosAccounts = {
  'welfare': '2119',
  'social': '2114',
  'education': '2115',
  'crk': '3115',
  'development': '3114',
  'japinup': '4111',
  'swk': '2113',
};

/// Urutan tampil 7 pos dana di Buku Dana & form kas masuk/keluar.
const List<String> kFundPosOrder = [
  'welfare',
  'social',
  'education',
  'crk',
  'development',
  'japinup',
  'swk',
];

/// Saldo satu akun dari buku besar (nilai utuh |saldo natural|).
class LedgerBalance extends Equatable {
  const LedgerBalance({
    required this.code,
    required this.name,
    required this.balance,
  });

  final String code;
  final String name;
  final double balance;

  @override
  List<Object?> get props => [code, name, balance];
}

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

  String get fundLabel =>
      kFundPosLabels[fundType] ?? kFundLabels[fundType] ?? fundType;

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
    this.memberSavingsPct,
    this.memberServicePct,
    this.managementPct,
    this.staffPct,
    this.developmentPct,
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
  final double? memberSavingsPct;
  final double? memberServicePct;
  final double? managementPct;
  final double? staffPct;
  final double? developmentPct;
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
      (memberSavingsPct ?? 0) +
      (memberServicePct ?? 0) +
      (managementPct ?? 0) +
      (staffPct ?? 0) +
      (developmentPct ?? 0);

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
    memberSavingsPct,
    memberServicePct,
    managementPct,
    staffPct,
    developmentPct,
    distributionDate,
    notes,
  ];
}
