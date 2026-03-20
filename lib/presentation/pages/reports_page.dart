import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dose_certa/presentation/bloc/medication/medication_bloc.dart';
import 'package:dose_certa/presentation/bloc/medication/medication_state.dart';
import 'package:dose_certa/presentation/bloc/medication/medication_event.dart';
import 'package:dose_certa/domain/entities/medication.dart';
import 'package:dose_certa/domain/entities/medication_dose.dart';
import 'package:dose_certa/domain/usecases/dose_usecases.dart';
import 'package:dose_certa/core/di/injection_container.dart' as di;
import 'package:dose_certa/core/theme/app_theme.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  @override
  void initState() {
    super.initState();
    context.read<MedicationBloc>().add(LoadMedications());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Relatórios',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryBrown,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocBuilder<MedicationBloc, MedicationState>(
        builder: (context, state) {
          if (state is MedicationInitial || state is MedicationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MedicationError) {
            return Center(
              child: Text(
                'Erro: ${state.message}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (state is MedicationLoaded) {
            return _buildReportsContent(context, state.medications);
          }

          return const Center(child: Text('Estado inesperado'));
        },
      ),
    );
  }

  Widget _buildReportsContent(
      BuildContext context, List<Medication> medications) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(medications),
          const SizedBox(height: 20),
          _buildAdherenceReport(medications),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(List<Medication> medications) {
    final activeMeds = medications.where((m) => m.isActive).length;
    final totalReminders =
        medications.fold<int>(0, (sum, med) => sum + med.times.length);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Medicamentos',
            '$activeMeds',
            Icons.medication,
            AppColors.primaryBrown,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Horários/dia',
            '$totalReminders',
            Icons.access_time,
            AppColors.primaryBrownLight,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAdherenceReport(List<Medication> medications) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Controle de Aderência',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBrown,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Seus medicamentos ativos:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...medications
            .where((m) => m.isActive)
            .map((medication) => _buildMedicationAdherenceCard(medication))
            .toList(),
        if (medications.where((m) => m.isActive).isEmpty) ...[
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.medication_outlined,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhum medicamento ativo',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Adicione medicamentos para começar o controle',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMedicationAdherenceCard(Medication medication) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showMedicationCalendar(medication),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${medication.formattedDosage} - ${medication.times.length} horários/dia',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Ativo',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Últimos 7 dias:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<_AdherenceWindow>(
                future: _computeAdherenceWindow(medication, days: 7),
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  final taken = data?.taken ?? 0;
                  final total = data?.total ?? 0;
                  final percent = total == 0 ? null : (taken / total * 100);

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBrownLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.insights,
                          size: 18,
                          color: AppColors.primaryBrownLight,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            total == 0
                                ? 'Sem registros suficientes (toque para ver o calendário)'
                                : 'Aderência: $taken/$total (${percent!.toStringAsFixed(0)}%) — toque para ver o calendário',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryBrownLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<_AdherenceWindow> _computeAdherenceWindow(Medication medication,
      {required int days}) async {
    final doseUseCases = di.getIt<DoseUseCases>();
    final now = DateTime.now();
    final endExclusive =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final startInclusive = endExclusive.subtract(Duration(days: days));

    final id = medication.id ?? 0;
    if (id == 0) return const _AdherenceWindow(taken: 0, total: 0);

    final doses = await doseUseCases.getDosesForMedicationInRange(
        id, startInclusive, endExclusive);
    final scheduledInWindow = doses.where((d) {
      final st = d.scheduledTime;
      return !st.isBefore(startInclusive) && st.isBefore(endExclusive);
    }).toList();

    final total = scheduledInWindow.length;
    final taken = scheduledInWindow.where((d) => d.isTaken).length;
    return _AdherenceWindow(taken: taken, total: total);
  }

  Future<void> _showMedicationCalendar(Medication medication) async {
    final doseFuture = () async {
      final doseUseCases = di.getIt<DoseUseCases>();
      final today = DateTime.now();
      final created = DateTime(medication.createdAt.year,
          medication.createdAt.month, medication.createdAt.day);
      int totalDays = today.difference(created).inDays + 1;
      const int maxDays = 365;
      if (totalDays > maxDays) {
        totalDays = maxDays;
      }

      final endExclusive = DateTime(today.year, today.month, today.day)
          .add(const Duration(days: 1));
      final startInclusive = totalDays == maxDays
          ? endExclusive.subtract(const Duration(days: maxDays))
          : created;

      final all = await doseUseCases.getDosesForMedicationInRange(
          medication.id ?? 0, startInclusive, endExclusive);
      final Map<DateTime, List<MedicationDose>> dosesByDate = {};
      final rangeDays = endExclusive.difference(startInclusive).inDays;
      for (int i = 0; i < rangeDays; i++) {
        final d = startInclusive.add(Duration(days: i));
        dosesByDate[DateTime(d.year, d.month, d.day)] = [];
      }

      for (final dose in all) {
        final st = dose.scheduledTime;
        final key = DateTime(st.year, st.month, st.day);
        dosesByDate.putIfAbsent(key, () => []);
        dosesByDate[key]!.add(dose);
      }
      for (final entry in dosesByDate.entries) {
        entry.value.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
      }

      return dosesByDate;
    }();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          backgroundColor: AppColors.cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.92,
            height: MediaQuery.of(context).size.height * 0.78,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FutureBuilder<Map<DateTime, List<MedicationDose>>>(
                  future: doseFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final dosesByDate = snapshot.data ?? {};
                    final bool empty = dosesByDate.isEmpty;
                    final displayMap = <DateTime, List<MedicationDose>>{};
                    if (empty) {
                      final today = DateTime.now();
                      for (int i = 6; i >= 0; i--) {
                        final d = DateTime(today.year, today.month, today.day)
                            .subtract(Duration(days: i));
                        displayMap[d] = [];
                      }
                    } else {
                      displayMap.addAll(dosesByDate);
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Calendário - ${medication.name}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(color: AppColors.textPrimary),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Histórico de aderência desde ${_formatDate(medication.createdAt)}',
                          style: TextStyle(
                              fontSize: 14, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _legendItem(
                                AppColors.successColor, Icons.check, 'Tomado'),
                            const SizedBox(width: 8),
                            _legendItem(AppColors.errorColor, Icons.close,
                                'Não registrado'),
                            const SizedBox(width: 8),
                            _legendItem(AppColors.pendingBlue,
                                Icons.access_time, 'Pendente'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child:
                              _buildCompactCalendarView(medication, displayMap),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactCalendarView(
      Medication medication, Map<DateTime, List<MedicationDose>> dosesByDate) {
    final today = DateTime.now();
    final dateList = dosesByDate.isNotEmpty
        ? (dosesByDate.keys.toList()..sort())
        : List.generate(
            7,
            (i) => DateTime(today.year, today.month, today.day)
                .subtract(Duration(days: 6 - i)));

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: dateList.length,
      itemBuilder: (context, index) {
        final date = dateList[index];
        final normalized = DateTime(date.year, date.month, date.day);
        final isToday = normalized.year == today.year &&
            normalized.month == today.month &&
            normalized.day == today.day;

        final doses = dosesByDate[normalized] ?? [];
        final total = doses.length;
        final takenCount = doses.where((d) => d.isTaken).length;
        final pendingCount = doses
            .where((d) => d.isOverdue)
            .length; // Pendente = passou da hora, ainda pode tomar
        final missedCount = doses
            .where((d) => d.isMissed)
            .length; // Não registrado = perdeu a janela

        Color bgColor;
        String centerText;

        if (total == 0) {
          bgColor = AppColors.textSecondary.withOpacity(0.6);
          centerText = '${date.day}';
        } else if (takenCount == total) {
          bgColor = AppColors.successColor.withOpacity(0.95);
          centerText = '$takenCount/$total';
        } else if (takenCount > 0) {
          bgColor = AppColors.primaryBrownLight.withOpacity(0.95);
          centerText = '$takenCount/$total';
        } else if (pendingCount > 0) {
          bgColor = AppColors.pendingBlue
              .withOpacity(0.95); // Azul para "Pendente" (pode tomar)
          centerText = '0/$total';
        } else if (missedCount > 0) {
          bgColor = AppColors.errorColor
              .withOpacity(0.95); // Vermelho para "Não registrado" (perdeu)
          centerText = '0/$total';
        } else {
          bgColor = AppColors.errorColor.withOpacity(0.95);
          centerText = '0/$total';
        }

        final borderStyle = isToday
            ? Border.all(color: AppColors.primaryBrown, width: 2)
            : null;

        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            border: borderStyle,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  centerText,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _legendItem(Color color, IconData icon, String label) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 12),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

class _AdherenceWindow {
  final int taken;
  final int total;

  const _AdherenceWindow({required this.taken, required this.total});
}
