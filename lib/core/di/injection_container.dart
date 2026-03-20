import 'package:get_it/get_it.dart';
import 'package:dose_certa/data/database/database_helper.dart';
import 'package:dose_certa/data/repositories/medication_repository_impl.dart';
import 'package:dose_certa/data/repositories/pharmacy_repository_impl.dart';
import 'package:dose_certa/data/repositories/medication_dose_repository_impl.dart';
import 'package:dose_certa/domain/repositories/medication_repository.dart';
import 'package:dose_certa/domain/repositories/medication_dose_repository.dart';
import 'package:dose_certa/domain/repositories/pharmacy_repository.dart';
import 'package:dose_certa/domain/usecases/medication_usecases.dart';
import 'package:dose_certa/domain/usecases/pharmacy_usecases.dart';
import 'package:dose_certa/domain/usecases/dose_usecases.dart';
import 'package:dose_certa/presentation/bloc/medication/medication_bloc.dart';
import 'package:dose_certa/presentation/bloc/pharmacy/pharmacy_bloc.dart';
import 'package:dose_certa/presentation/bloc/reminder/reminder_bloc.dart';
import 'package:dose_certa/services/notification/notification_service.dart';
import 'package:dose_certa/services/notification/reminder_sync_service.dart';
import 'package:dose_certa/services/location/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

Future<void> initializeDependencies() async {
  getIt.registerSingletonAsync<DatabaseHelper>(() async {
    final helper = DatabaseHelper.instance;
    await helper.database; // Initialize database
    return helper;
  });
  getIt.registerSingletonAsync<SharedPreferences>(() async {
    return SharedPreferences.getInstance();
  });
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());
  getIt.registerLazySingleton<LocationService>(() => LocationService());
  getIt.registerLazySingleton<ReminderSyncService>(
    () => ReminderSyncService(
      getIt<MedicationRepository>(),
      getIt<DoseUseCases>(),
      getIt<NotificationService>(),
      getIt<SharedPreferences>(),
    ),
  );
  getIt.registerLazySingleton<MedicationRepository>(
    () => MedicationRepositoryImpl(getIt<DatabaseHelper>()),
  );
  getIt.registerLazySingleton<MedicationDoseRepository>(
    () => MedicationDoseRepositoryImpl(getIt<DatabaseHelper>()),
  );
  getIt.registerLazySingleton<DoseUseCases>(
      () => DoseUseCases(getIt<MedicationDoseRepository>()));
  getIt.registerLazySingleton<PharmacyRepository>(
    () => PharmacyRepositoryImpl(
        getIt<LocationService>(), getIt<DatabaseHelper>()),
  );
  getIt.registerLazySingleton(
      () => MedicationUseCases(getIt<MedicationRepository>()));
  getIt.registerLazySingleton(
      () => PharmacyUseCases(getIt<PharmacyRepository>()));
  getIt.registerFactory(() => MedicationBloc(getIt<MedicationRepository>(),
      getIt<DoseUseCases>(), getIt<ReminderSyncService>()));
  getIt.registerFactory(() => PharmacyBloc(getIt<PharmacyUseCases>()));
  getIt.registerFactory(() => ReminderBloc(getIt<ReminderSyncService>()));

  await getIt.allReady();
}
