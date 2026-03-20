import 'package:equatable/equatable.dart';

class Medication extends Equatable {
  final int? id;
  final String name;
  final String dosage;
  final double dosageAmount;
  final String unit;
  final String frequency;
  final List<String> daysOfWeek;
  final List<String> times;
  final DateTime startDate;
  final DateTime? endDate;
  final int? durationDays;
  final int stockQuantity;
  final int stockAlertThreshold;
  final bool stockAlertsEnabled;
  final bool isActive;
  final bool isPaused;
  final String description;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<MedicationSchedule>? schedules;

  const Medication({
    this.id,
    required this.name,
    this.dosage = '',
    required this.dosageAmount,
    required this.unit,
    required this.frequency,
    this.daysOfWeek = const [],
    this.times = const [],
    required this.startDate,
    this.endDate,
    this.durationDays,
    this.stockQuantity = 0,
    this.stockAlertThreshold = 10,
    this.stockAlertsEnabled = true,
    this.isActive = true,
    this.isPaused = false,
    this.description = '',
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.schedules,
  });
  bool get needsStockAlert =>
      stockAlertsEnabled && stockQuantity <= stockAlertThreshold;

  String get formattedDosage {
    final dosageText = dosageAmount == dosageAmount.toInt()
        ? dosageAmount.toInt().toString()
        : dosageAmount.toString();
    return '$dosageText${_getUnitAbbreviation()}';
  }

  String _getUnitAbbreviation() {
    switch (unit) {
      case 'tablet':
        return ' comp';
      case 'capsule':
        return ' cáps';
      case 'ml':
        return ' ml';
      case 'drops':
        return ' gotas';
      case 'sachets':
        return ' sachê';
      default:
        return '';
    }
  }

  Medication copyWith({
    int? id,
    String? name,
    String? dosage,
    double? dosageAmount,
    String? unit,
    String? frequency,
    List<String>? daysOfWeek,
    List<String>? times,
    DateTime? startDate,
    DateTime? endDate,
    int? durationDays,
    int? stockQuantity,
    int? stockAlertThreshold,
    bool? stockAlertsEnabled,
    bool? isActive,
    bool? isPaused,
    String? description,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<MedicationSchedule>? schedules,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      dosageAmount: dosageAmount ?? this.dosageAmount,
      unit: unit ?? this.unit,
      frequency: frequency ?? this.frequency,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      times: times ?? this.times,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      durationDays: durationDays ?? this.durationDays,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      stockAlertThreshold: stockAlertThreshold ?? this.stockAlertThreshold,
      stockAlertsEnabled: stockAlertsEnabled ?? this.stockAlertsEnabled,
      isActive: isActive ?? this.isActive,
      isPaused: isPaused ?? this.isPaused,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      schedules: schedules ?? this.schedules,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'dosage_amount': dosageAmount,
      'unit': unit,
      'frequency': frequency,
      'days_of_week': daysOfWeek.join(','),
      'times': times.join(','),
      'start_date': startDate.millisecondsSinceEpoch,
      'end_date': endDate?.millisecondsSinceEpoch,
      'duration_days': durationDays,
      'stock_quantity': stockQuantity,
      'stock_alert_threshold': stockAlertThreshold,
      'stock_alerts_enabled': stockAlertsEnabled ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'is_paused': isPaused ? 1 : 0,
      'description': description,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    int? _toInt(dynamic v) {
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

    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    DateTime _toDateTime(dynamic v, {DateTime? fallback}) {
      if (v == null) return fallback ?? DateTime.now();
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is double) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
      if (v is String) {
        final asInt = int.tryParse(v);
        if (asInt != null) return DateTime.fromMillisecondsSinceEpoch(asInt);
        final dt = DateTime.tryParse(v);
        if (dt != null) return dt;
      }
      return fallback ?? DateTime.now();
    }

    return Medication(
      id: _toInt(map['id']),
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      dosageAmount: _toDouble(map['dosage_amount']) ?? 0.0,
      unit: map['unit'] ?? 'tablet',
      frequency: map['frequency'] ?? '',
      daysOfWeek: map['days_of_week'] != null
          ? (map['days_of_week'] as String)
              .split(',')
              .where((s) => s.isNotEmpty)
              .toList()
          : [],
      times: map['times'] != null
          ? (map['times'] as String)
              .split(',')
              .where((s) => s.isNotEmpty)
              .toList()
          : [],
      startDate: _toDateTime(map['start_date'], fallback: DateTime.now()),
      endDate: map['end_date'] != null ? _toDateTime(map['end_date']) : null,
      durationDays: _toInt(map['duration_days']),
      stockQuantity: _toInt(map['stock_quantity']) ?? 0,
      stockAlertThreshold: _toInt(map['stock_alert_threshold']) ?? 10,
      stockAlertsEnabled: (_toInt(map['stock_alerts_enabled']) ?? 1) == 1,
      isActive: (_toInt(map['is_active']) ?? 1) == 1,
      isPaused: (_toInt(map['is_paused']) ?? 0) == 1,
      description: map['description'] ?? '',
      notes: map['notes'],
      createdAt: _toDateTime(map['created_at'], fallback: DateTime.now()),
      updatedAt:
          map['updated_at'] != null ? _toDateTime(map['updated_at']) : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        dosage,
        dosageAmount,
        unit,
        frequency,
        daysOfWeek,
        times,
        startDate,
        endDate,
        durationDays,
        stockQuantity,
        stockAlertThreshold,
        stockAlertsEnabled,
        isActive,
        isPaused,
        description,
        notes,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'Medication(id: $id, name: $name, dosage: $dosage, isActive: $isActive, isPaused: $isPaused)';
  }
}

class MedicationSchedule extends Equatable {
  final int? id;
  final int? medicationId;
  final String time;
  final List<int> daysOfWeek;
  final bool isActive;
  final DateTime createdAt;

  const MedicationSchedule({
    this.id,
    this.medicationId,
    required this.time,
    required this.daysOfWeek,
    this.isActive = true,
    required this.createdAt,
  });

  MedicationSchedule copyWith({
    int? id,
    int? medicationId,
    String? time,
    List<int>? daysOfWeek,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return MedicationSchedule(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      time: time ?? this.time,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medication_id': medicationId,
      'time': time,
      'days_of_week': daysOfWeek.join(','),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory MedicationSchedule.fromMap(Map<String, dynamic> map) {
    int? _toInt(dynamic v) {
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

    return MedicationSchedule(
      id: _toInt(map['id']),
      medicationId: _toInt(map['medication_id']),
      time: map['time'] ?? '',
      daysOfWeek: map['days_of_week'] != null
          ? (map['days_of_week'] as String)
              .split(',')
              .map((e) => int.tryParse(e) ?? 0)
              .toList()
          : [],
      isActive: (_toInt(map['is_active']) ?? 1) == 1,
      createdAt: _toDate(map['created_at']),
    );
  }

  @override
  List<Object?> get props =>
      [id, medicationId, time, daysOfWeek, isActive, createdAt];

  @override
  String toString() {
    return 'MedicationSchedule(id: $id, medicationId: $medicationId, time: $time, daysOfWeek: $daysOfWeek)';
  }
}
