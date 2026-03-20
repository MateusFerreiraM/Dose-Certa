import 'package:flutter/material.dart';
import 'package:dose_certa/presentation/pages/reminders_page.dart';
import 'package:dose_certa/presentation/pages/reports_page.dart';
import 'package:dose_certa/presentation/pages/pharmacies_page.dart';
import 'package:dose_certa/presentation/pages/profile_page.dart';
import 'package:dose_certa/core/theme/app_theme.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const RemindersPage(),
    const ReportsPage(),
    const PharmaciesPage(),
    const ProfilePage(),
  ];

  final List<BottomNavigationBarItem> _bottomNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.alarm),
      label: 'Lembretes',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.analytics),
      label: 'Relatório',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.local_pharmacy),
      label: 'Farmácias',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: 'Config',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surfaceColor,
          selectedItemColor: AppColors.primaryBrown,
          unselectedItemColor: AppColors.textSecondary,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          items: _bottomNavItems,
        ),
      ),
    );
  }
}
