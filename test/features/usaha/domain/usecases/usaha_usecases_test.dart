import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sadaya/core/utils/result.dart';
import 'package:sadaya/features/usaha/domain/repositories/usaha_repository.dart';
import 'package:sadaya/features/usaha/domain/usecases/material_usecases.dart';
import 'package:sadaya/features/usaha/domain/usecases/production_usecases.dart';
import 'package:sadaya/features/usaha/domain/usecases/sale_usecases.dart';

class _MockUsahaRepository extends Mock implements UsahaRepository {}

void main() {
  late _MockUsahaRepository repository;

  setUp(() {
    repository = _MockUsahaRepository();
  });

  group('CreateMaterial', () {
    test('gagal bila nama kosong', () async {
      final usecase = CreateMaterial(repository);
      final result = await usecase(const CreateMaterialParams(
        name: '   ',
        unit: 'kg',
      ));
      expect(result, isA<Err<void>>());
    });

    test('gagal bila satuan kosong', () async {
      final usecase = CreateMaterial(repository);
      final result = await usecase(const CreateMaterialParams(
        name: 'Kentang',
        unit: '  ',
      ));
      expect(result, isA<Err<void>>());
    });
  });

  group('RecordMaterialTransaction', () {
    test('pembelian valid diteruskan sebagai type purchase', () async {
      when(() => repository.recordMaterialTransaction(
            materialId: any(named: 'materialId'),
            type: any(named: 'type'),
            quantity: any(named: 'quantity'),
            unitPrice: any(named: 'unitPrice'),
            date: any(named: 'date'),
            notes: any(named: 'notes'),
          )).thenAnswer((_) async => const Ok(15.0));

      final usecase = RecordMaterialTransaction(repository);
      final result = await usecase(RecordMaterialTxParams(
        materialId: 'm1',
        isPurchase: true,
        quantity: 10,
        unitPrice: 12000,
        date: DateTime(2026, 8, 20),
      ));

      expect(result, const Ok(15.0));
      final data = verify(() => repository.recordMaterialTransaction(
            materialId: captureAny(named: 'materialId'),
            type: captureAny(named: 'type'),
            quantity: captureAny(named: 'quantity'),
            unitPrice: captureAny(named: 'unitPrice'),
            date: any(named: 'date'),
            notes: any(named: 'notes'),
          )).captured;
      expect(data[0], 'm1');
      expect(data[1], 'purchase');
      expect(data[2], 10);
      expect(data[3], 12000);
    });

    test('pemakaian tidak meneruskan harga', () async {
      double? capturedPrice;
      when(() => repository.recordMaterialTransaction(
            materialId: any(named: 'materialId'),
            type: any(named: 'type'),
            quantity: any(named: 'quantity'),
            unitPrice: any(named: 'unitPrice'),
            date: any(named: 'date'),
            notes: any(named: 'notes'),
          )).thenAnswer((invocation) async {
        capturedPrice =
            invocation.namedArguments[#unitPrice] as double?;
        return const Ok(0.0);
      });

      final usecase = RecordMaterialTransaction(repository);
      await usecase(RecordMaterialTxParams(
        materialId: 'm1',
        isPurchase: false,
        quantity: 3,
        date: DateTime(2026, 8, 21),
      ));

      expect(capturedPrice, isNull);
    });

    test('gagal bila jumlah <= 0', () async {
      final usecase = RecordMaterialTransaction(repository);
      final result = await usecase(RecordMaterialTxParams(
        materialId: 'm1',
        isPurchase: true,
        quantity: 0,
        date: DateTime.now(),
      ));
      expect(result, isA<Err<double>>());
    });
  });

  group('CreateProduction / CreateSale', () {
    test('produksi gagal bila jumlah <= 0', () async {
      final usecase = CreateProduction(repository);
      final result = await usecase(CreateProductionParams(
        productType: 'keripik_kentang',
        date: fakeDate,
        quantity: 0,
        unit: 'kg',
      ));
      expect(result, isA<Err<void>>());
    });

    test('penjualan gagal bila produk tak dikenal', () async {
      final usecase = CreateSale(repository);
      final result = await usecase(CreateSaleParams(
        productType: 'keripik_seledri',
        date: fakeDate,
        quantity: 2,
        unit: 'kg',
        unitPrice: 20000,
      ));
      expect(result, isA<Err<void>>());
    });

    test('penjualan gagal bila harga <= 0', () async {
      final usecase = CreateSale(repository);
      final result = await usecase(CreateSaleParams(
        productType: 'kopi',
        date: fakeDate,
        quantity: 2,
        unit: 'pack',
        unitPrice: 0,
      ));
      expect(result, isA<Err<void>>());
    });
  });
}

final fakeDate = DateTime(2026, 8, 20);
