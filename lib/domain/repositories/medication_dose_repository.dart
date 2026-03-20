import 'package:dose_certa/domain/entities/medication_dose.dart';

abstract class MedicationDoseRepository {
  Future<int> insertDose(MedicationDose dose);
  Future<List<MedicationDose>> getDosesForMedicationOnDate(
      int medicationId, DateTime date);
  Future<List<MedicationDose>> getDosesForMedicationInRange(
    int medicationId,
    DateTime startInclusive,
    DateTime endExclusive,
  );
  Future<bool> markDoseAsTaken(int doseId, DateTime takenAt);
  Future<bool> updateDose(MedicationDose dose);
  Future<bool> deleteDose(int id);
}
