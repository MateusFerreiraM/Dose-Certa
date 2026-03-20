import 'package:equatable/equatable.dart';
import 'package:dose_certa/domain/entities/medication.dart';

abstract class MedicationState extends Equatable {
  const MedicationState();

  @override
  List<Object?> get props => [];
}

class MedicationInitial extends MedicationState {}

class MedicationLoading extends MedicationState {}

class MedicationLoaded extends MedicationState {
  final List<Medication> medications;

  const MedicationLoaded(this.medications);

  @override
  List<Object?> get props => [medications];
}

class MedicationError extends MedicationState {
  final String message;

  const MedicationError(this.message);

  @override
  List<Object?> get props => [message];
}

class MedicationOperationSuccess extends MedicationState {
  final String message;

  const MedicationOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class LowStockMedicationsLoaded extends MedicationState {
  final List<Medication> lowStockMedications;

  const LowStockMedicationsLoaded(this.lowStockMedications);

  @override
  List<Object?> get props => [lowStockMedications];
}
