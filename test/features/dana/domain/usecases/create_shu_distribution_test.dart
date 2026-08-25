import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sadaya/core/utils/result.dart';
import 'package:sadaya/features/dana/domain/repositories/dana_repository.dart';
import 'package:sadaya/features/dana/domain/usecases/create_shu_distribution.dart';

class MockDanaRepository extends Mock implements DanaRepository {}

void main() {
  late MockDanaRepository repo;
  late CreateShuDistribution usecase;

  setUp(() {
    repo = MockDanaRepository();
    usecase = CreateShuDistribution(repo);
  });

  test('menolak total SHU <= 0', () async {
    final result = await usecase(const CreateShuDistributionParams(
      fiscalYear: 2026,
      totalShu: 0,
    ));
    expect(result, isA<Err<String>>());
    verifyNever(() => repo.createShuDistribution(
          fiscalYear: any(named: 'fiscalYear'),
          totalShu: any(named: 'totalShu'),
          taxAmount: any(named: 'taxAmount'),
          netShu: any(named: 'netShu'),
        ));
  });

  test('menolak pajak lebih besar dari total', () async {
    final result = await usecase(const CreateShuDistributionParams(
      fiscalYear: 2026,
      totalShu: 1000000,
      taxAmount: 2000000,
    ));
    expect(result, isA<Err<String>>());
  });

  test('menolak total alokasi melebihi 100%', () async {
    final result = await usecase(const CreateShuDistributionParams(
      fiscalYear: 2026,
      totalShu: 1000000,
      reservePct: 0.5,
      socialPct: 0.4,
      educationPct: 0.3,
    ));
    expect(result, isA<Err<String>>());
    verifyNever(() => repo.createShuDistribution(
          fiscalYear: any(named: 'fiscalYear'),
          totalShu: any(named: 'totalShu'),
          taxAmount: any(named: 'taxAmount'),
          netShu: any(named: 'netShu'),
        ));
  });

  test('meneruskan dengan net SHU benar', () async {
    when(() => repo.createShuDistribution(
          fiscalYear: any(named: 'fiscalYear'),
          totalShu: any(named: 'totalShu'),
          taxAmount: any(named: 'taxAmount'),
          netShu: any(named: 'netShu'),
          reservePct: any(named: 'reservePct'),
          socialPct: any(named: 'socialPct'),
          educationPct: any(named: 'educationPct'),
        )).thenAnswer((_) async => const Ok('shu-id'));

    final result = await usecase(const CreateShuDistributionParams(
      fiscalYear: 2025,
      totalShu: 10000000,
      taxAmount: 1000000,
      reservePct: 0.25,
      socialPct: 0.05,
      educationPct: 0.05,
    ));

    expect(result, isA<Ok<String>>());
    final captured = verify(() => repo.createShuDistribution(
          fiscalYear: any(named: 'fiscalYear'),
          totalShu: captureAny(named: 'totalShu'),
          taxAmount: captureAny(named: 'taxAmount'),
          netShu: captureAny(named: 'netShu'),
          reservePct: captureAny(named: 'reservePct'),
          socialPct: captureAny(named: 'socialPct'),
          educationPct: captureAny(named: 'educationPct'),
        )).captured;
    expect(captured[0], 10000000.0);
    expect(captured[1], 1000000.0);
    expect(captured[2], 9000000.0);
    expect(captured[3], 0.25);
  });
}
