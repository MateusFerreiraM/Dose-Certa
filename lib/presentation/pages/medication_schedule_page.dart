import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dose_certa/presentation/bloc/medication/medication_bloc.dart';
import 'package:dose_certa/presentation/bloc/medication/medication_event.dart';
import 'package:dose_certa/presentation/bloc/medication/medication_state.dart';
import 'package:dose_certa/domain/entities/medication.dart';
import 'package:dose_certa/core/theme/app_theme.dart';

class MedicationSchedulePage extends StatefulWidget {
  final int medicationId;

  const MedicationSchedulePage({Key? key, required this.medicationId})
      : super(key: key);

  @override
  State<MedicationSchedulePage> createState() => _MedicationSchedulePageState();
}

class _MedicationSchedulePageState extends State<MedicationSchedulePage> {
  Medication? _medication;
  List<TimeOfDay> _scheduledTimes = [];
  String _frequency = 'daily';
  List<String> _selectedDays = [];
  bool _loading = false;

  final List<String> _weekDays = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo'
  ];
  final List<String> _weekDaysCodes = [
    'segunda',
    'terça',
    'quarta',
    'quinta',
    'sexta',
    'sábado',
    'domingo'
  ];

  @override
  void initState() {
    super.initState();
    final bloc = BlocProvider.of<MedicationBloc>(context);
    final state = bloc.state;
    if (state is MedicationLoaded) {
      _loadFromState(state);
    } else {
      bloc.stream.firstWhere((s) => s is MedicationLoaded).then((s) {
        _loadFromState(s as MedicationLoaded);
      }).catchError((_) {});
    }
  }

  void _loadFromState(MedicationLoaded state) {
    final med =
        state.medications.where((m) => m.id == widget.medicationId).toList();
    if (med.isEmpty) return;

    final medication = med.first;

    String normalize(String value) {
      final v = value.trim().toLowerCase();
      switch (v) {
        case 'monday':
        case 'mon':
          return 'segunda';
        case 'tuesday':
        case 'tue':
          return 'terça';
        case 'wednesday':
        case 'wed':
          return 'quarta';
        case 'thursday':
        case 'thu':
          return 'quinta';
        case 'friday':
        case 'fri':
          return 'sexta';
        case 'saturday':
        case 'sat':
          return 'sábado';
        case 'sunday':
        case 'sun':
          return 'domingo';
        default:
          return v;
      }
    }

    final selectedDays = medication.daysOfWeek.map(normalize).toSet().toList();

    final freqFromMed =
        medication.frequency == 'custom' ? 'weekly' : medication.frequency;

    setState(() {
      _medication = medication;
      if (selectedDays.isNotEmpty) {
        _frequency = 'weekly';
      } else {
        _frequency = (freqFromMed == 'daily' || freqFromMed == 'weekly')
            ? freqFromMed
            : 'daily';
      }
      _selectedDays = selectedDays;
      _scheduledTimes = medication.times.map((timeStr) {
        final parts = timeStr.split(':');
        if (parts.length == 2) {
          return TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 9,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
        return const TimeOfDay(hour: 9, minute: 0);
      }).toList();

      if (_scheduledTimes.isEmpty) {
        _scheduledTimes = [const TimeOfDay(hour: 9, minute: 0)];
      }
    });
  }

  Future<void> _addTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time != null) {
      setState(() {
        _scheduledTimes.add(time);
        _scheduledTimes.sort((a, b) {
          final aMinutes = a.hour * 60 + a.minute;
          final bMinutes = b.hour * 60 + b.minute;
          return aMinutes.compareTo(bMinutes);
        });
      });
    }
  }

  void _removeTime(int index) {
    if (_scheduledTimes.length > 1) {
      setState(() {
        _scheduledTimes.removeAt(index);
      });
    }
  }

  Future<void> _editTime(int index) async {
    final time = await showTimePicker(
      context: context,
      initialTime: _scheduledTimes[index],
    );
    if (time != null) {
      setState(() {
        _scheduledTimes[index] = time;
        _scheduledTimes.sort((a, b) {
          final aMinutes = a.hour * 60 + a.minute;
          final bMinutes = b.hour * 60 + b.minute;
          return aMinutes.compareTo(bMinutes);
        });
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _save() async {
    if (_medication == null) return;
    setState(() => _loading = true);

    final times = _scheduledTimes.map(_formatTime).toList();
    final days = _frequency == 'daily' ? <String>[] : _selectedDays;

    final updated = _medication!.copyWith(
      frequency: _frequency,
      times: times,
      daysOfWeek: days,
    );

    try {
      context.read<MedicationBloc>().add(UpdateMedication(updated));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cronograma atualizado')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cronograma de Medicação'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _medication == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _medication!.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_medication!.dosageAmount} ${_medication!.unit}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  const Text('Frequência',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _frequency,
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(
                          value: 'daily', child: Text('Todos os dias')),
                      DropdownMenuItem(
                          value: 'weekly',
                          child: Text('Dias específicos da semana')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _frequency = value!;
                        if (_frequency == 'daily') _selectedDays.clear();
                      });
                    },
                  ),
                  if (_frequency == 'weekly') ...[
                    const SizedBox(height: 16),
                    const Text('Dias da semana',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: List.generate(_weekDays.length, (index) {
                        final day = _weekDaysCodes[index];
                        final isSelected = _selectedDays.contains(day);
                        return FilterChip(
                          label: Text(_weekDays[index]),
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
                          selectedColor:
                              AppColors.primaryBrown.withOpacity(0.3),
                        );
                      }),
                    ),
                  ],
                  if (_frequency != 'as_needed') ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Horários',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        ElevatedButton.icon(
                          onPressed: _addTime,
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _scheduledTimes.length,
                        itemBuilder: (context, index) {
                          final time = _scheduledTimes[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.schedule),
                              title: Text(
                                _formatTime(time),
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editTime(index),
                                  ),
                                  if (_scheduledTimes.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => _removeTime(index),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
