import 'package:flutter/material.dart';
import 'package:dose_certa/presentation/pages/splash_page.dart';
import 'package:dose_certa/presentation/pages/reminders_page.dart';
import 'package:dose_certa/presentation/pages/add_reminder_page.dart';
import 'package:dose_certa/presentation/pages/medication_details_page.dart';
import 'package:dose_certa/presentation/pages/stock_management_page.dart';
import 'package:dose_certa/presentation/pages/pharmacies_page.dart';
import 'package:dose_certa/presentation/pages/reports_page.dart';
import 'package:dose_certa/presentation/pages/profile_page.dart';
import 'package:dose_certa/presentation/pages/main_page.dart';

class AppRouter {
  static const String splash = '/';
  static const String main = '/main';
  static const String reminders = '/reminders';
  static const String addReminder = '/add_reminder';
  static const String medicationDetails = '/medication_details';
  static const String stockManagement = '/stock_management';
  static const String pharmacies = '/pharmacies';
  static const String reports = '/reports';
  static const String profile = '/profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashPage(),
        );
      case main:
        return MaterialPageRoute(
          builder: (_) => const MainPage(),
        );
      case reminders:
        return MaterialPageRoute(
          builder: (_) => const RemindersPage(),
        );
      case addReminder:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => AddReminderPage(
            medicationId: args != null ? args['medicationId'] as int? : null,
          ),
        );
      case medicationDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => MedicationDetailsPage(
            medicationId: args?['medicationId'] as int? ?? 0,
          ),
        );
      case stockManagement:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => StockManagementPage(
            medicationId: args?['medicationId'] as int? ?? 0,
          ),
        );
      case pharmacies:
        return MaterialPageRoute(
          builder: (_) => const PharmaciesPage(),
        );
      case reports:
        return MaterialPageRoute(
          builder: (_) => const ReportsPage(),
        );
      case profile:
        return MaterialPageRoute(
          builder: (_) => const ProfilePage(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Página não encontrada: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
