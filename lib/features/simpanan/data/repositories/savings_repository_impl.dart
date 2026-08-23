import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/saving_entities.dart';
import '../../domain/repositories/savings_repository.dart';
import '../datasources/savings_remote_data_source.dart';
import '../models/saving_models.dart';

@LazySingleton(as: SavingsRepository)
class SavingsRepositoryImpl implements SavingsRepository {
  SavingsRepositoryImpl(this._dataSource);

  final SavingsRemoteDataSource _dataSource;

  @override
  Future<Result<List<SavingsTypeEntity>>> getSavingsTypes() async {
    try {
      final rows = await _dataSource.fetchTypes();
      return Ok(rows.map(SavingsTypeModel.fromMap).toList());
    } on PostgrestException catch (e) {
      return Err(Failure(message: 'Gagal memuat jenis simpanan (${e.message})'));
    } catch (_) {
      return const Err(
          Failure(message: 'Gagal memuat jenis simpanan. Periksa koneksi'));
    }
  }

  @override
  Future<Result<MemberSavingsSummary>> getMemberSummary(
    String memberId,
  ) async {
    try {
      final rows = await _dataSource.fetchMemberTransactions(memberId);
      final transactions =
          rows.map(SavingTransactionModel.fromMap).toList();
      final balances = <String, double>{};
      for (final tx in transactions.where((t) => !t.isVoid)) {
        final delta = tx.isDeposit ? tx.amount : -tx.amount;
        balances[tx.typeCode] = (balances[tx.typeCode] ?? 0) + delta;
      }
      return Ok(MemberSavingsSummary(
        balances: balances,
        transactions: transactions,
      ));
    } on PostgrestException catch (e) {
      return Err(Failure(message: 'Gagal memuat data simpanan (${e.message})'));
    } catch (_) {
      return const Err(
          Failure(message: 'Gagal memuat data simpanan. Periksa koneksi'));
    }
  }

  @override
  Future<Result<SavingTransactionEntity>> createTransaction({
    required String memberId,
    required SavingsTypeEntity type,
    required String transactionType,
    required double amount,
    String? description,
  }) async {
    try {
      final row = await _dataSource.rpcCreateTransaction(
        memberId: memberId,
        typeCode: type.code,
        transactionType: transactionType,
        amount: amount,
        description: description,
      );
      return Ok(SavingTransactionModel.fromRpcRow(
        row,
        typeCode: type.code,
        typeName: type.name,
      ));
    } on PostgrestException catch (e) {
      // Pesan exception dari RPC sudah berbahasa Indonesia.
      final message = e.message.replaceFirst(RegExp(r'^\W+'), '').trim();
      return Err(Failure(message: message.isEmpty ? e.message : message));
    } catch (_) {
      return const Err(
          Failure(message: 'Gagal menyimpan transaksi. Periksa koneksi'));
    }
  }
}
