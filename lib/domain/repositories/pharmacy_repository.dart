import 'package:dose_certa/domain/entities/pharmacy.dart';

abstract class PharmacyRepository {
  Future<List<Pharmacy>> getNearbyPharmacies(double latitude, double longitude);

  Future<List<Pharmacy>> searchNearbyPharmacies({
    required double latitude,
    required double longitude,
    required double radius,
    String? query,
  });

  Future<List<Pharmacy>> getFavoritePharmacies();

  Future<void> addFavoritePharmacy(Pharmacy pharmacy);

  Future<void> removeFavoritePharmacy(String pharmacyId);
}
