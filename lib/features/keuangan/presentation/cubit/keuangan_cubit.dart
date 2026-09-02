import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/cash_entities.dart';
import '../../domain/usecases/create_cash_category.dart';
import '../../domain/usecases/get_cash_entries.dart';
import '../../domain/usecases/get_cash_ledger_summary.dart';

part 'keuangan_state.dart';

@lazySingleton
class KeuanganCubit extends Cubit<KeuanganState> {
  KeuanganCubit(
    this._getEntries,
    this._getCategories,
    this._createCategory,
    this._getSummary,
  ) : super(const KeuanganInitial());

  final GetCashEntries _getEntries;
  final GetCashCategories _getCategories;
  final CreateCashCategory _createCategory;
  final GetCashLedgerSummary _getSummary;

  /// Kategori baru: simpan ke server lalu perbarui state halaman
  /// bila sedang ter-load, agar sheet berikutnya langsung melihatnya.
  Future<Result<String>> addCategory({
    required String name,
    required bool isIncome,
  }) async {
    final result = await _createCategory(CreateCashCategoryParams(
      name: name,
      isIncome: isIncome,
    ));

    switch (result) {
      case Ok(:final value):
        final current = state;
        if (current is KeuanganLoaded) {
          emit(KeuanganLoaded(
            cashEntries: current.cashEntries,
            bankEntries: current.bankEntries,
            categories: [
              ...current.categories,
              CashCategoryOption(
                code: value,
                name: name.trim(),
                isIncome: isIncome,
              ),
            ],
            summary: current.summary,
          ));
        }
      case Err():
        break;
    }
    return result;
  }

  Future<void> load({bool silent = false}) async {
    if (!silent || state is! KeuanganLoaded) {
      emit(const KeuanganLoadInProgress());
    }
    final year = DateTime.now().year;
    final cash = await _getEntries('cash');
    final bank = await _getEntries('bank');
    final categories = await _getCategories(const NoParams());
    final summary = await _getSummary(year);

    if (cash case Err(:final failure)) {
      emit(KeuanganFailure(failure.message));
      return;
    }
    if (bank case Err(:final failure)) {
      emit(KeuanganFailure(failure.message));
      return;
    }
    if (categories case Err(:final failure)) {
      emit(KeuanganFailure(failure.message));
      return;
    }
    if (summary case Err(:final failure)) {
      emit(KeuanganFailure(failure.message));
      return;
    }

    emit(KeuanganLoaded(
      cashEntries: (cash as Ok).value,
      bankEntries: (bank as Ok).value,
      categories: (categories as Ok).value,
      summary: (summary as Ok).value,
    ));
  }
}
