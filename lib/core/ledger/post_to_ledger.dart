import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../error/failure.dart';
import '../usecases/usecase.dart';
import '../utils/result.dart';

class LedgerLine extends Equatable {
  const LedgerLine({
    required this.accountCode,
    this.debit = 0,
    this.credit = 0,
  });

  final String accountCode;
  final double debit;
  final double credit;

  bool get isValidSide => (debit > 0) != (credit > 0);

  Map<String, dynamic> toMap() => {
    'account_code': accountCode,
    'debit_amount': debit,
    'credit_amount': credit,
  };

  @override
  List<Object?> get props => [accountCode, debit, credit];
}

class PostToLedgerParams extends Equatable {
  const PostToLedgerParams({
    required this.entryDate,
    required this.referenceId,
    required this.referenceType,
    required this.description,
    required this.lines,
    this.sourceBook = 'cash',
    this.fiscalYear,
  });

  final DateTime entryDate;
  final String referenceId;
  final String referenceType;
  final String description;
  final String sourceBook;
  final int? fiscalYear;
  final List<LedgerLine> lines;

  @override
  List<Object?> get props => [
    entryDate,
    referenceId,
    referenceType,
    description,
    sourceBook,
    lines,
  ];
}

@lazySingleton
class LedgerRemoteDataSource {
  LedgerRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<void> postEntries(PostToLedgerParams params, String userId) async {
    await _client.from('ledger_entries').insert([
      for (final line in params.lines)
        {
          ...line.toMap(),
          'entry_date': params.entryDate.toIso8601String().substring(0, 10),
          'source_book': params.sourceBook,
          'reference_id': params.referenceId,
          'reference_type': params.referenceType,
          'description': params.description,
          if (params.fiscalYear != null) 'fiscal_year': params.fiscalYear,
          'created_by': userId,
        },
    ]);
  }
}

@lazySingleton
class PostToLedgerUseCase implements UseCase<void, PostToLedgerParams> {
  PostToLedgerUseCase(this._dataSource, this._client);

  final LedgerRemoteDataSource _dataSource;
  final SupabaseClient _client;

  @override
  Future<Result<void>> call(PostToLedgerParams params) async {
    if (params.lines.isEmpty) {
      return const Err(Failure(message: 'Jurnal tidak boleh kosong'));
    }
    if (params.lines.any((line) => !line.isValidSide)) {
      return const Err(
        Failure(
          message: 'Setiap baris jurnal harus memiliki debit ATAU kredit',
        ),
      );
    }
    final totalDebit = params.lines.fold<double>(
      0,
      (sum, line) => sum + line.debit,
    );
    final totalCredit = params.lines.fold<double>(
      0,
      (sum, line) => sum + line.credit,
    );
    if ((totalDebit - totalCredit).abs() > 0.005) {
      return Err(
        Failure(
          message:
              'Jurnal tidak seimbang. Debit: $totalDebit, Kredit: $totalCredit',
        ),
      );
    }
    try {
      await _dataSource.postEntries(params, _client.auth.currentUser?.id ?? '');
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(Failure(message: 'Gagal mencatat jurnal (${e.message})'));
    } catch (_) {
      return const Err(
        Failure(message: 'Gagal mencatat jurnal. Periksa koneksi internet'),
      );
    }
  }
}
