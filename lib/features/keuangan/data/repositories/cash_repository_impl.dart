import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/cash_entities.dart';
import '../../domain/repositories/cash_repository.dart';
import '../datasources/cash_remote_data_source.dart';
import '../models/cash_models.dart';

@LazySingleton(as: CashRepository)
class CashRepositoryImpl implements CashRepository {
  CashRepositoryImpl(this._dataSource);

  final CashRemoteDataSource _dataSource;

  @override
  Future<Result<List<CashBookEntry>>> getEntries(String book) async {
    try {
      final rows = await _dataSource.fetchEntries(book);
      final isBank = book == 'bank';
      return Ok(rows
          .map((row) =>
              CashBookEntryModel.fromMap(row, isBank: isBank) as CashBookEntry)
          .toList());
    } on PostgrestException catch (e) {
      return Err(Failure(message: 'Gagal memuat buku (${e.message})'));
    } catch (_) {
      return const Err(Failure(message: 'Gagal memuat data buku kas/bank'));
    }
  }

  @override
  Future<Result<CashLedgerSummary>> getLedgerSummary(int year) async {
    try {
      final data = await _dataSource.fetchLedgerSummary(year);
      return Ok(CashLedgerSummaryModel.fromMap(data) as CashLedgerSummary);
    } on PostgrestException catch (e) {
      return Err(Failure(message: 'Gagal memuat ringkasan kas (${e.message})'));
    } catch (_) {
      return const Err(Failure(message: 'Gagal memuat ringkasan kas'));
    }
  }

  @override
  Future<Result<CashSources>> getCashSources(int year) async {
    try {
      final data = await _dataSource.fetchCashSources(year);
      return Ok(CashSourcesModel.fromMap(data) as CashSources);
    } on PostgrestException catch (e) {
      return Err(Failure(message: 'Gagal memuat kas (${e.message})'));
    } catch (_) {
      return const Err(Failure(message: 'Gagal memuat kas'));
    }
  }

  @override
  Future<Result<List<CashCategoryOption>>> getCategories() async {
    try {
      final rows = await _dataSource.fetchCategories();
      return Ok(rows
          .map((row) =>
              CashCategoryOptionModel.fromMap(row) as CashCategoryOption)
          .toList());
    } on PostgrestException catch (e) {
      return Err(Failure(message: 'Gagal memuat kategori (${e.message})'));
    } catch (_) {
      return const Err(Failure(message: 'Gagal memuat kategori transaksi'));
    }
  }

  @override
  Future<Result<String>> createCategory({
    required String name,
    required bool isIncome,
  }) async {
    try {
      final code = await _dataSource.rpcCreateCategory(
        name: name,
        isIncome: isIncome,
      );
      return Ok(code);
    } on PostgrestException catch (e) {
      return Err(Failure(message: e.message));
    } catch (_) {
      return const Err(Failure(message: 'Gagal membuat kategori baru'));
    }
  }

  @override
  Future<Result<void>> bankDanaMasuk({
    required double amount,
    required DateTime date,
    required String description,
  }) async {
    try {
      await _dataSource.rpcBankDanaMasuk(
        amount: amount,
        date: date,
        description: description,
      );
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(Failure(message: e.message));
    } catch (_) {
      return const Err(Failure(message: 'Gagal mencatat dana masuk bank'));
    }
  }

  @override
  Future<Result<void>> bankCairKas({
    required double amount,
    required DateTime date,
    required String description,
  }) async {
    try {
      await _dataSource.rpcBankCairKas(
        amount: amount,
        date: date,
        description: description,
      );
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(Failure(message: e.message));
    } catch (_) {
      return const Err(Failure(message: 'Gagal mencairkan ke kas'));
    }
  }
}
