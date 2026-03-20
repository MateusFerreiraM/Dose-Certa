import 'package:flutter/material.dart';
import 'package:dose_certa/app.dart';
import 'package:dose_certa/core/di/injection_container.dart';
import 'package:dose_certa/services/notification/notification_service.dart';
import 'package:dose_certa/services/notification/reminder_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDependencies();
  final notificationService = getIt<NotificationService>();
  await notificationService.initialize();
  try {
    final syncService = getIt<ReminderSyncService>();
    await syncService.syncAll(daysAhead: 7);
  } catch (_) {}

  runApp(DoseCertaApp());
}
