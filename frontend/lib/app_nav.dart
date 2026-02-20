import 'package:flutter/material.dart';

/// Global navigation: switch to Settings tab (same as bottom nav) instead of pushing a new page.
class AppNav {
  static void Function()? navigateToSettings;

  static void goToSettings(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
    navigateToSettings?.call();
  }
}
