import 'package:flutter/material.dart';

import 'package:dose_certa/core/di/injection_container.dart';
import 'package:dose_certa/services/notification/reminder_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _medicationReminders = true;
  bool _stockAlerts = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPrefs();
  }

  Future<void> _loadNotificationPrefs() async {
    try {
      final prefs = getIt<SharedPreferences>();
      setState(() {
        _medicationReminders =
            prefs.getBool(ReminderSyncService.kMedicationRemindersEnabledKey) ??
                true;
        _stockAlerts =
            prefs.getBool(ReminderSyncService.kStockAlertsEnabledKey) ?? true;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _buildSettingsSection(context),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Config'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showNotificationSettings(context);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Privacidade'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showPrivacySettings(context);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Ajuda'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showHelpSupport(context);
            },
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Config'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.medication),
                title: const Text('Lembretes de Medicamentos'),
                subtitle: const Text('Notificações para tomar medicamentos'),
                trailing: Switch(
                  value: _medicationReminders,
                  onChanged: (value) {
                    setState(() {
                      _medicationReminders = value;
                    });
                    this.setState(() {});
                    _persistAndSyncNotificationSettings();
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.inventory),
                title: const Text('Alertas de Estoque'),
                subtitle: const Text('Avisos quando estoque estiver baixo'),
                trailing: Switch(
                  value: _stockAlerts,
                  onChanged: (value) {
                    setState(() {
                      _stockAlerts = value;
                    });
                    this.setState(() {});
                    _persistAndSyncNotificationSettings();
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _persistAndSyncNotificationSettings() async {
    try {
      final prefs = getIt<SharedPreferences>();
      await prefs.setBool(
        ReminderSyncService.kMedicationRemindersEnabledKey,
        _medicationReminders,
      );
      await prefs.setBool(
        ReminderSyncService.kStockAlertsEnabledKey,
        _stockAlerts,
      );

      final sync = getIt<ReminderSyncService>();
      await sync.syncAll(daysAhead: 7);
    } catch (_) {}
  }

  void _showPrivacySettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacidade'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seus dados estão seguros',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
                '• Todas as informações são armazenadas localmente no seu dispositivo'),
            SizedBox(height: 4),
            Text('• Nenhum dado é enviado para servidores externos'),
            SizedBox(height: 16),
            Text(
              'Para apagar todos os dados:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
                'Vá em Configurações > Aplicativos > Dose Certa > Armazenamento > Limpar dados'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showHelpSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajuda'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Como usar o Dose Certa',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _buildHelpItem('📱', 'Adicionar Medicamento',
                  'Toque no botão + para adicionar um novo medicamento'),
              _buildHelpItem('⏰', 'Configurar Horários',
                  'Defina os horários para tomar cada medicamento'),
              _buildHelpItem('📦', 'Gerenciar Estoque',
                  'Acompanhe a quantidade de medicamentos disponível'),
              _buildHelpItem('🏥', 'Encontrar Farmácias',
                  'Use o mapa para localizar farmácias próximas'),
              const SizedBox(height: 16),
              const Text(
                'Precisa de mais ajuda?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Este aplicativo foi desenvolvido para ajudar no controle de medicamentos. '
                'Sempre consulte seu médico para orientações sobre sua medicação.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
