import 'package:dose_certa/domain/entities/medication.dart';
import 'package:dose_certa/domain/repositories/medication_repository.dart';

class MedicationUseCases {
  final MedicationRepository repository;

  MedicationUseCases(this.repository);

  Future<List<Medication>> getAllMedications() async {
    return await repository.getAllMedications();
  }

  Future<Medication?> getMedicationById(int id) async {
    return await repository.getMedicationById(id);
  }

  Future<int> addMedication(Medication medication) async {
    return await repository.addMedication(medication);
  }

  Future<void> updateMedication(Medication medication) async {
    await repository.updateMedication(medication);
  }

  Future<void> deleteMedication(int id) async {
    await repository.deleteMedication(id);
  }

  Future<void> updateMedicationStock(int id, int newStock) async {
    await repository.updateMedicationStock(id, newStock);
  }
}
