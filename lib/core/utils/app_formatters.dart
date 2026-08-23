import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final NumberFormat _numberFormat = NumberFormat.decimalPattern('id');

  static const List<String> _monthShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  static String rupiah(num value) => 'Rp ${_numberFormat.format(value)}';

  static String number(num value) => _numberFormat.format(value);

  static String date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_monthShort[d.month - 1]} ${d.year}';

  static String dateIso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
