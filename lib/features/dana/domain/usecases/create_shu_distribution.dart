import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../repositories/dana_repository.dart';

class CreateShuDistributionParams extends Equatable {
  const CreateShuDistributionParams({
    required this.fiscalYear,
    required this.totalShu,
    this.taxAmount = 0,
    this.reservePct,
    this.socialPct,
    this.educationPct,
    this.memberSavingsPct,
    this.memberServicePct,
    this.managementPct,
    this.staffPct,
    this.developmentPct,
    this.notes,
  });

  final int fiscalYear;
  final double totalShu;
  final double taxAmount;
  final double? reservePct;
  final double? socialPct;
  final double? educationPct;
  final double? memberSavingsPct;
  final double? memberServicePct;
  final double? managementPct;
  final double? staffPct;
  final double? developmentPct;
  final String? notes;

  /// Net SHU = total dikurangi pajak.
  double get netShu => totalShu - taxAmount;

  /// Total persentase alokasi (fraksi).
  double get totalPct =>
      (reservePct ?? 0) +
      (socialPct ?? 0) +
      (educationPct ?? 0) +
      (memberSavingsPct ?? 0) +
      (memberServicePct ?? 0) +
      (managementPct ?? 0) +
      (staffPct ?? 0) +
      (developmentPct ?? 0);

  /// Validasi bersama untuk create & update.
  String? validate() {
    if (fiscalYear < 2000 || fiscalYear > 2100) {
      return 'Tahun fiskal tidak valid';
    }
    if (totalShu <= 0) {
      return 'Total SHU harus lebih dari 0';
    }
    if (taxAmount < 0) {
      return 'Pajak tidak boleh negatif';
    }
    if (netShu <= 0) {
      return 'Net SHU harus positif setelah pajak';
    }
    for (final pct in [
      reservePct,
      socialPct,
      educationPct,
      memberSavingsPct,
      memberServicePct,
      managementPct,
      staffPct,
      developmentPct,
    ]) {
      final value = pct ?? 0;
      if (value < 0 || value > 1) {
        return 'Persentase alokasi harus antara 0-100%';
      }
    }
    if (totalPct > 1.000001) {
      return 'Total persentase alokasi melebihi 100%';
    }
    return null;
  }

  @override
  List<Object?> get props => [
    fiscalYear,
    totalShu,
    taxAmount,
    reservePct,
    socialPct,
    educationPct,
    memberSavingsPct,
    memberServicePct,
    managementPct,
    staffPct,
    developmentPct,
    notes,
  ];
}

/// Menyimpan perhitungan SHU tahunan sebagai draft.
@injectable
class CreateShuDistribution {
  CreateShuDistribution(this._repository);

  final DanaRepository _repository;

  Future<Result<String>> call(CreateShuDistributionParams params) async {
    final error = params.validate();
    if (error != null) {
      return Err(Failure(message: error));
    }
    return _repository.createShuDistribution(
      fiscalYear: params.fiscalYear,
      totalShu: params.totalShu,
      taxAmount: params.taxAmount,
      netShu: params.netShu,
      reservePct: params.reservePct,
      socialPct: params.socialPct,
      educationPct: params.educationPct,
      memberSavingsPct: params.memberSavingsPct,
      memberServicePct: params.memberServicePct,
      managementPct: params.managementPct,
      staffPct: params.staffPct,
      developmentPct: params.developmentPct,
      notes: params.notes?.trim(),
    );
  }
}

/// Memperbarui hitungan SHU yang masih draft.
@injectable
class UpdateShuDistribution {
  UpdateShuDistribution(this._repository);

  final DanaRepository _repository;

  Future<Result<void>> call(
    String id,
    CreateShuDistributionParams params,
  ) async {
    final error = params.validate();
    if (error != null) {
      return Err(Failure(message: error));
    }
    return _repository.updateShuDistribution(
      id: id,
      fiscalYear: params.fiscalYear,
      totalShu: params.totalShu,
      taxAmount: params.taxAmount,
      netShu: params.netShu,
      reservePct: params.reservePct,
      socialPct: params.socialPct,
      educationPct: params.educationPct,
      memberSavingsPct: params.memberSavingsPct,
      memberServicePct: params.memberServicePct,
      managementPct: params.managementPct,
      staffPct: params.staffPct,
      developmentPct: params.developmentPct,
      notes: params.notes?.trim(),
    );
  }
}
