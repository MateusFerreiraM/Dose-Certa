import 'package:dose_certa/data/database/database_helper.dart';
import 'package:dose_certa/domain/entities/medication_dose.dart';
import 'package:dose_certa/domain/repositories/medication_dose_repository.dart';

class MedicationDoseRepositoryImpl implements MedicationDoseRepository {
  final DatabaseHelper _db;

  MedicationDoseRepositoryImpl(this._db);

  DoseStatus _statusFromString(String? s) {
    switch (s) {
      case 'overdue':
        return DoseStatus.overdue;
      case 'missed':
        return DoseStatus.missed;
      case 'taken':
        return DoseStatus.taken;
      default:
        return DoseStatus.pending;
    }
  }

  @override
  Future<int> insertDose(MedicationDose dose) async {
    final data = <String, dynamic>{
      'medication_id': dose.medicationId,
      'scheduled_time': dose.scheduledTime.millisecondsSinceEpoch,
      'status': dose.status.name,
      'taken_at': dose.takenAt?.millisecondsSinceEpoch,
      'dose_amount': null,
      'unit': null,
      'created_at': dose.createdAt.millisecondsSinceEpoch,
      'updated_at': dose.updatedAt?.millisecondsSinceEpoch,
    };

    return await _db.insertDose(data);
  }

  MedicationDose _fromMap(Map<String, dynamic> m) {
    DateTime _toDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is double) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
      if (v is String) {
        final asInt = int.tryParse(v);
        if (asInt != null) return DateTime.fromMillisecondsSinceEpoch(asInt);
        final dt = DateTime.tryParse(v);
        if (dt != null) return dt;
      }
      return DateTime.now();
    }

    final id = m['id'] is int
        ? m['id'] as int
        : (m['id'] is String ? int.tryParse(m['id']) : null);
    final medicationId = m['medication_id'] is int
        ? m['medication_id'] as int
        : int.tryParse(m['medication_id']?.toString() ?? '0') ?? 0;

    final scheduledTime = _toDate(m['scheduled_time']);
    final takenAt = m['taken_at'] != null ? _toDate(m['taken_at']) : null;
    final createdAt = _toDate(m['created_at']);
    final updatedAt = m['updated_at'] != null ? _toDate(m['updated_at']) : null;

    final status = _statusFromString(m['status'] as String?);

    return MedicationDose(
      id: id,
      medicationId: medicationId,
      scheduledTime: scheduledTime,
      status: status,
      takenAt: takenAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  Future<List<MedicationDose>> getDosesForMedicationOnDate(
      int medicationId, DateTime date) async {
    final maps = await _db.getDosesForMedicationOnDate(medicationId, date);
    return maps.map((m) => _fromMap(m)).toList();
  }

  @override
  Future<List<MedicationDose>> getDosesForMedicationInRange(
    int medicationId,
    DateTime startInclusive,
    DateTime endExclusive,
  ) async {
    final maps = await _db.getDosesForMedicationInRange(
        medicationId, startInclusive, endExclusive);
    return maps.map((m) => _fromMap(m)).toList();
  }

  @override
  Future<bool> markDoseAsTaken(int doseId, DateTime takenAt) async {
    return await _db.markDoseAsTaken(doseId, takenAt);
  }

  @override
  Future<bool> updateDose(MedicationDose dose) async {
    if (dose.id == null) return false;
    final data = <String, dynamic>{
      'medication_id': dose.medicationId,
      'scheduled_time': dose.scheduledTime.millisecondsSinceEpoch,
      'status': dose.status.name,
      'taken_at': dose.takenAt?.millisecondsSinceEpoch,
      'updated_at': dose.updatedAt?.millisecondsSinceEpoch,
    };
    return await _db.updateDose(dose.id!, data);
  }

  @override
  Future<bool> deleteDose(int id) async {
    return await _db.deleteDose(id);
  }

  Future<int> deleteDosesForMedication(int medicationId) async {
    return await _db.deleteDosesForMedication(medicationId);
  }
}
