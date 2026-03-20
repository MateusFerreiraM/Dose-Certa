import 'package:equatable/equatable.dart';

class Pharmacy extends Equatable {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? phone;
  final String? website;
  final double? rating;
  final bool isOpen;
  final String? openingHours;
  final String? photoUrl;
  final double? distanceKm;

  const Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.website,
    this.rating,
    this.isOpen = true,
    this.openingHours,
    this.photoUrl,
    this.distanceKm,
  });

  Pharmacy copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? phone,
    String? website,
    double? rating,
    bool? isOpen,
    String? openingHours,
    String? photoUrl,
    double? distanceKm,
  }) {
    return Pharmacy(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      rating: rating ?? this.rating,
      isOpen: isOpen ?? this.isOpen,
      openingHours: openingHours ?? this.openingHours,
      photoUrl: photoUrl ?? this.photoUrl,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }

  String get statusText => isOpen ? 'Aberto' : 'Fechado';

  String get distanceText {
    if (distanceKm == null) return '';
    if (distanceKm! < 1) {
      return '${(distanceKm! * 1000).round()}m';
    }
    return '${distanceKm!.toStringAsFixed(1)}km';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        latitude,
        longitude,
        phone,
        website,
        rating,
        isOpen,
        openingHours,
        photoUrl,
        distanceKm,
      ];
}
