import '../../domain/entities/cash_entities.dart';

class CashBookEntryModel extends CashBookEntry {
  const CashBookEntryModel({
    required super.id,
    required super.date,
    required super.direction,
    required super.amount,
    required super.description,
    super.categoryName,
  });

  /// [isBank] mengubah konvensi tipe transaksi tabel bank:
  /// credit = uang masuk, debit = uang keluar.
  factory CashBookEntryModel.fromMap(
    Map<String, dynamic> map, {
    bool isBank = false,
  }) {
    final rawType = map['transaction_type'] as String;
    final direction = isBank
        ? (rawType == 'credit' ? 'in' : 'out')
        : (rawType == 'income' ? 'in' : 'out');
    final category = map['transaction_categories'];
    return CashBookEntryModel(
      id: map['id'] as String,
      date: DateTime.parse(map['transaction_date'] as String),
      direction: direction,
      amount: double.tryParse('${map['amount']}') ?? 0,
      description: map['description'] as String? ?? '',
      categoryName:
          category is Map<String, dynamic> ? category['name'] as String? : null,
    );
  }
}

class CashCategoryOptionModel extends CashCategoryOption {
  const CashCategoryOptionModel({
    required super.code,
    required super.name,
    required super.isIncome,
  });

  factory CashCategoryOptionModel.fromMap(Map<String, dynamic> map) {
    final type = map['category_type'] as String;
    return CashCategoryOptionModel(
      code: map['code'] as String,
      name: map['name'] as String,
      isIncome: type == 'income',
    );
  }
}
