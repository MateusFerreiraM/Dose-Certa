import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dose_certa/presentation/bloc/medication/medication_bloc.dart';
import 'package:dose_certa/presentation/bloc/medication/medication_event.dart';
import 'package:dose_certa/presentation/bloc/medication/medication_state.dart';
import 'package:dose_certa/domain/entities/medication.dart';
import 'package:dose_certa/core/routes/app_router.dart';
import 'package:dose_certa/core/theme/app_theme.dart';

class MedicationDetailsPage extends StatefulWidget {
  final int medicationId;

  const MedicationDetailsPage({Key? key, required this.medicationId})
      : super(key: key);

  @override
  State<MedicationDetailsPage> createState() => _MedicationDetailsPageState();
}

class _MedicationDetailsPageState extends State<MedicationDetailsPage> {
  @override
  void initState() {
    super.initState();
    context.read<MedicationBloc>().add(LoadMedications());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBrown,
        foregroundColor: Colors.white,
        title: const Text('Detalhes do Medicamento'),
      ),
      body: BlocBuilder<MedicationBloc, MedicationState>(
        builder: (context, state) {
          if (state is MedicationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MedicationError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: AppColors.errorColor),
                  const SizedBox(height: 16),
                  Text('Erro ao carregar dados',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<MedicationBloc>().add(LoadMedications()),
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          if (state is MedicationLoaded) {
            final medication = state.medications.firstWhere(
              (med) => med.id == widget.medicationId,
              orElse: () => throw Exception('Medicamento não encontrado'),
            );

            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeaderCard(context, medication),
                  const SizedBox(height: 16),
                  _buildScheduleCard(context, medication),
                  const SizedBox(height: 16),
                  _buildStockCard(context, medication),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }

          return const Center(child: Text('Medicamento não encontrado'));
        },
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, Medication medication) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBrown,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.medication,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.successColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Ativo',
                          style: TextStyle(
                            color: AppColors.successColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              context,
              icon: Icons.medical_services,
              title: 'Dosagem',
              value: medication.formattedDosage,
              onEdit: () => _showEditDosageDialog(medication),
            ),
            if (medication.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                context,
                icon: Icons.description,
                title: 'Descrição',
                value: medication.description,
                isDescription: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(BuildContext context, Medication medication) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Horários e Frequência',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRouter.addReminder,
                      arguments: {'medicationId': widget.medicationId},
                    );
                  },
                  icon: const Icon(Icons.edit,
                      color: AppColors.primaryBrown, size: 20),
                  tooltip: 'Editar cronograma',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: Icons.access_time,
              title: 'Horários',
              value: medication.times.join(' • '),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              icon: Icons.calendar_today,
              title: 'Dias da Semana',
              value: _formatDaysOfWeek(medication.daysOfWeek),
            ),
            if (medication.durationDays != null) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                context,
                icon: Icons.event,
                title: 'Duração',
                value: '${medication.durationDays} dias',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStockCard(BuildContext context, Medication medication) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Controle de Estoque',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (medication.needsStockAlert) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warningColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.warningColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning,
                                color: AppColors.warningColor, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Estoque Baixo',
                              style: TextStyle(
                                color: AppColors.warningColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          AppRouter.stockManagement,
                          arguments: {'medicationId': widget.medicationId},
                        );
                      },
                      icon: const Icon(Icons.edit,
                          color: AppColors.primaryBrown, size: 20),
                      tooltip: 'Gerenciar estoque',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBrown.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    color: AppColors.primaryBrown,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantidade Disponível',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${medication.stockQuantity} ${_getUnitName(medication.unit)}',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (medication.stockAlertThreshold > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryBrownLight.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.primaryBrownLight.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppColors.primaryBrown, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Alerta configurado para ${medication.stockAlertThreshold} ${_getUnitName(medication.unit)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onEdit,
    bool isDescription = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryBrown.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryBrown,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight:
                          isDescription ? FontWeight.normal : FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        if (onEdit != null)
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 16),
            color: AppColors.primaryBrown,
            tooltip: 'Editar $title',
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }

  String _formatDaysOfWeek(List<String> days) {
    if (days.isEmpty) {
      return 'Todos os dias';
    }

    final dayNames = days
        .map((day) {
          switch (day.toLowerCase()) {
            case 'monday':
            case 'segunda':
              return 'Segunda';
            case 'tuesday':
            case 'terça':
              return 'Terça';
            case 'wednesday':
            case 'quarta':
              return 'Quarta';
            case 'thursday':
            case 'quinta':
              return 'Quinta';
            case 'friday':
            case 'sexta':
              return 'Sexta';
            case 'saturday':
            case 'sábado':
              return 'Sábado';
            case 'sunday':
            case 'domingo':
              return 'Domingo';
            default:
              return '';
          }
        })
        .where((name) => name.isNotEmpty)
        .join(', ');

    return dayNames.isEmpty ? 'Todos os dias' : dayNames;
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

  void _showEditDosageDialog(Medication medication) {
    final controller =
        TextEditingController(text: medication.dosageAmount.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Dosagem'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Medicamento: ${medication.name}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Nova dosagem',
                suffixText: medication.unit,
                border: const OutlineInputBorder(),
                helperText: 'Quantidade por dose',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final newDosage = double.tryParse(controller.text);
              if (newDosage != null && newDosage > 0) {
                Navigator.of(context).pop();
                _updateMedicationDosage(medication, newDosage);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Por favor, insira um valor válido')),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _updateMedicationDosage(Medication medication, double newDosage) {
    final updatedMedication = medication.copyWith(
      dosageAmount: newDosage,
      updatedAt: DateTime.now(),
    );

    context.read<MedicationBloc>().add(UpdateMedication(updatedMedication));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dosagem atualizada com sucesso!'),
        backgroundColor: AppColors.successColor,
      ),
    );
  }
}
