import 'package:dose_certa/domain/repositories/pharmacy_repository.dart';
import 'package:dose_certa/domain/entities/pharmacy.dart';
import 'package:dose_certa/data/database/database_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class PharmacyRepositoryImpl implements PharmacyRepository {
  final dynamic locationService;
  final DatabaseHelper _db;

  PharmacyRepositoryImpl(this.locationService, this._db);

  @override
  Future<List<Pharmacy>> searchNearbyPharmacies({
    required double latitude,
    required double longitude,
    required double radius,
    String? query,
  }) async {
    try {
      final overpassQuery = '''
[out:json][timeout:25];
(
  node["amenity"="pharmacy"](around:$radius,$latitude,$longitude);
  way["amenity"="pharmacy"](around:$radius,$latitude,$longitude);
  node["healthcare"="pharmacy"](around:$radius,$latitude,$longitude);
  way["healthcare"="pharmacy"](around:$radius,$latitude,$longitude);
  node["name"~"farmacia|farmácia|drogaria",i](around:$radius,$latitude,$longitude);
  way["name"~"farmacia|farmácia|drogaria",i](around:$radius,$latitude,$longitude);
);
out geom;
''';

      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: overpassQuery,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pharmacies = <Pharmacy>[];

        for (final element in data['elements']) {
          final tags = element['tags'] ?? {};
          final name = tags['name'] ?? 'Farmácia';

          double lat, lon;
          if (element['type'] == 'node') {
            lat = element['lat'].toDouble();
            lon = element['lon'].toDouble();
          } else if (element['type'] == 'way' &&
              element['geometry'] != null &&
              element['geometry'].isNotEmpty) {
            lat = element['geometry'][0]['lat'].toDouble();
            lon = element['geometry'][0]['lon'].toDouble();
          } else {
            continue;
          }
          final distanceKm = _calculateDistance(latitude, longitude, lat, lon);
          String? phone = tags['phone'] ?? tags['contact:phone'];
          String? openingHours = tags['opening_hours'];
          bool isOpen = _determineIfOpen(openingHours);
          String address = _buildAddress(tags);

          pharmacies.add(Pharmacy(
            id: element['id'].toString(),
            name: name,
            address: address,
            latitude: lat,
            longitude: lon,
            phone: phone,
            website: tags['website'],
            isOpen: isOpen,
            openingHours: openingHours,
            distanceKm: distanceKm,
          ));
        }
        if (query != null && query.trim().isNotEmpty) {
          final q = query.trim().toLowerCase();
          pharmacies.removeWhere((p) => !p.name.toLowerCase().contains(q));
        }
        pharmacies.sort(
            (a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999));

        return pharmacies.take(20).toList(); // Limit to 20 results
      } else {
        throw Exception('Erro ao buscar farmácias: ${response.statusCode}');
      }
    } catch (e) {
      print('Overpass API error: $e, using mock data');
      return _getMockPharmacies(latitude, longitude);
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth radius in kilometers
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  bool _determineIfOpen(String? openingHours) {
    if (openingHours == null) return true;
    if (openingHours.toLowerCase().contains('24/7')) return true;
    if (openingHours.toLowerCase().contains('24 hours')) return true;
    final now = DateTime.now();
    final hour = now.hour;
    return hour >= 7 && hour <= 22; // Assume open 7AM to 10PM
  }

  String _buildAddress(Map<String, dynamic> tags) {
    List<String> addressParts = [];

    if (tags['addr:street'] != null) {
      addressParts.add(tags['addr:street']);
    }
    if (tags['addr:housenumber'] != null) {
      addressParts.add(tags['addr:housenumber']);
    }
    if (tags['addr:neighbourhood'] != null) {
      addressParts.add(tags['addr:neighbourhood']);
    }
    if (tags['addr:city'] != null) {
      addressParts.add(tags['addr:city']);
    }

    return addressParts.isNotEmpty
        ? addressParts.join(', ')
        : 'Endereço não disponível';
  }

  @override
  Future<List<Pharmacy>> getFavoritePharmacies() async {
    final rows = await _db.getFavoritePharmacies();
    return rows.map((m) {
      double toDouble(dynamic v) {
        if (v == null) return 0;
        if (v is double) return v;
        if (v is int) return v.toDouble();
        return double.tryParse(v.toString()) ?? 0;
      }

      return Pharmacy(
        id: (m['id'] ?? '').toString(),
        name: (m['name'] ?? '').toString(),
        address: (m['address'] ?? '').toString(),
        phone: m['phone']?.toString(),
        latitude: toDouble(m['latitude']),
        longitude: toDouble(m['longitude']),
        openingHours: m['opening_hours']?.toString(),
        isOpen: true,
      );
    }).toList();
  }

  @override
  Future<void> addFavoritePharmacy(Pharmacy pharmacy) async {
    final data = <String, dynamic>{
      'name': pharmacy.name,
      'address': pharmacy.address,
      'phone': pharmacy.phone,
      'latitude': pharmacy.latitude,
      'longitude': pharmacy.longitude,
      'opening_hours': pharmacy.openingHours,
      'services': null,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };
    final parsedId = int.tryParse(pharmacy.id);
    if (parsedId != null) {
      data['id'] = parsedId;
    }

    await _db.insertFavoritePharmacy(data);
  }

  @override
  Future<void> removeFavoritePharmacy(String pharmacyId) async {
    final id = int.tryParse(pharmacyId);
    if (id == null) return;
    await _db.deleteFavoritePharmacy(id);
  }

  List<Pharmacy> _getMockPharmacies(double userLat, double userLon) {
    return [
      Pharmacy(
        id: '1',
        name: 'Farmácia Popular',
        address: 'Rua das Flores, 123 - Centro',
        latitude: userLat + 0.002,
        longitude: userLon + 0.002,
        phone: '(61) 3333-4444',
        rating: 4.5,
        isOpen: true,
        openingHours: 'Seg-Sex: 08:00-18:00, Sáb: 08:00-12:00',
        distanceKm: 0.3,
      ),
      Pharmacy(
        id: '2',
        name: 'Drogaria São Paulo',
        address: 'Av. Principal, 456 - Centro',
        latitude: userLat - 0.001,
        longitude: userLon + 0.003,
        phone: '(61) 2222-3333',
        rating: 4.2,
        isOpen: true,
        openingHours: '24 horas',
        distanceKm: 0.5,
      ),
      Pharmacy(
        id: '3',
        name: 'Farmácia do Bairro',
        address: 'Rua Secundária, 789 - Bairro Norte',
        latitude: userLat + 0.005,
        longitude: userLon - 0.001,
        phone: '(61) 1111-2222',
        rating: 3.8,
        isOpen: false,
        openingHours: 'Seg-Sex: 07:00-19:00, Sáb: 07:00-13:00',
        distanceKm: 0.8,
      ),
    ];
  }

  @override
  Future<List<Pharmacy>> getNearbyPharmacies(
      double latitude, double longitude) async {
    return searchNearbyPharmacies(
      latitude: latitude,
      longitude: longitude,
      radius: 5000,
    );
  }
}
