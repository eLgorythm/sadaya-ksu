import '../../domain/entities/usaha_entities.dart';

class RawMaterialModel extends RawMaterial {
  const RawMaterialModel({
    required super.id,
    required super.name,
    required super.unit,
    required super.currentStock,
  });

  factory RawMaterialModel.fromMap(Map<String, dynamic> map) {
    return RawMaterialModel(
      id: map['id'] as String,
      name: map['name'] as String,
      unit: map['unit'] as String? ?? 'kg',
      currentStock: (map['current_stock'] as num).toDouble(),
    );
  }
}

class MaterialTransactionModel extends MaterialTransaction {
  const MaterialTransactionModel({
    required super.id,
    required super.materialId,
    required super.materialName,
    required super.type,
    required super.quantity,
    required super.date,
    required super.unitPrice,
    required super.totalPrice,
    required super.notes,
  });

  factory MaterialTransactionModel.fromMap(Map<String, dynamic> map) {
    return MaterialTransactionModel(
      id: map['id'] as String,
      materialId: map['material_id'] as String,
      materialName: map['chip_raw_materials'] == null
          ? '(bahan terhapus)'
          : (map['chip_raw_materials'] as Map)['name'] as String? ?? '',
      type: map['transaction_type'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      date: DateTime.parse(map['transaction_date'] as String),
      unitPrice: (map['unit_price'] as num?)?.toDouble(),
      totalPrice: (map['total_price'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
    );
  }
}

class ProductionRecordModel extends ProductionRecord {
  const ProductionRecordModel({
    required super.id,
    required super.productType,
    required super.date,
    required super.quantityProduced,
    required super.unit,
    required super.quantityPack,
    required super.productionCost,
    required super.notes,
  });

  factory ProductionRecordModel.fromMap(Map<String, dynamic> map) {
    return ProductionRecordModel(
      id: map['id'] as String,
      productType: map['product_type'] as String,
      date: DateTime.parse(map['production_date'] as String),
      quantityProduced: (map['quantity_produced'] as num).toDouble(),
      unit: map['unit'] as String? ?? 'kg',
      quantityPack: (map['quantity_pack'] as num?)?.toDouble(),
      productionCost: (map['production_cost'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
    );
  }
}

class SaleRecordModel extends SaleRecord {
  const SaleRecordModel({
    required super.id,
    required super.productType,
    required super.date,
    required super.quantity,
    required super.unit,
    required super.unitPrice,
    required super.totalPrice,
    required super.buyer,
    required super.notes,
  });

  factory SaleRecordModel.fromMap(Map<String, dynamic> map) {
    return SaleRecordModel(
      id: map['id'] as String,
      productType: map['product_type'] as String,
      date: DateTime.parse(map['sale_date'] as String),
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String? ?? 'kg',
      unitPrice: (map['unit_price'] as num).toDouble(),
      totalPrice: (map['total_price'] as num).toDouble(),
      buyer: map['buyer'] as String?,
      notes: map['notes'] as String?,
    );
  }
}
