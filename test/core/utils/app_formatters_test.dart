import 'package:flutter_test/flutter_test.dart';
import 'package:sadaya/core/utils/app_formatters.dart';

void main() {
  group('AppFormatters', () {
    test('rupiah formats thousands separator', () {
      expect(AppFormatters.rupiah(0), 'Rp 0');
      expect(AppFormatters.rupiah(1234567), 'Rp 1.234.567');
      expect(AppFormatters.rupiah(20000), 'Rp 20.000');
    });

    test('date formats in Indonesian short month', () {
      expect(AppFormatters.date(DateTime(2026, 8, 23)), '23 Agu 2026');
      expect(AppFormatters.date(DateTime(2026, 1, 5)), '05 Jan 2026');
    });

    test('dateIso pads single digit month/day', () {
      expect(AppFormatters.dateIso(DateTime(2026, 8, 23)), '2026-08-23');
      expect(AppFormatters.dateIso(DateTime(2026, 1, 5)), '2026-01-05');
    });
  });
}
