import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dose_certa/core/theme/app_theme.dart';
import 'package:dose_certa/domain/entities/medication.dart';
import 'package:dose_certa/presentation/bloc/medication/medication_bloc.dart';
import 'package:dose_certa/presentation/bloc/medication/medication_event.dart';
import 'package:dose_certa/presentation/bloc/medication/medication_state.dart';

class AddReminderPage extends StatefulWidget {
  final int? medicationId;

  const AddReminderPage({super.key, this.medicationId});

  @override
  State<AddReminderPage> createState() => _AddReminderPageState();
}

class _AddReminderPageState extends State<AddReminderPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageAmountController = TextEditingController();
  final _stockController = TextEditingController();
  final _alertController = TextEditingController();
  final _notesController = TextEditingController();

  String _dosageUnit = 'tablet';
  String _frequency = 'daily';
  List<String> _selectedDays = [];
  List<MedicationSchedule> _schedules = [];
  bool _stockAlertsEnabled = true;

  final List<String> _dosageUnits = [
    'tablet',
    'capsule',
    'ml',
    'drops',
    'sachets',
  ];

  final Map<String, String> _unitLabels = {
    'tablet': 'comprimido(s)',
    'capsule': 'cápsula(s)',
    'ml': 'ml',
    'drops': 'gota(s)',
    'sachets': 'sachê(s)',
  };

  final List<String> _frequencies = [
    'daily',
    'weekly',
  ];

  final Map<String, String> _frequencyLabels = {
    'daily': 'Todos os dias',
    'weekly': 'Dias específicos',
  };

  final List<String> _weekDays = [
    'segunda',
    'terça',
    'quarta',
    'quinta',
    'sexta',
    'sábado',
    'domingo',
  ];

  @override
  void initState() {
    super.initState();
    _editingMedication = null;
    if (widget.medicationId != null) {
      final bloc = BlocProvider.of<MedicationBloc>(context);
      final state = bloc.state;
      if (state is MedicationLoaded) {
        try {
          final med =
              state.medications.firstWhere((m) => m.id == widget.medicationId);
          _prefillFromMedication(med);
        } catch (_) {
          _setDefaultValues();
        }
      } else {
        bloc.stream.firstWhere((s) => s is MedicationLoaded).then((s) {
          final meds = (s as MedicationLoaded)
              .medications
              .where((m) => m.id == widget.medicationId)
              .toList();
          if (meds.isNotEmpty) {
            _prefillFromMedication(meds.first);
          } else {
            _setDefaultValues();
          }
        }).catchError((_) {
          _setDefaultValues();
        });
      }
    } else {
      _setDefaultValues();
    }
  }

  Medication? _editingMedication;

  void _prefillFromMedication(Medication med) {
    _editingMedication = med;
    _nameController.text = med.name;
    _dosageAmountController.text = med.dosageAmount.toString();
    _dosageUnit = med.unit;
    _selectedDays = List<String>.from(med.daysOfWeek);
    final freq = (med.frequency == 'custom') ? 'weekly' : med.frequency;
    if (_selectedDays.isNotEmpty && _selectedDays.length < 7) {
      _frequency = 'weekly';
    } else {
      _frequency = (freq == 'daily' || freq == 'weekly') ? freq : 'daily';
    }

    _schedules = med.schedules ?? _schedules;
    _stockController.text = med.stockQuantity.toString();
    _alertController.text = med.stockAlertThreshold.toString();
    _stockAlertsEnabled = med.stockAlertsEnabled;
    _notesController.text = med.notes ?? '';
    setState(() {});
  }

  void _setDefaultValues() {
    _dosageAmountController.text = '1';
    _stockController.text = '30';
    _alertController.text = '10';
    _schedules.add(MedicationSchedule(
      medicationId: 0,
      time: '08:00',
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7], // Todos os dias
      createdAt: DateTime.now(),
    ));
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageAmountController.dispose();
    _stockController.dispose();
    _alertController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Adicionar Medicamento'),
        backgroundColor: AppColors.primaryBrown,
        foregroundColor: Colors.white,
      ),
      body: BlocListener<MedicationBloc, MedicationState>(
        listener: (context, state) {
          if (state is MedicationOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.successColor,
              ),
            );
            Navigator.of(context).pop();
          } else if (state is MedicationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.errorColor,
              ),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfoSection(),
                const SizedBox(height: 24),
                _buildDosageSection(),
                const SizedBox(height: 24),
                _buildScheduleSection(),
                const SizedBox(height: 24),
                _buildStockSection(),
                const SizedBox(height: 32),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações Básicas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primaryBrown,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do medicamento',
                hintText: 'Ex: Paracetamol',
                prefixIcon: Icon(Icons.medication),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor, informe o nome do medicamento';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
                hintText: 'Ex: Tomar após as refeições',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDosageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dosagem',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primaryBrown,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _dosageAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Quantidade',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe a quantidade';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Quantidade inválida';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _dosageUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unidade',
                      prefixIcon: Icon(Icons.label),
                    ),
                    items: _dosageUnits.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(_unitLabels[unit]!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _dosageUnit = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Horários',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primaryBrown,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _frequency,
              decoration: const InputDecoration(
                labelText: 'Frequência',
                prefixIcon: Icon(Icons.schedule),
              ),
              items: _frequencies.map((freq) {
                return DropdownMenuItem(
                  value: freq,
                  child: Text(_frequencyLabels[freq]!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _frequency = value!;
                });
              },
            ),
            if (_frequency == 'weekly') ...[
              const SizedBox(height: 16),
              Text(
                'Dias da semana:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _weekDays.map((day) {
                  final isSelected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(day.substring(0, 3).toUpperCase()),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(day);
                        } else {
                          _selectedDays.remove(day);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Horários do dia:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ..._schedules.asMap().entries.map((entry) {
              final index = entry.key;
              final schedule = entry.value;
              return _buildScheduleItem(index, schedule);
            }).toList(),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _addSchedule,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar horário'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleItem(int index, MedicationSchedule schedule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectTime(index),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Horário',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(schedule.time),
                ),
              ),
            ),
            const SizedBox(width: 16),
            if (_schedules.length > 1)
              IconButton(
                onPressed: () => _removeSchedule(index),
                icon: const Icon(Icons.delete, color: AppColors.errorColor),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Controle de Estoque',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primaryBrown,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stockController,
              decoration: const InputDecoration(
                labelText: 'Quantidade atual',
                hintText: '30',
                prefixIcon: Icon(Icons.inventory),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe a quantidade';
                }
                if (int.tryParse(value) == null) {
                  return 'Quantidade inválida';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Alertas de estoque baixo'),
              subtitle: const Text(
                  'Receba notificações quando o estoque estiver baixo'),
              value: _stockAlertsEnabled,
              onChanged: (value) {
                setState(() {
                  _stockAlertsEnabled = value;
                });
              },
              activeColor: AppColors.primaryBrown,
            ),
            if (_stockAlertsEnabled) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _alertController,
                decoration: InputDecoration(
                  labelText: 'Alertar quando restarem',
                  hintText: '10',
                  suffixText: _dosageUnit,
                  prefixIcon: const Icon(Icons.warning),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_stockAlertsEnabled &&
                      (value == null || value.trim().isEmpty)) {
                    return 'Informe quando alertar';
                  }
                  if (value != null &&
                      value.isNotEmpty &&
                      int.tryParse(value) == null) {
                    return 'Quantidade inválida';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: BlocBuilder<MedicationBloc, MedicationState>(
        builder: (context, state) {
          return ElevatedButton(
            onPressed: state is MedicationLoading ? null : _saveMedication,
            child: state is MedicationLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Salvar Medicamento'),
          );
        },
      ),
    );
  }

  void _addSchedule() {
    setState(() {
      _schedules.add(MedicationSchedule(
        medicationId: 0,
        time: '12:00',
        daysOfWeek: [1, 2, 3, 4, 5, 6, 7], // Todos os dias
        createdAt: DateTime.now(),
      ));
    });
  }

  void _removeSchedule(int index) {
    setState(() {
      _schedules.removeAt(index);
    });
  }

  Future<void> _selectTime(int index) async {
    final schedule = _schedules[index];
    final timeParts = schedule.time.split(':');
    final currentTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (selectedTime != null) {
      final timeString = '${selectedTime.hour.toString().padLeft(2, '0')}:'
          '${selectedTime.minute.toString().padLeft(2, '0')}';

      setState(() {
        _schedules[index] = schedule.copyWith(time: timeString);
      });
    }
  }

  void _saveMedication() {
    if (!_formKey.currentState!.validate()) return;

    if (_frequency == 'weekly' && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um dia da semana'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    final existing = _editingMedication;

    int _weekdayToInt(String weekdayPt) {
      switch (weekdayPt.trim().toLowerCase()) {
        case 'segunda':
          return 1;
        case 'terça':
        case 'terca':
          return 2;
        case 'quarta':
          return 3;
        case 'quinta':
          return 4;
        case 'sexta':
          return 5;
        case 'sábado':
        case 'sabado':
          return 6;
        case 'domingo':
          return 7;
        default:
          return 0;
      }
    }

    final List<int> scheduleDays;
    if (_frequency == 'weekly') {
      final days =
          _selectedDays.map(_weekdayToInt).where((d) => d > 0).toSet().toList();
      days.sort();
      scheduleDays = days;
    } else {
      scheduleDays = <int>[1, 2, 3, 4, 5, 6, 7];
    }
    final normalizedSchedules = <MedicationSchedule>[];
    final seenTimes = <String>{};
    for (final s in _schedules) {
      final t = s.time.trim();
      if (t.isEmpty) continue;
      if (seenTimes.contains(t)) continue;
      seenTimes.add(t);
      normalizedSchedules.add(s.copyWith(daysOfWeek: scheduleDays, time: t));
    }
    normalizedSchedules.sort((a, b) => a.time.compareTo(b.time));

    final medication = Medication(
      id: existing?.id,
      name: _nameController.text.trim(),
      dosageAmount:
          double.tryParse(_dosageAmountController.text.replaceAll(',', '.')) ??
              1.0,
      unit: _dosageUnit,
      frequency: _frequency,
      daysOfWeek: _frequency == 'weekly' ? _selectedDays : [],
      times: normalizedSchedules.map((s) => s.time).toList(),
      startDate: existing?.startDate ?? DateTime.now(),
      stockQuantity: int.tryParse(_stockController.text) ?? 0,
      stockAlertThreshold: int.tryParse(_alertController.text) ?? 10,
      stockAlertsEnabled: _stockAlertsEnabled,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      schedules: normalizedSchedules,
    );

    if (existing != null) {
      context.read<MedicationBloc>().add(UpdateMedication(medication));
    } else {
      context.read<MedicationBloc>().add(AddMedication(medication));
    }
  }
}
