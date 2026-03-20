import 'package:shared_preferences/shared_preferences.dart';

import 'package:dose_certa/domain/entities/medication.dart';
import 'package:dose_certa/domain/entities/medication_dose.dart';
import 'package:dose_certa/domain/repositories/medication_repository.dart';
import 'package:dose_certa/domain/usecases/dose_usecases.dart';
import 'package:dose_certa/services/notification/notification_service.dart';

class ReminderSyncService {
  static const String kMedicationRemindersEnabledKey =
      'settings.medication_reminders_enabled';
  static const String kStockAlertsEnabledKey = 'settings.stock_alerts_enabled';

  final MedicationRepository _medicationRepository;
  final DoseUseCases _doseUseCases;
  final NotificationService _notificationService;
  final SharedPreferences _prefs;

  ReminderSyncService(
    this._medicationRepository,
    this._doseUseCases,
    this._notificationService,
    this._prefs,
  );

  bool get medicationRemindersEnabled =>
      _prefs.getBool(kMedicationRemindersEnabledKey) ?? true;

  bool get stockAlertsEnabled => _prefs.getBool(kStockAlertsEnabledKey) ?? true;

  Future<void> syncAll({int daysAhead = 7}) async {
    final medications = await _medicationRepository.getAllMedications();
    for (final medication in medications) {
      await syncMedication(medication, daysAhead: daysAhead);
    }
  }

  Future<void> syncMedication(Medication medication,
      {int daysAhead = 7}) async {
    if (medication.id == null) return;
    if (!medicationRemindersEnabled) {
      await _cancelUpcomingNotificationsForMedication(medication,
          daysAhead: daysAhead);
      return;
    }

    if (!medication.isActive || medication.isPaused) {
      await _cancelUpcomingNotificationsForMedication(medication,
          daysAhead: daysAhead);
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tolerance = _computeToleranceForMedication(medication);

    for (int i = 0; i <= daysAhead; i++) {
      final date = today.add(Duration(days: i));

      final isScheduledToday = _isMedicationScheduledOnDate(medication, date);
      final existing =
          await _doseUseCases.getDosesForMedicationOnDate(medication.id!, date);

      final desiredTimes = <DateTime>{};
      if (isScheduledToday) {
        for (final time in medication.times) {
          final scheduled = _buildDateTime(date, time);
          if (scheduled == null) continue;
          desiredTimes.add(DateTime(scheduled.year, scheduled.month,
              scheduled.day, scheduled.hour, scheduled.minute));
        }
      }

      final existingScheduled = existing
          .map((d) => DateTime(
              d.scheduledTime.year,
              d.scheduledTime.month,
              d.scheduledTime.day,
              d.scheduledTime.hour,
              d.scheduledTime.minute))
          .toSet();
      for (final dose in List<MedicationDose>.from(existing)) {
        if (dose.id == null) continue;
        if (dose.isTaken) continue;

        final doseDay = DateTime(dose.scheduledTime.year,
            dose.scheduledTime.month, dose.scheduledTime.day);
        final isSameDay = doseDay.year == date.year &&
            doseDay.month == date.month &&
            doseDay.day == date.day;
        if (!isSameDay) continue;

        final normalized = DateTime(
          dose.scheduledTime.year,
          dose.scheduledTime.month,
          dose.scheduledTime.day,
          dose.scheduledTime.hour,
          dose.scheduledTime.minute,
        );

        final shouldExist = desiredTimes.contains(normalized);
        if (!shouldExist && dose.scheduledTime.isAfter(now)) {
          await _notificationService.cancelNotification(dose.id!);
          await _doseUseCases.deleteDose(dose.id!);
          existing.removeWhere((d) => d.id == dose.id);
          existingScheduled.remove(normalized);
        }
      }
      for (final normalized in desiredTimes) {
        if (existingScheduled.contains(normalized)) continue;
        final newDose = MedicationDose(
          medicationId: medication.id!,
          scheduledTime: normalized,
          status: DoseStatus.pending,
          createdAt: DateTime.now(),
        );
        final id = await _doseUseCases.insertDose(newDose);
        if (id > 0) {
          existing.add(newDose.copyWith(id: id));
          existingScheduled.add(normalized);
        }
      }
      for (final dose in existing) {
        if (dose.id == null) continue;

        final desiredStatus = _computeDoseStatus(
          now: now,
          scheduled: dose.scheduledTime,
          tolerance: tolerance,
          currentStatus: dose.status,
        );

        if (desiredStatus != dose.status) {
          await _doseUseCases.updateDose(
            dose.copyWith(status: desiredStatus, updatedAt: DateTime.now()),
          );
        }

        if (desiredStatus == DoseStatus.taken ||
            desiredStatus == DoseStatus.missed) {
          await _notificationService.cancelNotification(dose.id!);
          continue;
        }

        if (dose.scheduledTime.isAfter(now)) {
          await _notificationService.scheduleMedicationReminder(
            id: dose.id!,
            title: medication.name,
            body:
                'Hora de tomar ${medication.name} — ${medication.formattedDosage}',
            scheduledDate: dose.scheduledTime,
          );
        }
      }
    }
  }

  Future<void> cancelUpcomingForMedicationId(
    int medicationId, {
    int daysAhead = 7,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int i = 0; i <= daysAhead; i++) {
      final date = today.add(Duration(days: i));
      final doses =
          await _doseUseCases.getDosesForMedicationOnDate(medicationId, date);
      for (final d in doses) {
        if (d.id == null) continue;
        if (d.scheduledTime.isAfter(now) && !d.isTaken) {
          await _notificationService.cancelNotification(d.id!);
        }
      }
    }
  }

  Future<void> _cancelUpcomingNotificationsForMedication(
    Medication medication, {
    required int daysAhead,
  }) async {
    if (medication.id == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int i = 0; i <= daysAhead; i++) {
      final date = today.add(Duration(days: i));
      final doses =
          await _doseUseCases.getDosesForMedicationOnDate(medication.id!, date);
      for (final d in doses) {
        if (d.id == null) continue;
        if (d.scheduledTime.isAfter(now) && !d.isTaken) {
          await _notificationService.cancelNotification(d.id!);
        }
      }
    }
  }

  bool _isMedicationScheduledOnDate(Medication medication, DateTime date) {
    if (medication.daysOfWeek.isEmpty) return true; // daily

    final weekdayName = _weekdayNamePt(date.weekday);

    for (final raw in medication.daysOfWeek) {
      final normalized = _normalizeWeekdayToPt(raw);
      if (normalized == weekdayName) return true;
    }

    return false;
  }

  String _normalizeWeekdayToPt(String value) {
    final v = value.trim().toLowerCase();
    switch (v) {
      case 'segunda':
      case 'seg':
      case 'monday':
      case 'mon':
        return 'segunda';
      case 'terça':
      case 'terca':
      case 'ter':
      case 'tuesday':
      case 'tue':
        return 'terça';
      case 'quarta':
      case 'qua':
      case 'wednesday':
      case 'wed':
        return 'quarta';
      case 'quinta':
      case 'qui':
      case 'thursday':
      case 'thu':
        return 'quinta';
      case 'sexta':
      case 'sex':
      case 'friday':
      case 'fri':
        return 'sexta';
      case 'sábado':
      case 'sabado':
      case 'sáb':
      case 'sab':
      case 'saturday':
      case 'sat':
        return 'sábado';
      case 'domingo':
      case 'dom':
      case 'sunday':
      case 'sun':
        return 'domingo';
      default:
        return v;
    }
  }

  String _weekdayNamePt(int weekday) {
    switch (weekday) {
      case 1:
        return 'segunda';
      case 2:
        return 'terça';
      case 3:
        return 'quarta';
      case 4:
        return 'quinta';
      case 5:
        return 'sexta';
      case 6:
        return 'sábado';
      case 7:
        return 'domingo';
      default:
        return 'segunda';
    }
  }

  DateTime? _buildDateTime(DateTime day, String time) {
    try {
      final parts = time.split(':');
      if (parts.length != 2) return null;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return DateTime(day.year, day.month, day.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  Duration _computeToleranceForMedication(Medication medication) {
    try {
      final times = medication.times;
      if (times.length < 2) return const Duration(hours: 12);

      final minutes = <int>[];
      for (final t in times) {
        final parts = t.split(':');
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        minutes.add(h * 60 + m);
      }
      minutes.sort();

      int minDiff = 24 * 60;
      for (int i = 0; i < minutes.length; i++) {
        final a = minutes[i];
        final b = minutes[(i + 1) % minutes.length];
        final diff = (b - a) > 0 ? (b - a) : (b + 24 * 60 - a);
        if (diff < minDiff) minDiff = diff;
      }

      final half = (minDiff / 2).floor();
      final tolMinutes = half.clamp(30, 12 * 60);
      return Duration(minutes: tolMinutes);
    } catch (_) {
      return const Duration(hours: 12);
    }
  }

  DoseStatus _computeDoseStatus({
    required DateTime now,
    required DateTime scheduled,
    required Duration tolerance,
    required DoseStatus currentStatus,
  }) {
    if (currentStatus == DoseStatus.taken) return DoseStatus.taken;

    if (now.isBefore(scheduled)) return DoseStatus.pending;

    if (now.isAfter(scheduled.add(tolerance))) return DoseStatus.missed;

    return DoseStatus.overdue;
  }
}
