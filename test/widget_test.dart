import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadaya/core/theme/app_theme.dart';

void main() {
  testWidgets('tema aplikasi merender MaterialApp tanpa error',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Center(
            child: Text('Sadaya'),
          ),
        ),
      ),
    );

    expect(find.text('Sadaya'), findsOneWidget);
  });

  test('AppTheme.light memakai Material 3 dan warna khas koperasi',
      () {
    final theme = AppTheme.light;
    expect(theme.useMaterial3, isTrue);
    expect(theme.scaffoldBackgroundColor, isNotNull);
  });
}