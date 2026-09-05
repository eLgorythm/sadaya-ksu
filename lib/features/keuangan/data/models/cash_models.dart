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
      categoryName: category is Map<String, dynamic>
          ? category['name'] as String?
          : null,
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

class CashLedgerSummaryModel extends CashLedgerSummary {
  const CashLedgerSummaryModel({required super.accounts, required super.total});

  factory CashLedgerSummaryModel.fromMap(Map<String, dynamic> map) {
    final accounts = (map['accounts'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CashLedgerAccountModel.fromMap)
        .toList();
    return CashLedgerSummaryModel(
      accounts: accounts,
      total: double.tryParse('${map['total']}') ?? 0,
    );
  }
}

class CashLedgerAccountModel extends CashLedgerAccount {
  const CashLedgerAccountModel({
    required super.code,
    required super.name,
    required super.accountType,
    required super.balance,
  });

  factory CashLedgerAccountModel.fromMap(Map<String, dynamic> map) {
    return CashLedgerAccountModel(
      code: map['code'] as String,
      name: map['name'] as String,
      accountType: map['account_type'] as String,
      balance: double.tryParse('${map['balance']}') ?? 0,
    );
  }
}

class CashSourceEntryModel extends CashSourceEntry {
  const CashSourceEntryModel({
    required super.source,
    required super.date,
    required super.amount,
    required super.description,
  });

  factory CashSourceEntryModel.fromMap(Map<String, dynamic> map) {
    return CashSourceEntryModel(
      source: map['source'] as String? ?? 'kas_lain',
      date: DateTime.parse(map['date'] as String),
      amount: double.tryParse('${map['amount']}') ?? 0,
      description: map['description'] as String? ?? '',
    );
  }
}

class CashSourcesModel extends CashSources {
  const CashSourcesModel({
    required super.entries,
    required super.posKesra,
    required super.posSosial,
    required super.posPendidikan,
    required super.posCrk,
    required super.posPembangunan,
    required super.posSwk,
    required super.posJapinup,
    required super.totalSms,
    required super.totalCairBank,
    required super.total,
  });

  factory CashSourcesModel.fromMap(Map<String, dynamic> map) {
    final entries = (map['entries'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CashSourceEntryModel.fromMap)
        .toList();
    return CashSourcesModel(
      entries: entries,
      posKesra: double.tryParse('${map['pos_kesra']}') ?? 0,
      posSosial: double.tryParse('${map['pos_sosial']}') ?? 0,
      posPendidikan: double.tryParse('${map['pos_pendidikan']}') ?? 0,
      posCrk: double.tryParse('${map['pos_crk']}') ?? 0,
      posPembangunan: double.tryParse('${map['pos_pembangunan']}') ?? 0,
      posSwk: double.tryParse('${map['pos_swk']}') ?? 0,
      posJapinup: double.tryParse('${map['pos_japinup']}') ?? 0,
      totalSms: double.tryParse('${map['total_sms']}') ?? 0,
      totalCairBank: double.tryParse('${map['total_cair_bank']}') ?? 0,
      total: double.tryParse('${map['total']}') ?? 0,
    );
  }
}
