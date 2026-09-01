import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/loan_entities.dart';
import '../../domain/repositories/loan_repository.dart';
import '../datasources/loan_remote_data_source.dart';
import '../models/loan_models.dart';

@LazySingleton(as: LoanRepository)
class LoanRepositoryImpl implements LoanRepository {
  LoanRepositoryImpl(this._dataSource);

  final LoanRemoteDataSource _dataSource;

  @override
  Future<Result<List<LoanEntity>>> getMemberLoans(String memberId) async {
    try {
      final rows = await _dataSource.fetchMemberLoans(memberId);
      return Ok(rows.map(LoanModel.fromMap).toList());
    } on PostgrestException catch (e) {
      return Err(Failure(message: 'Gagal memuat pinjaman (${e.message})'));
    } catch (_) {
      return const Err(
          Failure(message: 'Gagal memuat pinjaman. Periksa koneksi'));
    }
  }

  @override
  Future<Result<LoanDetail>> getLoanDetail(String loanId) async {
    try {
      final schedules = await _dataSource.fetchSchedules(loanId);
      final loanRow = await _dataSource.fetchLoanById(loanId);
      if (loanRow == null) {
        return const Err(Failure(message: 'Pinjaman tidak ditemukan'));
      }
      return Ok(LoanDetail(
        loan: LoanModel.fromMap(loanRow),
        schedules:
            schedules.map(InstallmentScheduleModel.fromMap).toList(),
      ));
    } on PostgrestException catch (e) {
      return Err(Failure(message: 'Gagal memuat detail (${e.message})'));
    } catch (_) {
      return const Err(
          Failure(message: 'Gagal memuat detail. Periksa koneksi'));
    }
  }

  @override
  Future<Result<LoanEntity>> createLoan({
    required String memberId,
    required double principal,
    required int tenor,
    DateTime? disbursementDate,
    String? notes,
    String loanType = 'regular',
  }) async {
    try {
      final row = await _dataSource.rpcCreateLoan(
        memberId: memberId,
        principal: principal,
        tenor: tenor,
        disbursementDate: disbursementDate,
        notes: notes,
        loanType: loanType,
      );
      return Ok(LoanModel.fromMap(row));
    } on PostgrestException catch (e) {
      final message = e.message.replaceFirst(RegExp(r'^\W+'), '').trim();
      return Err(Failure(message: message.isEmpty ? e.message : message));
    } catch (_) {
      return const Err(
          Failure(message: 'Gagal menyimpan pinjaman. Periksa koneksi'));
    }
  }

  @override
  Future<Result<void>> payInstallment({
    required String scheduleId,
    double? principalPaid,
    double? interestPaid,
  }) async {
    try {
      await _dataSource.rpcPayInstallment(
        scheduleId: scheduleId,
        principalPaid: principalPaid,
        interestPaid: interestPaid,
      );
      return const Ok(null);
    } on PostgrestException catch (e) {
      final message = e.message.replaceFirst(RegExp(r'^\W+'), '').trim();
      return Err(Failure(message: message.isEmpty ? e.message : message));
    } catch (_) {
      return const Err(
          Failure(message: 'Gagal mencatat pembayaran. Periksa koneksi'));
    }
  }
}
