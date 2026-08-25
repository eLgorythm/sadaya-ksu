import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sadaya/core/utils/result.dart';
import 'package:sadaya/features/keuangan/domain/repositories/cash_repository.dart';
import 'package:sadaya/features/keuangan/domain/usecases/create_cash_entry.dart';

class _MockCashRepository extends Mock implements CashRepository {}

void main() {
  late _MockCashRepository repo;
  late CreateCashEntry usecase;

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    repo = _MockCashRepository();
    usecase = CreateCashEntry(repo);
    when(() => repo.createEntry(
          book: any(named: 'book'),
          direction: any(named: 'direction'),
          counterAccount: any(named: 'counterAccount'),
          amount: any(named: 'amount'),
          date: any(named: 'date'),
          description: any(named: 'description'),
        )).thenAnswer((_) async => const Ok(null));
  });

  final valid = CreateCashEntryParams(
    book: 'cash',
    direction: 'out',
    counterAccount: '5115',
    amount: 50000,
    date: DateTime(2026, 8, 24),
    description: 'Beli ATK',
  );

  test('menolak nominal <= 0 tanpa menyentuh repository', () async {
    final result = await usecase(valid.copyWith(amount: 0));
    expect(result, isA<Err>());
    verifyNever(() => repo.createEntry(
          book: any(named: 'book'),
          direction: any(named: 'direction'),
          counterAccount: any(named: 'counterAccount'),
          amount: any(named: 'amount'),
          date: any(named: 'date'),
          description: any(named: 'description'),
        ));
  });

  test('menolak keterangan kosong', () async {
    final result = await usecase(valid.copyWith(description: '   '));
    expect(result, isA<Err>());
  });

  test('menolak kategori kosong', () async {
    final result = await usecase(valid.copyWith(counterAccount: ''));
    expect(result, isA<Err>());
  });

  test('meneruskan ke repository dengan deskripsi ter-trim', () async {
    final result =
        await usecase(valid.copyWith(description: '  Beli ATK  '));
    expect(result, isA<Ok>());
    final captured = verify(() => repo.createEntry(
          book: captureAny(named: 'book'),
          direction: captureAny(named: 'direction'),
          counterAccount: captureAny(named: 'counterAccount'),
          amount: captureAny(named: 'amount'),
          date: captureAny(named: 'date'),
          description: captureAny(named: 'description'),
        )).captured;
    expect(captured[0], 'cash');
    expect(captured[1], 'out');
    expect(captured[2], '5115');
    expect(captured[3], 50000.0);
    expect(captured[5], 'Beli ATK');
  });
}
