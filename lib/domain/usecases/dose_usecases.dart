import 'package:dose_certa/domain/entities/medication_dose.dart';
import 'package:dose_certa/domain/repositories/medication_dose_repository.dart';

class DoseUseCases {
  final MedicationDoseRepository repository;

  DoseUseCases(this.repository);

  Future<bool> markDoseAsTaken(int doseId, DateTime takenAt) async {
    return await repository.markDoseAsTaken(doseId, takenAt);
  }

  Future<List<MedicationDose>> getDosesForMedicationOnDate(
      int medicationId, DateTime date) async {
    return await repository.getDosesForMedicationOnDate(medicationId, date);
  }

  Future<List<MedicationDose>> getDosesForMedicationInRange(
    int medicationId,
    DateTime startInclusive,
    DateTime endExclusive,
  ) async {
    return await repository.getDosesForMedicationInRange(
        medicationId, startInclusive, endExclusive);
  }

  Future<int> insertDose(MedicationDose dose) async {
    return await repository.insertDose(dose);
  }

  Future<bool> updateDose(MedicationDose dose) async {
    return await repository.updateDose(dose);
  }

  Future<bool> deleteDose(int id) async {
    return await repository.deleteDose(id);
  }
}
