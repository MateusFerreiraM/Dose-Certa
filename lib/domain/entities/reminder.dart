import 'package:equatable/equatable.dart';

enum ReminderStatus {
  pending,
  taken,
  missed,
  skipped,
}

class Reminder extends Equatable {
  final int? id;
  final int medicationId;
  final String medicationName;
  final String dosageUnit;
  final DateTime scheduledTime;
  final DateTime? takenTime;
  final ReminderStatus status;
  final double dosageAmount;
  final String? notes;
  final DateTime createdAt;

  const Reminder({
    this.id,
    required this.medicationId,
    required this.medicationName,
    required this.dosageUnit,
    required this.scheduledTime,
    this.takenTime,
    this.status = ReminderStatus.pending,
    required this.dosageAmount,
    this.notes,
    required this.createdAt,
  });

  Reminder copyWith({
    int? id,
    int? medicationId,
    String? medicationName,
    String? dosageUnit,
    DateTime? scheduledTime,
    DateTime? takenTime,
    ReminderStatus? status,
    double? dosageAmount,
    String? notes,
    DateTime? createdAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      dosageUnit: dosageUnit ?? this.dosageUnit,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      takenTime: takenTime ?? this.takenTime,
      status: status ?? this.status,
      dosageAmount: dosageAmount ?? this.dosageAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isPending => status == ReminderStatus.pending;
  bool get isTaken => status == ReminderStatus.taken;
  bool get isMissed => status == ReminderStatus.missed;
  bool get isOverdue => DateTime.now().isAfter(scheduledTime) && isPending;

  String get statusText {
    switch (status) {
      case ReminderStatus.pending:
        return isOverdue ? 'Atrasado' : 'Pendente';
      case ReminderStatus.taken:
        return 'Confirmado';
      case ReminderStatus.missed:
        return 'Perdido';
      case ReminderStatus.skipped:
        return 'Pulado';
    }
  }

  String get dosageText => '$dosageAmount $dosageUnit';

  Duration get timeDifference => scheduledTime.difference(DateTime.now());

  String get timeUntilText {
    final diff = timeDifference;
    if (diff.isNegative) {
      final absDiff = diff.abs();
      if (absDiff.inDays > 0) return '${absDiff.inDays} dia(s) atrás';
      if (absDiff.inHours > 0) return '${absDiff.inHours} hora(s) atrás';
      if (absDiff.inMinutes > 0) return '${absDiff.inMinutes} min atrás';
      return 'Agora';
    } else {
      if (diff.inDays > 0) return 'Em ${diff.inDays} dia(s)';
      if (diff.inHours > 0) return 'Em ${diff.inHours} hora(s)';
      if (diff.inMinutes > 0) return 'Em ${diff.inMinutes} min';
      return 'Agora';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medication_id': medicationId,
      'scheduled_time': scheduledTime.millisecondsSinceEpoch,
      'taken_time': takenTime?.millisecondsSinceEpoch,
      'status': status.name,
      'dosage_amount': dosageAmount,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    dynamic _toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) {
        final asInt = int.tryParse(v);
        if (asInt != null) return asInt;
        final dt = DateTime.tryParse(v);
        if (dt != null) return dt.millisecondsSinceEpoch;
      }
      return null;
    }

    DateTime _toDate(dynamic v) {
      final i = _toInt(v);
      if (i != null) return DateTime.fromMillisecondsSinceEpoch(i);
      return DateTime.now();
    }

    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return Reminder(
      id: _toInt(map['id']),
      medicationId: _toInt(map['medication_id']) ?? 0,
      medicationName: map['medication_name'] ?? '',
      dosageUnit: map['dosage_unit'] ?? '',
      scheduledTime: _toDate(map['scheduled_time']),
      takenTime: map['taken_time'] != null ? _toDate(map['taken_time']) : null,
      status: ReminderStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? ''),
        orElse: () => ReminderStatus.pending,
      ),
      dosageAmount: _toDouble(map['dosage_amount']),
      notes: map['notes'],
      createdAt: _toDate(map['created_at']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        medicationId,
        medicationName,
        dosageUnit,
        scheduledTime,
        takenTime,
        status,
        dosageAmount,
        notes,
        createdAt,
      ];
}
