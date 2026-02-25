import 'package:flutter/material.dart';

/// Global navigation: switch main app tabs from pushed pages (e.g. Add Deadline).
class AppNav {
  static void Function()? navigateToHome;
  static void Function()? navigateToPlanner;
  static void Function()? navigateToGroup;
  static void Function()? navigateToSettings;
  /// Called when returning from setup flow (Academic Details) so Home/Planner refresh.
  static void Function()? onReturnFromSetup;
  /// Called when plan is regenerated (e.g. after edit) so Today's tasks on Home update immediately.
  static void Function()? onPlanRegenerated;

  static void goToSettings(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
    navigateToSettings?.call();
  }
}
