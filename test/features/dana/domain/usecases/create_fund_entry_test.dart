import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sadaya/core/utils/result.dart';
import 'package:sadaya/features/dana/domain/repositories/dana_repository.dart';
import 'package:sadaya/features/dana/domain/usecases/create_fund_entry.dart';

class MockDanaRepository extends Mock implements DanaRepository {}

void main() {
  late MockDanaRepository repo;
  late CreateFundEntry usecase;

  setUp(() {
    repo = MockDanaRepository();
    usecase = CreateFundEntry(repo);
    registerFallbackValue(DateTime(2026));
  });

  test('menolak nominal <= 0', () async {
    final result = await usecase(CreateFundEntryParams(
      fundType: 'social',
      isIncoming: false,
      amount: 0,
      description: 'Bantuan',
      date: DateTime(2026, 8, 24),
    ));
    expect(result, isA<Err<void>>());
    verifyNever(() => repo.createFundEntry(
          fundType: any(named: 'fundType'),
          isIncoming: any(named: 'isIncoming'),
          amount: any(named: 'amount'),
          description: any(named: 'description'),
          date: any(named: 'date'),
        ));
  });

  test('menolak keterangan kosong', () async {
    final result = await usecase(CreateFundEntryParams(
      fundType: 'social',
      isIncoming: false,
      amount: 50000,
      description: '   ',
      date: DateTime(2026, 8, 24),
    ));
    expect(result, isA<Err<void>>());
    verifyNever(() => repo.createFundEntry(
          fundType: any(named: 'fundType'),
          isIncoming: any(named: 'isIncoming'),
          amount: any(named: 'amount'),
          description: any(named: 'description'),
          date: any(named: 'date'),
        ));
  });

  test('meneruskan dengan keterangan trim', () async {
    when(() => repo.createFundEntry(
          fundType: any(named: 'fundType'),
          isIncoming: any(named: 'isIncoming'),
          amount: any(named: 'amount'),
          description: captureAny(named: 'description'),
          date: any(named: 'date'),
        )).thenAnswer((_) async => const Ok(null));

    final result = await usecase(CreateFundEntryParams(
      fundType: 'education',
      isIncoming: true,
      amount: 100000,
      description: '  Donasi buku  ',
      date: DateTime(2026, 8, 24),
    ));

    expect(result, isA<Ok<void>>());
    final captured = verify(() => repo.createFundEntry(
          fundType: any(named: 'fundType'),
          isIncoming: any(named: 'isIncoming'),
          amount: any(named: 'amount'),
          description: captureAny(named: 'description'),
          date: any(named: 'date'),
        )).captured;
    expect(captured.single, 'Donasi buku');
  });
}
