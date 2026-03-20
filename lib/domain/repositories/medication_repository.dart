import 'package:dose_certa/domain/entities/medication.dart';

abstract class MedicationRepository {
  Future<List<Medication>> getAllMedications();
  Future<Medication?> getMedicationById(int id);
  Future<int> addMedication(Medication medication);
  Future<bool> updateMedication(Medication medication);
  Future<bool> deleteMedication(int id);
  Future<bool> updateMedicationStock(int medicationId, int newStock);
  Future<List<Medication>> getLowStockMedications();
  Future<bool> pauseMedication(int medicationId);
  Future<bool> resumeMedication(int medicationId);
}
