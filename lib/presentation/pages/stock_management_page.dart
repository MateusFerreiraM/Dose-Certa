import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dose_certa/presentation/bloc/medication/medication_bloc.dart';
import 'package:dose_certa/presentation/bloc/medication/medication_event.dart';
import 'package:dose_certa/presentation/bloc/medication/medication_state.dart';
import 'package:dose_certa/domain/entities/medication.dart';
import 'package:dose_certa/core/theme/app_theme.dart';
import 'package:dose_certa/core/di/injection_container.dart';
import 'package:dose_certa/services/notification/notification_service.dart';
import 'package:dose_certa/services/notification/reminder_sync_service.dart';

class StockManagementPage extends StatefulWidget {
  final int medicationId;

  const StockManagementPage({Key? key, required this.medicationId})
      : super(key: key);

  @override
  State<StockManagementPage> createState() => _StockManagementPageState();
}

class _StockManagementPageState extends State<StockManagementPage> {
  Medication? _medication;
  final TextEditingController _stockController = TextEditingController();
  bool _alertsEnabled = true;
  final TextEditingController _alertThresholdController =
      TextEditingController();
  bool _loading = false;

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
    final matches =
        state.medications.where((m) => m.id == widget.medicationId).toList();
    if (matches.isEmpty) return;
    final med = matches.first;
    setState(() {
      _medication = med;
      _stockController.text = med.stockQuantity.toString();
      _alertsEnabled = med.stockAlertsEnabled;
      _alertThresholdController.text = med.stockAlertThreshold.toString();
    });
  }

  @override
  void dispose() {
    _stockController.dispose();
    _alertThresholdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_medication == null) return;

    final stock = int.tryParse(_stockController.text);
    final alertThreshold = int.tryParse(_alertThresholdController.text);

    if (stock == null || stock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Por favor, insira uma quantidade válida')));
      return;
    }

    if (alertThreshold == null || alertThreshold < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Por favor, insira um limite de alerta válido')));
      return;
    }

    setState(() => _loading = true);
    final updated = _medication!.copyWith(
      stockQuantity: stock,
      stockAlertThreshold: alertThreshold,
      stockAlertsEnabled: _alertsEnabled,
    );

    try {
      context.read<MedicationBloc>().add(UpdateMedication(updated));
      final notif = getIt<NotificationService>();
      final syncPrefs = getIt<ReminderSyncService>();
      final medId = _medication!.id;
      if (medId != null) {
        final notifId = medId + 100000; // id único para notificações de estoque
        final globalEnabled = syncPrefs.stockAlertsEnabled;
        if (globalEnabled && _alertsEnabled && stock <= alertThreshold) {
          final title = 'Estoque baixo: ${_medication!.name}';
          final body = 'Restam $stock ${_medication!.unit}. Considere repor.';
          final scheduled = DateTime.now().add(const Duration(seconds: 10));
          await notif.scheduleMedicationReminder(
            id: notifId,
            title: title,
            body: body,
            scheduledDate: scheduled,
          );
        } else {
          await notif.cancelNotification(notifId);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estoque atualizado com sucesso!')));
      Navigator.of(context).pop(); // Volta para a tela anterior
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Gerenciar Estoque'),
        backgroundColor: AppColors.primaryBrown,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _medication == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _medication!.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryBrown,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Dosagem: ${_medication!.formattedDosage}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quantidade em Estoque',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Quantidade atual',
                                suffixText: _medication!.unit,
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.inventory),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alertas de Estoque',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              title: const Text(
                                  'Receber alertas de estoque baixo'),
                              subtitle: const Text(
                                  'Você será notificado quando o estoque estiver baixo'),
                              value: _alertsEnabled,
                              onChanged: (v) =>
                                  setState(() => _alertsEnabled = v),
                              activeColor: AppColors.primaryBrown,
                            ),
                            if (_alertsEnabled) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _alertThresholdController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Alertar quando restarem',
                                  suffixText: _medication!.unit,
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.warning_amber),
                                  helperText:
                                      'Você receberá um alerta quando atingir esta quantidade',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBrown,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Salvar Alterações',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
