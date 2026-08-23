import 'package:flutter/material.dart';

/// SATU-SATUNYA cara menampilkan snackbar di aplikasi Sadaya.
class SadayaMessage {
  SadayaMessage._();

  static void success(BuildContext context, String message) {
    _show(context, message, Colors.green.shade700);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, Theme.of(context).colorScheme.error);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, Colors.blueGrey.shade700);
  }

  static void _show(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: color,
      ));
  }
}
