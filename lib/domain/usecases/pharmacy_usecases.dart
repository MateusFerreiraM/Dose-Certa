import 'package:dose_certa/domain/entities/pharmacy.dart';
import 'package:dose_certa/domain/repositories/pharmacy_repository.dart';

class PharmacyUseCases {
  final PharmacyRepository repository;

  PharmacyUseCases(this.repository);

  Future<List<Pharmacy>> searchNearbyPharmacies({
    required double latitude,
    required double longitude,
    required double radius,
    String? query,
  }) async {
    return await repository.searchNearbyPharmacies(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
      query: query,
    );
  }

  Future<List<Pharmacy>> getFavoritePharmacies() async {
    return await repository.getFavoritePharmacies();
  }

  Future<void> addFavoritePharmacy(Pharmacy pharmacy) async {
    await repository.addFavoritePharmacy(pharmacy);
  }

  Future<void> removeFavoritePharmacy(String pharmacyId) async {
    await repository.removeFavoritePharmacy(pharmacyId);
  }
}
