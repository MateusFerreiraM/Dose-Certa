import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:dose_certa/services/notification/reminder_sync_service.dart';

abstract class ReminderEvent extends Equatable {
  const ReminderEvent();

  @override
  List<Object?> get props => [];
}

class SyncAllReminders extends ReminderEvent {
  final int daysAhead;

  const SyncAllReminders({this.daysAhead = 7});

  @override
  List<Object?> get props => [daysAhead];
}

abstract class ReminderState extends Equatable {
  const ReminderState();

  @override
  List<Object?> get props => [];
}

class ReminderInitial extends ReminderState {}

class ReminderSyncInProgress extends ReminderState {}

class ReminderSyncSuccess extends ReminderState {
  final DateTime syncedAt;

  const ReminderSyncSuccess(this.syncedAt);

  @override
  List<Object?> get props => [syncedAt];
}

class ReminderError extends ReminderState {
  final String message;

  const ReminderError(this.message);

  @override
  List<Object?> get props => [message];
}

class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  final ReminderSyncService _syncService;

  ReminderBloc(this._syncService) : super(ReminderInitial()) {
    on<SyncAllReminders>(_onSyncAll);
  }

  Future<void> _onSyncAll(
    SyncAllReminders event,
    Emitter<ReminderState> emit,
  ) async {
    emit(ReminderSyncInProgress());
    try {
      await _syncService.syncAll(daysAhead: event.daysAhead);
      emit(ReminderSyncSuccess(DateTime.now()));
    } catch (e) {
      emit(ReminderError('Erro ao sincronizar lembretes: ${e.toString()}'));
    }
  }
}
