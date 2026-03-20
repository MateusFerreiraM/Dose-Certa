import 'package:equatable/equatable.dart';
import 'package:dose_certa/domain/entities/medication.dart';

abstract class MedicationEvent extends Equatable {
  const MedicationEvent();

  @override
  List<Object?> get props => [];
}

class LoadMedications extends MedicationEvent {}

class AddMedication extends MedicationEvent {
  final Medication medication;

  const AddMedication(this.medication);

  @override
  List<Object?> get props => [medication];
}

class UpdateMedication extends MedicationEvent {
  final Medication medication;

  const UpdateMedication(this.medication);

  @override
  List<Object?> get props => [medication];
}

class DeleteMedication extends MedicationEvent {
  final int medicationId;

  const DeleteMedication(this.medicationId);

  @override
  List<Object?> get props => [medicationId];
}

class UpdateMedicationStock extends MedicationEvent {
  final int medicationId;
  final int newStock;

  const UpdateMedicationStock(this.medicationId, this.newStock);

  @override
  List<Object?> get props => [medicationId, newStock];
}

class PauseMedication extends MedicationEvent {
  final int medicationId;

  const PauseMedication(this.medicationId);

  @override
  List<Object?> get props => [medicationId];
}

class ResumeMedication extends MedicationEvent {
  final int medicationId;

  const ResumeMedication(this.medicationId);

  @override
  List<Object?> get props => [medicationId];
}

class ToggleMedicationStatus extends MedicationEvent {
  final int medicationId;

  const ToggleMedicationStatus(this.medicationId);

  @override
  List<Object?> get props => [medicationId];
}

class LoadLowStockMedications extends MedicationEvent {}

class RefreshMedications extends MedicationEvent {}

class MarkDoseAsTaken extends MedicationEvent {
  final int doseId;
  final DateTime takenAt;

  const MarkDoseAsTaken(this.doseId, this.takenAt);

  @override
  List<Object?> get props => [doseId, takenAt];
}
