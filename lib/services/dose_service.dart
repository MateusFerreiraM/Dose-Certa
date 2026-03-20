import 'package:dose_certa/domain/entities/medication_dose.dart';

class DoseService {
  static Map<String, MedicationDose> _takenDoses = {};

  /// Gera uma chave única para identificar uma dose
  static String _getDoseKey(int medicationId, DateTime scheduledTime) {
    final timeStr =
        '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';
    final dateStr =
        '${scheduledTime.year}-${scheduledTime.month.toString().padLeft(2, '0')}-${scheduledTime.day.toString().padLeft(2, '0')}';
    return '${medicationId}_${dateStr}_$timeStr';
  }

  /// Gera as doses para um medicamento em uma data específica
  static List<MedicationDose> generateDosesForDate({
    required int medicationId,
    required DateTime date,
    required List<String> times,
  }) {
    final doses = <MedicationDose>[];

    for (final timeStr in times) {
      final timeParts = timeStr.split(':');
      if (timeParts.length == 2) {
        final hour = int.tryParse(timeParts[0]) ?? 0;
        final minute = int.tryParse(timeParts[1]) ?? 0;

        final scheduledTime = DateTime(
          date.year,
          date.month,
          date.day,
          hour,
          minute,
        );

        final doseKey = _getDoseKey(medicationId, scheduledTime);
        if (_takenDoses.containsKey(doseKey)) {
          doses.add(_takenDoses[doseKey]!);
        } else {
          final dose = MedicationDose(
            medicationId: medicationId,
            scheduledTime: scheduledTime,
            status: _getDoseStatus(scheduledTime),
            createdAt: DateTime.now(),
          );

          doses.add(dose);
        }
      }
    }

    return doses;
  }

  /// Determina o status inicial da dose baseado no horário
  static DoseStatus _getDoseStatus(DateTime scheduledTime) {
    final now = DateTime.now();

    if (scheduledTime.isAfter(now)) {
      return DoseStatus.pending;
    } else {
      return DoseStatus
          .pending; // Será atualizado para overdue quando verificado
    }
  }

  /// Atualiza o status das doses baseado no tempo atual
  static List<MedicationDose> updateDoseStatuses(List<MedicationDose> doses) {
    final now = DateTime.now();
    const toleranceHours = 4; // Janela de tolerância de 4 horas

    return doses.map((dose) {
      if (dose.status == DoseStatus.taken || dose.status == DoseStatus.missed) {
        return dose; // Não altera doses já finalizadas
      }

      final timeSinceScheduled = now.difference(dose.scheduledTime).inHours;

      if (dose.scheduledTime.isAfter(now)) {
        return dose.copyWith(status: DoseStatus.pending);
      } else if (timeSinceScheduled <= toleranceHours) {
        return dose.copyWith(status: DoseStatus.overdue);
      } else {
        return dose.copyWith(status: DoseStatus.missed);
      }
    }).toList();
  }

  /// Marca uma dose como tomada e salva no 'banco de dados' temporário
  static MedicationDose markDoseAsTaken(MedicationDose dose) {
    final takenDose = dose.copyWith(
      status: DoseStatus.taken,
      takenAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final doseKey = _getDoseKey(dose.medicationId, dose.scheduledTime);
    _takenDoses[doseKey] = takenDose;

    return takenDose;
  }

  /// Limpa todas as doses tomadas (para testes)
  static void clearTakenDoses() {
    _takenDoses.clear();
  }

  /// Simula doses para demonstração
  static List<MedicationDose> getMockDosesForMedication({
    required int medicationId,
    required List<String> times,
  }) {
    final today = DateTime.now();
    final todayDoses = generateDosesForDate(
      medicationId: medicationId,
      date: today,
      times: times,
    );
    final updatedTodayDoses = updateDoseStatuses(todayDoses);
    final hasActiveDoses = updatedTodayDoses.any((dose) =>
        dose.status == DoseStatus.pending || dose.status == DoseStatus.overdue);

    if (!hasActiveDoses && times.isNotEmpty) {
      final tomorrow = today.add(const Duration(days: 1));
      final tomorrowDoses = generateDosesForDate(
        medicationId: medicationId,
        date: tomorrow,
        times: [times.first], // Apenas o primeiro horário de amanhã
      );

      return [...updatedTodayDoses, ...tomorrowDoses];
    }

    return updatedTodayDoses;
  }
}
