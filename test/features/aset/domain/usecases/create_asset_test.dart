import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sadaya/core/utils/result.dart';
import 'package:sadaya/features/aset/domain/repositories/aset_repository.dart';
import 'package:sadaya/features/aset/domain/usecases/create_asset.dart';

class _MockAsetRepository extends Mock implements AsetRepository {}

void main() {
  late _MockAsetRepository repository;
  late CreateAsset usecase;

  setUp(() {
    repository = _MockAsetRepository();
    usecase = CreateAsset(repository);
  });

  final validParams = CreateAssetParams(
    name: 'Vacuum Frying',
    acquisitionDate: DateTime(2026, 1, 15),
    cost: 50000000,
    salvageValue: 5000000,
    usefulLifeYears: 5,
  );

  group('CreateAsset', () {
    test('sukses menyimpan aset valid', () async {
      when(() => repository.createAsset(
            name: any(named: 'name'),
            description: any(named: 'description'),
            acquisitionDate: any(named: 'acquisitionDate'),
            cost: any(named: 'cost'),
            salvageValue: any(named: 'salvageValue'),
            usefulLifeYears: any(named: 'usefulLifeYears'),
          )).thenAnswer((_) async => const Ok(null));

      final result = await usecase(validParams);

      expect(result, isA<Ok<void>>());
      verify(() => repository.createAsset(
            name: 'Vacuum Frying',
            description: null,
            acquisitionDate: validParams.acquisitionDate,
            cost: 50000000,
            salvageValue: 5000000,
            usefulLifeYears: 5,
          )).called(1);
    });

    test('gagal bila nama kosong', () async {
      final result = await usecase(
          validParams.copyWith(name: '   '));
      expect(result, isA<Err<void>>());
      verifyNever(() => repository.createAsset(
            name: any(named: 'name'),
            description: any(named: 'description'),
            acquisitionDate: any(named: 'acquisitionDate'),
            cost: any(named: 'cost'),
            salvageValue: any(named: 'salvageValue'),
            usefulLifeYears: any(named: 'usefulLifeYears'),
          ));
    });

    test('gagal bila nilai perolehan <= 0', () async {
      final result =
          await usecase(validParams.copyWith(cost: 0));
      expect(result, isA<Err<void>>());
    });

    test('gagal bila residu >= nilai perolehan', () async {
      final result = await usecase(
          validParams.copyWith(salvageValue: 60000000));
      expect(result, isA<Err<void>>());
    });

    test('gagal bila umur pakai di luar rentang', () async {
      final result =
          await usecase(validParams.copyWith(usefulLifeYears: 51));
      expect(result, isA<Err<void>>());
    });

    test('gagal bila tanggal perolehan di masa depan', () async {
      final result = await usecase(CreateAssetParams(
        name: 'Freezer',
        acquisitionDate: DateTime.now().add(const Duration(days: 1)),
        cost: 10000000,
        salvageValue: 0,
        usefulLifeYears: 4,
      ));
      expect(result, isA<Err<void>>());
    });

    test('mode ubah: params dengan id memanggil updateAsset', () async {
      when(() => repository.updateAsset(
            id: any(named: 'id'),
            name: any(named: 'name'),
            description: any(named: 'description'),
            acquisitionDate: any(named: 'acquisitionDate'),
            cost: any(named: 'cost'),
            salvageValue: any(named: 'salvageValue'),
            usefulLifeYears: any(named: 'usefulLifeYears'),
          )).thenAnswer((_) async => const Ok(null));

      final result = await usecase(CreateAssetParams(
        id: 'asset-1',
        name: 'Freezer Besar',
        acquisitionDate: validParams.acquisitionDate,
        cost: 50000000,
        salvageValue: 5000000,
        usefulLifeYears: 5,
      ));

      expect(result, isA<Ok<void>>());
      verify(() => repository.updateAsset(
            id: 'asset-1',
            name: 'Freezer Besar',
            description: null,
            acquisitionDate: validParams.acquisitionDate,
            cost: 50000000,
            salvageValue: 5000000,
            usefulLifeYears: 5,
          )).called(1);
      verifyNever(() => repository.createAsset(
            name: any(named: 'name'),
            description: any(named: 'description'),
            acquisitionDate: any(named: 'acquisitionDate'),
            cost: any(named: 'cost'),
            salvageValue: any(named: 'salvageValue'),
            usefulLifeYears: any(named: 'usefulLifeYears'),
          ));
    });
  });

  group('DeleteAsset', () {
    test('meneruskan id ke repository', () async {
      when(() => repository.deleteAsset(any()))
          .thenAnswer((_) async => const Ok(null));

      final result = await DeleteAsset(repository)('asset-1');

      expect(result, isA<Ok<void>>());
      verify(() => repository.deleteAsset('asset-1')).called(1);
    });
  });
}
