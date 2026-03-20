import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dose_certa/presentation/bloc/medication/medication_event.dart';
import 'package:dose_certa/presentation/bloc/medication/medication_state.dart';
import 'package:dose_certa/domain/repositories/medication_repository.dart';
import 'package:dose_certa/domain/usecases/dose_usecases.dart';
import 'package:dose_certa/services/notification/reminder_sync_service.dart';

class MedicationBloc extends Bloc<MedicationEvent, MedicationState> {
  final MedicationRepository _medicationRepository;
  final DoseUseCases _doseUseCases;
  final ReminderSyncService _reminderSyncService;

  MedicationBloc(
      this._medicationRepository, this._doseUseCases, this._reminderSyncService)
      : super(MedicationInitial()) {
    on<LoadMedications>(_onLoadMedications);
    on<AddMedication>(_onAddMedication);
    on<UpdateMedication>(_onUpdateMedication);
    on<DeleteMedication>(_onDeleteMedication);
    on<UpdateMedicationStock>(_onUpdateMedicationStock);
    on<PauseMedication>(_onPauseMedication);
    on<ResumeMedication>(_onResumeMedication);
    on<ToggleMedicationStatus>(_onToggleMedicationStatus);
    on<LoadLowStockMedications>(_onLoadLowStockMedications);
    on<RefreshMedications>(_onRefreshMedications);
    on<MarkDoseAsTaken>(_onMarkDoseAsTaken);
  }

  Future<void> _onLoadMedications(
    LoadMedications event,
    Emitter<MedicationState> emit,
  ) async {
    emit(MedicationLoading());
    try {
      final medications = await _medicationRepository.getAllMedications();
      emit(MedicationLoaded(medications));
    } catch (e) {
      emit(MedicationError('Erro ao carregar medicamentos: ${e.toString()}'));
    }
  }

  Future<void> _onAddMedication(
    AddMedication event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      final id = await _medicationRepository.addMedication(event.medication);
      if (id > 0) {
        final med = await _medicationRepository.getMedicationById(id);
        if (med != null) {
          await _reminderSyncService.syncMedication(med, daysAhead: 7);
        }
      }
      emit(const MedicationOperationSuccess(
          'Medicamento adicionado com sucesso!'));
      add(LoadMedications()); // Recarregar lista
    } catch (e) {
      emit(MedicationError('Erro ao adicionar medicamento: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateMedication(
    UpdateMedication event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      await _medicationRepository.updateMedication(event.medication);
      await _reminderSyncService.syncMedication(event.medication, daysAhead: 7);
      emit(const MedicationOperationSuccess(
          'Medicamento atualizado com sucesso!'));
      add(LoadMedications()); // Recarregar lista
    } catch (e) {
      emit(MedicationError('Erro ao atualizar medicamento: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteMedication(
    DeleteMedication event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      await _reminderSyncService
          .cancelUpcomingForMedicationId(event.medicationId, daysAhead: 7);
      await _medicationRepository.deleteMedication(event.medicationId);
      emit(const MedicationOperationSuccess(
          'Medicamento excluído com sucesso!'));
      add(LoadMedications()); // Recarregar lista
    } catch (e) {
      emit(MedicationError('Erro ao excluir medicamento: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateMedicationStock(
    UpdateMedicationStock event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      await _medicationRepository.updateMedicationStock(
        event.medicationId,
        event.newStock,
      );
      final med =
          await _medicationRepository.getMedicationById(event.medicationId);
      if (med != null) {
        await _reminderSyncService.syncMedication(med, daysAhead: 2);
      }
      emit(const MedicationOperationSuccess('Estoque atualizado com sucesso!'));
      add(LoadMedications()); // Recarregar lista
    } catch (e) {
      emit(MedicationError('Erro ao atualizar estoque: ${e.toString()}'));
    }
  }

  Future<void> _onPauseMedication(
    PauseMedication event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      await _medicationRepository.pauseMedication(event.medicationId);
      final med =
          await _medicationRepository.getMedicationById(event.medicationId);
      if (med != null) {
        await _reminderSyncService.syncMedication(med, daysAhead: 7);
      }
      emit(
          const MedicationOperationSuccess('Medicamento pausado com sucesso!'));
      add(LoadMedications()); // Recarregar lista
    } catch (e) {
      emit(MedicationError('Erro ao pausar medicamento: ${e.toString()}'));
    }
  }

  Future<void> _onResumeMedication(
    ResumeMedication event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      await _medicationRepository.resumeMedication(event.medicationId);
      final med =
          await _medicationRepository.getMedicationById(event.medicationId);
      if (med != null) {
        await _reminderSyncService.syncMedication(med, daysAhead: 7);
      }
      emit(const MedicationOperationSuccess(
          'Medicamento reativado com sucesso!'));
      add(LoadMedications()); // Recarregar lista
    } catch (e) {
      emit(MedicationError('Erro ao reativar medicamento: ${e.toString()}'));
    }
  }

  Future<void> _onToggleMedicationStatus(
    ToggleMedicationStatus event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      if (state is MedicationLoaded) {
        final medications = (state as MedicationLoaded).medications;
        final medication = medications.firstWhere(
          (med) => med.id == event.medicationId,
          orElse: () => throw Exception('Medicamento não encontrado'),
        );

        if (medication.isPaused) {
          await _medicationRepository.resumeMedication(event.medicationId);
          emit(const MedicationOperationSuccess(
              'Medicamento reativado com sucesso!'));
        } else {
          await _medicationRepository.pauseMedication(event.medicationId);
          emit(const MedicationOperationSuccess(
              'Medicamento pausado com sucesso!'));
        }

        final updated =
            await _medicationRepository.getMedicationById(event.medicationId);
        if (updated != null) {
          await _reminderSyncService.syncMedication(updated, daysAhead: 7);
        }
        add(LoadMedications()); // Recarregar lista
      }
    } catch (e) {
      emit(MedicationError(
          'Erro ao alterar status do medicamento: ${e.toString()}'));
    }
  }

  Future<void> _onLoadLowStockMedications(
    LoadLowStockMedications event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      final lowStockMedications =
          await _medicationRepository.getLowStockMedications();
      emit(LowStockMedicationsLoaded(lowStockMedications));
    } catch (e) {
      emit(MedicationError(
          'Erro ao carregar medicamentos com estoque baixo: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshMedications(
    RefreshMedications event,
    Emitter<MedicationState> emit,
  ) async {
    add(LoadMedications());
  }

  Future<void> _onMarkDoseAsTaken(
    MarkDoseAsTaken event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      await _doseUseCases.markDoseAsTaken(event.doseId, event.takenAt);
      emit(const MedicationOperationSuccess('Dose marcada como tomada'));
      add(LoadMedications());
    } catch (e) {
      emit(MedicationError('Erro ao marcar dose como tomada: ${e.toString()}'));
    }
  }
}
