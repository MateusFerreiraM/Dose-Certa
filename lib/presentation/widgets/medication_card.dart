import 'package:flutter/material.dart';
import 'package:dose_certa/domain/entities/medication.dart';
import 'package:dose_certa/domain/entities/medication_dose.dart';
import 'package:dose_certa/core/theme/app_theme.dart';

class MedicationCard extends StatelessWidget {
  final Medication medication;
  final List<MedicationDose> todayDoses; // Doses de hoje
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(MedicationDose)? onMarkAsTaken;

  const MedicationCard({
    Key? key,
    required this.medication,
    this.todayDoses = const [],
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onMarkAsTaken,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentDose = _getCurrentDose();
    final now = DateTime.now();

    Duration computeTolerance() {
      try {
        final times = medication.times;
        if (times.isEmpty) return const Duration(hours: 12);
        if (times.length < 2) return const Duration(hours: 12);
        final minutes = <int>[];
        for (final t in times) {
          final parts = (t.toString()).split(':');
          final h = int.tryParse(parts[0]) ?? 0;
          final m = int.tryParse(parts[1]) ?? 0;
          minutes.add(h * 60 + m);
        }
        minutes.sort();
        int minDiff = 24 * 60;
        for (int i = 0; i < minutes.length; i++) {
          final a = minutes[i];
          final b = minutes[(i + 1) % minutes.length];
          final diff = (b - a) > 0 ? (b - a) : (b + 24 * 60 - a);
          if (diff < minDiff) minDiff = diff;
        }
        final half = (minDiff / 2).floor();
        final tol = half.clamp(30, 12 * 60);
        return Duration(minutes: tol);
      } catch (_) {
        return const Duration(hours: 12);
      }
    }

    final tolerance = computeTolerance();

    DoseStatus? displayStatus;
    if (currentDose == null) {
      displayStatus = null;
    } else if (currentDose.isTaken) {
      displayStatus = DoseStatus.taken;
    } else if (now.isAfter(currentDose.scheduledTime.add(tolerance))) {
      displayStatus = DoseStatus.missed;
    } else if (now.isAfter(currentDose.scheduledTime) ||
        now.isAtSameMomentAs(currentDose.scheduledTime)) {
      displayStatus = DoseStatus.overdue;
    } else {
      displayStatus = DoseStatus.pending;
    }

    final statusColor = _getStatusColorByDisplay(displayStatus);
    final statusText = _getStatusTextByDisplay(currentDose, displayStatus);

    return Card(
      elevation: 6,
      color: AppColors.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          if (onTap != null) onTap!();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primaryBrownLight,
                          AppColors.primaryBrown
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.medication,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _buildScheduleText(),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (onEdit != null)
                        Material(
                          color: AppColors.surfaceColor,
                          shape: const CircleBorder(),
                          elevation: 2,
                          child: IconButton(
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit_outlined),
                            iconSize: 20,
                            color: AppColors.primaryBrown,
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (onDelete != null)
                        Material(
                          color: AppColors.surfaceColor,
                          shape: const CircleBorder(),
                          elevation: 2,
                          child: IconButton(
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete_outline),
                            iconSize: 20,
                            color: AppColors.errorColor,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${medication.stockQuantity} ${_getUnitName(medication.unit)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  if (medication.needsStockAlert) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.warning_outlined,
                      size: 16,
                      color: AppColors.warningColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Estoque baixo',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.warningColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  if (displayStatus == DoseStatus.overdue &&
                      currentDose != null) {
                    onMarkAsTaken?.call(currentDose);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: statusColor.withOpacity(0.25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Icon(
                        _getStatusIconByDisplay(displayStatus),
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          statusText,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                          softWrap: true,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildScheduleText() {
    final timeText = medication.times.join(', ');
    if (medication.frequency == 'daily' ||
        medication.frequency == 'diario' ||
        medication.daysOfWeek.length == 7) {
      return 'Todos os dias - $timeText';
    } else if (medication.daysOfWeek.isNotEmpty) {
      final uniqueDays = medication.daysOfWeek.toSet().toList();

      final dayNames = uniqueDays
          .map((day) {
            String dayStr = day.toString();
            int? dayInt = int.tryParse(dayStr);
            if (dayInt != null) {
              switch (dayInt) {
                case 1:
                  return 'Seg';
                case 2:
                  return 'Ter';
                case 3:
                  return 'Qua';
                case 4:
                  return 'Qui';
                case 5:
                  return 'Sex';
                case 6:
                  return 'Sáb';
                case 7:
                  return 'Dom';
                default:
                  return '';
              }
            }
            switch (dayStr.toLowerCase()) {
              case 'segunda':
              case 'monday':
                return 'Seg';
              case 'terça':
              case 'tuesday':
                return 'Ter';
              case 'quarta':
              case 'wednesday':
                return 'Qua';
              case 'quinta':
              case 'thursday':
                return 'Qui';
              case 'sexta':
              case 'friday':
                return 'Sex';
              case 'sábado':
              case 'saturday':
                return 'Sáb';
              case 'domingo':
              case 'sunday':
                return 'Dom';
              default:
                return '';
            }
          })
          .where((name) => name.isNotEmpty)
          .join(', ');

      if (dayNames.isNotEmpty) {
        return '$dayNames - $timeText';
      }
    }
    if (medication.frequency == 'weekly') {
      return 'Dias específicos - $timeText';
    }
    return 'Todos os dias - $timeText';
  }

  /// Encontra a dose atual mais relevante para mostrar no card
  MedicationDose? _getCurrentDose() {
    if (todayDoses.isEmpty) return null;

    final now = DateTime.now();
    const tolerance = Duration(hours: 12);

    final overdue = <MedicationDose>[];
    final pending = <MedicationDose>[];
    final taken = <MedicationDose>[];
    final missed = <MedicationDose>[];

    for (final dose in todayDoses) {
      if (dose.isTaken) {
        taken.add(dose);
        continue;
      }
      final scheduled = dose.scheduledTime;
      if (now.isAfter(scheduled.add(tolerance))) {
        missed.add(dose);
      } else if (now.isAfter(scheduled) || now.isAtSameMomentAs(scheduled)) {
        overdue.add(dose);
      } else {
        pending.add(dose);
      }
    }

    if (overdue.isNotEmpty) {
      overdue.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
      return overdue.first;
    }

    if (pending.isNotEmpty) {
      pending.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
      return pending.first;
    }

    if (taken.isNotEmpty) {
      taken.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
      return taken.first;
    }

    if (missed.isNotEmpty) {
      missed.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
      return missed.first;
    }

    return todayDoses.first;
  }

  Color _getStatusColorByDisplay(DoseStatus? display) {
    if (display == null) return AppColors.textSecondary;
    switch (display) {
      case DoseStatus.pending:
        return AppColors.pendingBlue;
      case DoseStatus.overdue:
        return AppColors.errorColor;
      case DoseStatus.missed:
        return AppColors.textSecondary;
      case DoseStatus.taken:
        return AppColors.successColor;
    }
  }

  String _getStatusTextByDisplay(MedicationDose? dose, DoseStatus? display) {
    if (dose == null || display == null) {
      final next = _getNextScheduledDateTime();
      if (next != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        if (next.year == today.year && next.month == today.month && next.day == today.day) {
          return 'Próxima dose às ${_formatTime(next)}';
        }
        
        final daysDifference = DateTime(next.year, next.month, next.day).difference(today).inDays;
        
        if (daysDifference == 1) {
          return 'Próxima dose amanhã às ${_formatTime(next)}';
        } else {
          final weekdays = ['', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
          final weekdayStr = weekdays[next.weekday];
          return 'Próxima dose $weekdayStr às ${_formatTime(next)}';
        }
      }
      return 'Sem doses previsíveis';
    }
    if (display == DoseStatus.overdue)
      return 'Clique aqui para marcar como tomado';
    if (display == DoseStatus.taken)
      return 'Tomado às ${_formatTime(dose.takenAt ?? dose.scheduledTime)}';
    if (display == DoseStatus.missed) return 'Dose perdida';
    return 'Próxima dose às ${_formatTime(dose.scheduledTime)}';
  }

  IconData _getStatusIconByDisplay(DoseStatus? display) {
    if (display == null) return Icons.schedule;
    switch (display) {
      case DoseStatus.pending:
        return Icons.schedule;
      case DoseStatus.overdue:
        return Icons.warning;
      case DoseStatus.missed:
        return Icons.close;
      case DoseStatus.taken:
        return Icons.check_circle;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  int _weekdayToInt(String weekdayPt) {
    switch (weekdayPt.trim().toLowerCase()) {
      case 'segunda': return 1;
      case 'terça':
      case 'terca': return 2;
      case 'quarta': return 3;
      case 'quinta': return 4;
      case 'sexta': return 5;
      case 'sábado':
      case 'sabado': return 6;
      case 'domingo': return 7;
      default: return 0;
    }
  }

  DateTime? _getNextScheduledDateTime() {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      DateTime? candidate;

      if (medication.times.isEmpty) return null;

      List<int> validDays = [];
      if (medication.frequency == 'weekly' && medication.daysOfWeek.isNotEmpty) {
        validDays = medication.daysOfWeek.map(_weekdayToInt).where((d) => d > 0).toList();
      } else {
        validDays = [1, 2, 3, 4, 5, 6, 7]; // daily
      }

      for (final t in medication.times) {
        final parts = (t.toString()).split(':');
        if (parts.length < 2) continue;
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;

        DateTime scheduled = DateTime(today.year, today.month, today.day, hour, minute);
        
        while (!scheduled.isAfter(now) || !validDays.contains(scheduled.weekday)) {
          scheduled = scheduled.add(const Duration(days: 1));
        }

        if (candidate == null || scheduled.isBefore(candidate)) {
          candidate = scheduled;
        }
      }

      return candidate;
    } catch (_) {
      return null;
    }
  }

  String _getUnitName(String unit) {
    switch (unit) {
      case 'tablet':
      case 'comprimido':
        return 'comprimido(s)';
      case 'capsule':
      case 'capsula':
        return 'cápsula(s)';
      case 'ml':
        return 'ml';
      case 'drops':
      case 'gotas':
        return 'gota(s)';
      case 'sachets':
      case 'saches':
        return 'sachê(s)';
      default:
        return 'unidade(s)';
    }
  }
}
