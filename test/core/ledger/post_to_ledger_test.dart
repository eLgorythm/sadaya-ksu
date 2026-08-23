import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sadaya/core/ledger/post_to_ledger.dart';
import 'package:sadaya/core/utils/result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockLedgerDataSource extends Mock implements LedgerRemoteDataSource {}

PostToLedgerParams _params({required List<LedgerLine> lines}) {
  return PostToLedgerParams(
    entryDate: DateTime(2026, 8, 23),
    referenceId: 'ref-1',
    referenceType: 'savings_transaction',
    description: 'Setoran SP',
    sourceBook: 'savings',
    fiscalYear: 2026,
    lines: lines,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_params(lines: const []));
  });

  late MockLedgerDataSource dataSource;
  late PostToLedgerUseCase useCase;

  setUp(() {
    dataSource = MockLedgerDataSource();
    final client = SupabaseClient('http://localhost:54321', 'test-anon-key');
    useCase = PostToLedgerUseCase(dataSource, client);
  });

  test('rejects empty lines', () async {
    final result = await useCase(_params(lines: const []));
    expect(result, isA<Err<void>>());
    verifyNever(() => dataSource.postEntries(any(), any()));
  });

  test('rejects unbalanced journal', () async {
    final result = await useCase(_params(lines: const [
      LedgerLine(accountCode: '1111', debit: 100000),
      LedgerLine(accountCode: '3112', credit: 90000),
    ]));

    final failed = switch (result) {
      Err() => true,
      Ok() => false,
    };
    expect(failed, isTrue);
    verifyNever(() => dataSource.postEntries(any(), any()));
  });

  test('rejects line containing both debit and credit', () async {
    final result = await useCase(_params(lines: const [
      LedgerLine(accountCode: '1111', debit: 50000, credit: 50000),
      LedgerLine(accountCode: '3112'),
      LedgerLine(accountCode: '1112'),
    ]));
    expect(result, isA<Err<void>>());
  });

  test('posts balanced journal to data source', () async {
    when(() => dataSource.postEntries(any(), any()))
        .thenAnswer((_) async {});

    final result = await useCase(_params(lines: const [
      LedgerLine(accountCode: '1111', debit: 100000),
      LedgerLine(accountCode: '3112', credit: 100000),
    ]));

    expect(result, isA<Ok<void>>());
    final captured =
        verify(() => dataSource.postEntries(captureAny(), captureAny()))
            .captured;
    final posted = captured.first as PostToLedgerParams;
    expect(posted.lines, hasLength(2));
  });
}
