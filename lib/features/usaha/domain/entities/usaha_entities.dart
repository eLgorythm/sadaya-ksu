import 'package:equatable/equatable.dart';

const kProductLabels = {
  'keripik_kentang': 'Keripik Kentang',
  'keripik_salak': 'Keripik Salak',
  'kopi': 'Kopi',
};

class RawMaterial extends Equatable {
  const RawMaterial({
    required this.id,
    required this.name,
    required this.unit,
    required this.currentStock,
  });

  final String id;
  final String name;
  final String unit;
  final double currentStock;

  @override
  List<Object?> get props => [id, name, unit, currentStock];
}

class MaterialTransaction extends Equatable {
  const MaterialTransaction({
    required this.id,
    required this.materialId,
    required this.materialName,
    required this.type,
    required this.quantity,
    required this.date,
    this.unitPrice,
    this.totalPrice,
    this.notes,
  });

  final String id;
  final String materialId;
  final String materialName;

  /// 'purchase' (beli) atau 'usage' (pakai).
  final String type;
  final double quantity;
  final DateTime date;
  final double? unitPrice;
  final double? totalPrice;
  final String? notes;

  bool get isPurchase => type == 'purchase';

  @override
  List<Object?> get props => [
        id,
        materialId,
        materialName,
        type,
        quantity,
        unitPrice,
        totalPrice,
        date,
        notes,
      ];
}

class ProductionRecord extends Equatable {
  const ProductionRecord({
    required this.id,
    required this.productType,
    required this.date,
    required this.quantityProduced,
    required this.unit,
    this.quantityPack,
    this.productionCost,
    this.notes,
  });

  final String id;
  final String productType;
  final DateTime date;

  /// Hasil bulk dengan satuan bebas (kg/gram).
  final double quantityProduced;
  final String unit;

  /// Hasil packing (pack) — opsional, terpisah dari [quantityProduced].
  final double? quantityPack;
  final double? productionCost;
  final String? notes;

  String get productLabel => kProductLabels[productType] ?? productType;

  @override
  List<Object?> get props => [
        id,
        productType,
        date,
        quantityProduced,
        unit,
        quantityPack,
        productionCost,
        notes,
      ];
}

class SaleRecord extends Equatable {
  const SaleRecord({
    required this.id,
    required this.productType,
    required this.date,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalPrice,
    this.buyer,
    this.notes,
  });

  final String id;
  final String productType;
  final DateTime date;
  final double quantity;

  /// 'kg' atau 'pack'.
  final String unit;
  final double unitPrice;
  final double totalPrice;
  final String? buyer;
  final String? notes;

  String get productLabel => kProductLabels[productType] ?? productType;

  @override
  List<Object?> get props => [
        id,
        productType,
        date,
        quantity,
        unit,
        unitPrice,
        totalPrice,
        buyer,
        notes,
      ];
}
