import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dose_certa/presentation/bloc/medication/medication_bloc.dart';
import 'package:dose_certa/presentation/bloc/medication/medication_event.dart';
import 'package:dose_certa/presentation/bloc/medication/medication_state.dart';
import 'package:dose_certa/presentation/widgets/medication_card.dart';
import 'package:dose_certa/services/notification/notification_service.dart';
import 'package:dose_certa/domain/usecases/dose_usecases.dart';
import 'package:dose_certa/core/di/injection_container.dart';
import 'package:dose_certa/domain/entities/medication_dose.dart';
import 'package:dose_certa/core/routes/app_router.dart';
import 'package:dose_certa/core/theme/app_theme.dart';
import 'package:dose_certa/presentation/bloc/reminder/reminder_bloc.dart';
import 'package:dose_certa/services/notification/reminder_sync_service.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({Key? key}) : super(key: key);

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage>
    with WidgetsBindingObserver {
  final List<Timer> _statusTimers = [];
  Timer? _backupTimer;
  Timer? _transitionTimer;
  DateTime? _nextScheduledAt;

  @override
  void initState() {
    super.initState();
    context.read<MedicationBloc>().add(LoadMedications());
    context.read<ReminderBloc>().add(const SyncAllReminders(daysAhead: 7));
    WidgetsBinding.instance.addObserver(this);
    _scheduleStatusChecks();
    _backupTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _transitionTimer?.cancel();
    _backupTimer?.cancel();
    for (final timer in _statusTimers) {
      timer.cancel();
    }
    _statusTimers.clear();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Duration _computeToleranceForMedication(dynamic med) {
    try {
      if (med.times == null || (med.times as List).length < 2) {
        return const Duration(hours: 12);
      }
      final List<int> minutes = [];
      for (final t in med.times) {
        final parts = (t as String).split(':');
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        minutes.add(h * 60 + m);
      }
      minutes.sort();
      int minDiff = 24 * 60; // max
      for (int i = 0; i < minutes.length; i++) {
        final a = minutes[i];
        final b = minutes[(i + 1) % minutes.length];
        final diff = (b - a) > 0 ? (b - a) : (b + 24 * 60 - a);
        if (diff < minDiff) minDiff = diff;
      }
      final half = (minDiff / 2).floor();
      final tolMinutes = half.clamp(30, 12 * 60);
      return Duration(minutes: tolMinutes);
    } catch (_) {
      return const Duration(hours: 12);
    }
  }

  void _scheduleStatusChecks() async {
    for (final timer in _statusTimers) {
      timer.cancel();
    }
    _statusTimers.clear();

    final state = context.read<MedicationBloc>().state;
    if (state is! MedicationLoaded) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final medication in state.medications) {
      if (medication.daysOfWeek.isNotEmpty) {
        final todayWeekday = now.weekday;
        final todayWeekdayString = _getWeekdayString(todayWeekday);

        if (!medication.daysOfWeek.contains(todayWeekdayString)) {
          continue;
        }
      }
      for (final time in medication.times) {
        try {
          final parts = time.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final scheduled =
              DateTime(today.year, today.month, today.day, hour, minute, 0, 0);
          if (scheduled.isAfter(now)) {
            final diff = scheduled.difference(now);
            final timer = Timer(diff, () {
              if (mounted) {
                setState(() {}); // Força rebuild no horário exato
              }
            });
            _statusTimers.add(timer);
          }
        } catch (_) {}
      }
    }
  }

  void _scheduleNextTransition(List<dynamic> medications) {
    _transitionTimer?.cancel();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime? next;

    for (final med in medications) {
      if (med.times == null) continue;
      final medTolerance = _computeToleranceForMedication(med);
      for (final t in med.times) {
        try {
          final parts = (t as String).split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final scheduled =
              DateTime(today.year, today.month, today.day, hour, minute);

          if (scheduled.isAfter(now)) {
            if (next == null || scheduled.isBefore(next)) next = scheduled;
          } else if (now.isBefore(scheduled.add(medTolerance))) {
            final transition = scheduled.add(medTolerance);
            if (next == null || transition.isBefore(next)) next = transition;
          }
        } catch (_) {}
      }
    }

    if (next == null) {
      _nextScheduledAt = null;
      return;
    }
    if (_nextScheduledAt != null && _nextScheduledAt == next) return;

    _nextScheduledAt = next;

    final diff = next.difference(now);
    if (diff.isNegative || diff.inMilliseconds == 0) {
      if (mounted) setState(() {});
      return;
    }

    _transitionTimer = Timer(diff, () {
      if (mounted) setState(() {});
      final state = context.read<MedicationBloc>().state;
      if (state is MedicationLoaded) {
        _scheduleNextTransition(state.medications);
      }
    });
  }

  void _considerCandidateTransition(DateTime candidate) {
    final now = DateTime.now();
    if (candidate.isBefore(now)) return;
    if (_nextScheduledAt != null && !_nextScheduledAt!.isAfter(candidate))
      return;
    _transitionTimer?.cancel();
    _nextScheduledAt = candidate;
    final diff = candidate.difference(now);

    _transitionTimer = Timer(diff, () {
      if (mounted) setState(() {});
      final state = context.read<MedicationBloc>().state;
      if (state is MedicationLoaded) {
        _scheduleNextTransition(state.medications);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<MedicationBloc, MedicationState>(
                builder: (context, state) {
                  if (state is MedicationLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (state is MedicationError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.errorColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erro ao carregar medicamentos',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.message,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              context
                                  .read<MedicationBloc>()
                                  .add(LoadMedications());
                            },
                            child: const Text('Tentar Novamente'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is MedicationLoaded) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scheduleNextTransition(state.medications);
                      _scheduleStatusChecks(); // Reagenda os timers de status
                    });
                    if (state.medications.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<MedicationBloc>().add(LoadMedications());
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16,
                            100), // Extra padding no bottom para o FAB
                        itemCount: state.medications.length,
                        itemBuilder: (context, index) {
                          final medication = state.medications[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: FutureBuilder<List<MedicationDose>>(
                              future: _prepareTodayDoses(medication),
                              builder: (context, snapshot) {
                                final doses = snapshot.data ?? [];
                                return MedicationCard(
                                  medication: medication,
                                  todayDoses: doses,
                                  onTap: () {
                                    Navigator.of(context).pushNamed(
                                      AppRouter.medicationDetails,
                                      arguments: {
                                        'medicationId': medication.id
                                      },
                                    );
                                  },
                                  onEdit: () {
                                    Navigator.of(context).pushNamed(
                                      AppRouter.addReminder,
                                      arguments: {
                                        'medicationId': medication.id
                                      },
                                    );
                                  },
                                  onDelete: () {
                                    _showDeleteDialog(context, medication.id!);
                                  },
                                  onMarkAsTaken: (dose) {
                                    _markDoseAsTaken(context, dose);
                                    setState(() {});
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRouter.addReminder);
        },
        backgroundColor: AppColors.primaryBrown,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Adicionar Lembrete',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primaryBrownLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.medication,
                size: 60,
                color: AppColors.primaryBrown,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Nenhum lembrete criado',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Adicione seu primeiro medicamento para começar a receber lembretes personalizados.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, int medicationId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Excluir Medicamento'),
          content: const Text(
            'Tem certeza que deseja excluir este medicamento? Esta ação não pode ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<MedicationBloc>().add(
                      DeleteMedication(medicationId),
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorColor,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  void _markDoseAsTaken(BuildContext context, MedicationDose dose) {
    _markDoseAsTakenAsync(context, dose);
  }

  Future<void> _markDoseAsTakenAsync(
      BuildContext context, MedicationDose dose) async {
    final now = DateTime.now();

    try {
      int? persistedId;
      if (dose.id != null) {
        persistedId = dose.id;
        context.read<MedicationBloc>().add(MarkDoseAsTaken(dose.id!, now));
      } else {
        final doseUseCases = getIt<DoseUseCases>();
        final newDose = MedicationDose(
          medicationId: dose.medicationId,
          scheduledTime: dose.scheduledTime,
          createdAt: now,
        );
        final insertedId = await doseUseCases.insertDose(newDose);
        if (insertedId > 0) {
          persistedId = insertedId;
          context.read<MedicationBloc>().add(MarkDoseAsTaken(insertedId, now));
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dose marcada como tomada às ${_formatTime(now)}'),
          backgroundColor: AppColors.successColor,
          duration: const Duration(seconds: 2),
        ),
      );
      try {
        final medState = context.read<MedicationBloc>().state;
        if (medState is MedicationLoaded) {
          final matched = medState.medications
              .where((m) => m.id == dose.medicationId)
              .toList();
          if (matched.isNotEmpty) {
            final med = matched.first;
            if (med.id != null) {
              final currentStock = med.stockQuantity;
              final dosageAmount =
                  med.dosageAmount.toInt(); // Use the actual dosage amount
              final newStock = (currentStock - dosageAmount) < 0
                  ? 0
                  : (currentStock - dosageAmount);
              context
                  .read<MedicationBloc>()
                  .add(UpdateMedicationStock(med.id!, newStock));
            }
          } else {
            context.read<MedicationBloc>().add(LoadMedications());
          }
        } else {
          context.read<MedicationBloc>().add(LoadMedications());
        }
      } catch (_) {
        context.read<MedicationBloc>().add(LoadMedications());
      }
      setState(() {});
      final state = context.read<MedicationBloc>().state;
      if (state is MedicationLoaded) {
        _scheduleNextTransition(state.medications);
      }
      try {
        final notificationService = getIt<NotificationService>();
        if (persistedId != null) {
          await notificationService.cancelNotification(persistedId);
        }
      } catch (_) {}
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao marcar dose: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<List<MedicationDose>> _prepareTodayDoses(medication) async {
    final doseUseCases = getIt<DoseUseCases>();
    final syncService = getIt<ReminderSyncService>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (medication.daysOfWeek.isNotEmpty) {
      final todayWeekday = now.weekday; // 1=Monday, 7=Sunday
      final todayWeekdayString = _getWeekdayString(todayWeekday);

      if (!medication.daysOfWeek.contains(todayWeekdayString)) {
        return [];
      }
    }
    List<MedicationDose> doses = await doseUseCases.getDosesForMedicationOnDate(
        medication.id ?? 0, today);
    if (doses.isEmpty) {
      await syncService.syncMedication(medication, daysAhead: 1);
      doses = await doseUseCases.getDosesForMedicationOnDate(
          medication.id ?? 0, today);
    }
    final hasActiveToday = doses.any((d) =>
        d.status == DoseStatus.pending || d.status == DoseStatus.overdue);
    if (!hasActiveToday) {
      final tomorrow = today.add(const Duration(days: 1));
      var tomorrowDoses = await doseUseCases.getDosesForMedicationOnDate(
          medication.id ?? 0, tomorrow);
      if (tomorrowDoses.isEmpty) {
        await syncService.syncMedication(medication, daysAhead: 2);
        tomorrowDoses = await doseUseCases.getDosesForMedicationOnDate(
            medication.id ?? 0, tomorrow);
      }
      final future = tomorrowDoses
          .where((d) => d.scheduledTime.isAfter(now) && !d.isTaken)
          .toList();
      future.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
      if (future.isNotEmpty) {
        doses = [...doses, future.first];
      }
    }
    try {
      final now = DateTime.now();
      DateTime? candidate;
      for (final d in doses) {
        final scheduled = d.scheduledTime;
        if (scheduled.isAfter(now)) {
          if (candidate == null || scheduled.isBefore(candidate))
            candidate = scheduled;
        } else {
          final tolerance = const Duration(hours: 12);
          final missTime = scheduled.add(tolerance);
          if (now.isBefore(missTime)) {
            if (candidate == null || missTime.isBefore(candidate))
              candidate = missTime;
          }
        }
      }
      if (candidate != null) _considerCandidateTransition(candidate);
    } catch (_) {}

    return doses;
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _getWeekdayString(int weekday) {
    switch (weekday) {
      case 1:
        return 'segunda';
      case 2:
        return 'terça';
      case 3:
        return 'quarta';
      case 4:
        return 'quinta';
      case 5:
        return 'sexta';
      case 6:
        return 'sábado';
      case 7:
        return 'domingo';
      default:
        return 'segunda';
    }
  }
}
