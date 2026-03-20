import 'package:equatable/equatable.dart';

enum DoseStatus {
  pending, // Ainda não chegou a hora
  overdue, // Passou da hora e não foi tomado (janela de tolerância)
  missed, // Passou da janela de tolerância e não foi tomado
  taken, // Foi marcado como tomado
}

class MedicationDose extends Equatable {
  final int? id;
  final int medicationId;
  final DateTime scheduledTime; // Data e hora exata da dose
  final DoseStatus status;
  final DateTime? takenAt; // Quando foi marcado como tomado
  final DateTime createdAt;
  final DateTime? updatedAt;

  const MedicationDose({
    this.id,
    required this.medicationId,
    required this.scheduledTime,
    this.status = DoseStatus.pending,
    this.takenAt,
    required this.createdAt,
    this.updatedAt,
  });

  MedicationDose copyWith({
    int? id,
    int? medicationId,
    DateTime? scheduledTime,
    DoseStatus? status,
    DateTime? takenAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicationDose(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      takenAt: takenAt ?? this.takenAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isPending => status == DoseStatus.pending;
  bool get isOverdue => status == DoseStatus.overdue;
  bool get isMissed => status == DoseStatus.missed;
  bool get isTaken => status == DoseStatus.taken;

  String get statusText {
    switch (status) {
      case DoseStatus.pending:
        return 'Próxima dose às ${_formatTime(scheduledTime)}';
      case DoseStatus.overdue:
        return 'Atrasado';
      case DoseStatus.missed:
        return 'Dose perdida';
      case DoseStatus.taken:
        return 'Tomado às ${_formatTime(takenAt ?? scheduledTime)}';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        id,
        medicationId,
        scheduledTime,
        status,
        takenAt,
        createdAt,
        updatedAt,
      ];
}
