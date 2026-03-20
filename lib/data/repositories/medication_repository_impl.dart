import 'package:dose_certa/domain/entities/medication.dart';
import 'package:dose_certa/domain/repositories/medication_repository.dart';
import 'package:dose_certa/data/database/database_helper.dart';

class MedicationRepositoryImpl implements MedicationRepository {
  final DatabaseHelper _databaseHelper;

  MedicationRepositoryImpl(this._databaseHelper);

  @override
  Future<List<Medication>> getAllMedications() async {
    try {
      final maps = await _databaseHelper.getAllMedications();
      final medications = <Medication>[];

      for (final map in maps) {
        final schedules =
            await _databaseHelper.getMedicationSchedules(map['id']);
        final medicationSchedules =
            schedules.map((s) => MedicationSchedule.fromMap(s)).toList();

        final medication = Medication.fromMap(map).copyWith(
          schedules: medicationSchedules,
        );
        medications.add(medication);
      }

      return medications;
    } catch (e) {
      throw Exception('Erro ao buscar medicamentos: $e');
    }
  }

  @override
  Future<Medication?> getMedicationById(int id) async {
    try {
      final map = await _databaseHelper.getMedicationById(id);
      if (map == null) return null;
      final schedules = await _databaseHelper.getMedicationSchedules(id);
      final medicationSchedules =
          schedules.map((s) => MedicationSchedule.fromMap(s)).toList();

      return Medication.fromMap(map).copyWith(
        schedules: medicationSchedules,
      );
    } catch (e) {
      throw Exception('Erro ao buscar medicamento: $e');
    }
  }

  @override
  Future<int> addMedication(Medication medication) async {
    try {
      final medicationData = medication.toMap();
      medicationData.remove('id'); // Remove ID para auto-increment
      medicationData['created_at'] = DateTime.now().millisecondsSinceEpoch;

      final medicationId =
          await _databaseHelper.insertMedication(medicationData);
      if (medication.schedules != null && medication.schedules!.isNotEmpty) {
        for (final schedule in medication.schedules!) {
          final scheduleData =
              schedule.copyWith(medicationId: medicationId).toMap();
          scheduleData.remove('id');
          scheduleData['created_at'] = DateTime.now().millisecondsSinceEpoch;

          await _databaseHelper.insertMedicationSchedule(scheduleData);
        }
      }

      return medicationId;
    } catch (e) {
      throw Exception('Erro ao adicionar medicamento: $e');
    }
  }

  @override
  Future<bool> updateMedication(Medication medication) async {
    try {
      if (medication.id == null) return false;

      final medicationData = medication.toMap();
      medicationData['updated_at'] = DateTime.now().millisecondsSinceEpoch;

      final result = await _databaseHelper.updateMedication(
          medication.id!, medicationData);
      if (medication.schedules != null) {
        await _databaseHelper.deleteMedicationSchedules(medication.id!);

        if (medication.schedules!.isNotEmpty) {
          for (final schedule in medication.schedules!) {
            final scheduleData =
                schedule.copyWith(medicationId: medication.id!).toMap();
            scheduleData.remove('id');
            scheduleData['created_at'] = DateTime.now().millisecondsSinceEpoch;

            await _databaseHelper.insertMedicationSchedule(scheduleData);
          }
        }
      }

      return result;
    } catch (e) {
      throw Exception('Erro ao atualizar medicamento: $e');
    }
  }

  @override
  Future<bool> deleteMedication(int id) async {
    try {
      try {
        await _databaseHelper.deleteMedicationSchedules(id);
      } catch (_) {}
      try {
        await _databaseHelper.deleteDosesForMedication(id);
      } catch (_) {}
      final result = await _databaseHelper.deleteMedication(id);
      return result;
    } catch (e) {
      throw Exception('Erro ao excluir medicamento: $e');
    }
  }

  @override
  Future<bool> updateMedicationStock(int medicationId, int newStock) async {
    try {
      final medicationData = {
        'stock_quantity': newStock,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      };

      final result =
          await _databaseHelper.updateMedication(medicationId, medicationData);
      return result;
    } catch (e) {
      throw Exception('Erro ao atualizar estoque: $e');
    }
  }

  @override
  Future<List<Medication>> getLowStockMedications() async {
    try {
      final medications = await getAllMedications();
      return medications
          .where((m) => m.needsStockAlert && m.stockAlertsEnabled)
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar medicamentos com estoque baixo: $e');
    }
  }

  @override
  Future<bool> pauseMedication(int medicationId) async {
    try {
      final medicationData = {
        'is_active': 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      };

      final result =
          await _databaseHelper.updateMedication(medicationId, medicationData);
      return result;
    } catch (e) {
      throw Exception('Erro ao pausar medicamento: $e');
    }
  }

  @override
  Future<bool> resumeMedication(int medicationId) async {
    try {
      final medicationData = {
        'is_active': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      };

      final result =
          await _databaseHelper.updateMedication(medicationId, medicationData);
      return result;
    } catch (e) {
      throw Exception('Erro ao reativar medicamento: $e');
    }
  }
}
