import 'package:flutter/material.dart';

/// Global navigation: switch main app tabs from pushed pages (e.g. Add Deadline).
class AppNav {
  static void Function()? navigateToHome;
  static void Function()? navigateToPlanner;
  static void Function()? navigateToGroup;
  static void Function()? navigateToSettings;

  static void goToSettings(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
    navigateToSettings?.call();
  }
}
