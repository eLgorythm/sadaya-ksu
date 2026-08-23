class Validators {
  Validators._();

  static String? Function(String?) required(String label) {
    return (value) {
      final v = value?.trim() ?? '';
      if (v.isEmpty) return '$label wajib diisi';
      return null;
    };
  }

  static String? optionalPhone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (!RegExp(r'^[0-9+\-\s()]{5,20}$').hasMatch(v)) {
      return 'Nomor telepon tidak valid';
    }
    return null;
  }

  static String? Function(String?) positiveAmount({String label = 'Nominal'}) {
    return (value) {
      final v = value?.trim() ?? '';
      if (v.isEmpty) return '$label wajib diisi';
      final parsed = double.tryParse(v.replaceAll('.', '').replaceAll(',', '.'));
      if (parsed == null || parsed <= 0) return '$label harus angka lebih dari 0';
      return null;
    };
  }
}
