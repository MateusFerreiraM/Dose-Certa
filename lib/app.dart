import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dose_certa/core/theme/app_theme.dart';
import 'package:dose_certa/core/routes/app_router.dart';
import 'package:dose_certa/presentation/bloc/medication/medication_bloc.dart';
import 'package:dose_certa/presentation/bloc/pharmacy/pharmacy_bloc.dart';
import 'package:dose_certa/presentation/bloc/reminder/reminder_bloc.dart';
import 'package:dose_certa/core/di/injection_container.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

class DoseCertaApp extends StatelessWidget {
  const DoseCertaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<MedicationBloc>(),
        ),
        BlocProvider(
          create: (_) => getIt<PharmacyBloc>(),
        ),
        BlocProvider(
          create: (_) => getIt<ReminderBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'Dose Certa',
        theme: AppTheme.lightTheme,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('pt', 'BR'),
        ],
        onGenerateRoute: AppRouter.generateRoute,
        initialRoute: AppRouter.splash,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
