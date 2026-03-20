import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'dart:typed_data';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    try {
      tzdata.initializeTimeZones();
      try {
        tz.setLocalLocation(
            tz.getLocation('America/Sao_Paulo')); // Brazil timezone
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    } catch (e) {}
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse response) async {},
    );
    try {
      final androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      const channel = AndroidNotificationChannel(
        'medication_reminders_v3', // id
        'Lembretes de Medicamento (Alarme)', // title
        description: 'Notificações persistentes para medicamentos', // description
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      await androidPlugin?.createNotificationChannel(channel);
    } catch (e) {}
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final status = await Permission.notification.status;
        if (!status.isGranted) {
          await Permission.notification.request();
        }
        if (Platform.isAndroid) {
          final alarmStatus = await Permission.scheduleExactAlarm.status;
          if (!alarmStatus.isGranted) {
            await Permission.scheduleExactAlarm.request();
          }
        }
      }
    } catch (_) {}
  }

  Future<void> scheduleMedicationReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      final now = DateTime.now();
      if (!scheduledDate.isAfter(now)) {
        return; // Silently skip past dates
      }

      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'medication_reminders_v3',
        'Lembretes de Medicamento (Alarme)',
        channelDescription: 'Notificações persistentes para medicamentos',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableLights: true,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT (toque contínuo)
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );
      final localTz = tz.local;
      final alignedSchedule = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        scheduledDate.hour,
        scheduledDate.minute,
        0, // Força segundos para 0
      );

      final scheduledTz = tz.TZDateTime(
        localTz,
        alignedSchedule.year,
        alignedSchedule.month,
        alignedSchedule.day,
        alignedSchedule.hour,
        alignedSchedule.minute,
        0, // Força segundos para 0
        0, // Força milissegundos para 0
      );

      final nowTz = tz.TZDateTime.now(localTz);
      if (!scheduledTz.isAfter(nowTz)) {
        return; // Skip if not in future
      }

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTz,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {}
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
