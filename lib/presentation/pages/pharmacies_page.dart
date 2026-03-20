import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dose_certa/presentation/bloc/pharmacy/pharmacy_bloc.dart';
import 'package:dose_certa/domain/entities/pharmacy.dart';
import 'package:dose_certa/core/di/injection_container.dart';
import 'package:dose_certa/services/location/location_service.dart';
import 'package:dose_certa/core/theme/app_theme.dart';

class PharmaciesPage extends StatefulWidget {
  const PharmaciesPage({Key? key}) : super(key: key);

  @override
  State<PharmaciesPage> createState() => _PharmaciesPageState();
}

class _PharmaciesPageState extends State<PharmaciesPage>
    with TickerProviderStateMixin {
  MapController? _mapController;
  Position? _currentPosition;
  TabController? _tabController;
  final TextEditingController _searchController = TextEditingController();

  final List<Marker> _markers = [];
  final LatLng _initialPosition =
      const LatLng(-15.7942, -47.8822); // Brasília default

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _mapController = MapController();
    context.read<PharmacyBloc>().add(LoadPharmacies());
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locationService = getIt<LocationService>();
      final position = await locationService.getCurrentLocation();
      if (position != null) {
        setState(() => _currentPosition = position);
        _mapController?.move(
            LatLng(position.latitude, position.longitude), 15.0);
        _searchNearbyPharmacies();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao obter localização: $e')),
      );
    }
  }

  void _searchNearbyPharmacies({String? query}) {
    if (_currentPosition != null) {
      final q = (query ?? _searchController.text).trim();
      context.read<PharmacyBloc>().add(
            SearchPharmaciesEvent(
              latitude: _currentPosition!.latitude,
              longitude: _currentPosition!.longitude,
              radius: 5000, // 5km
              query: q.isEmpty ? null : q,
            ),
          );
    }
  }

  void _updateMapMarkers(List<Pharmacy> pharmacies) {
    setState(() {
      _markers.clear();
      if (_currentPosition != null) {
        _markers.add(
          Marker(
            point:
                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            width: 40,
            height: 40,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.primaryBrown,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_pin_circle,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        );
      }
      for (final pharmacy in pharmacies) {
        _markers.add(
          Marker(
            point: LatLng(pharmacy.latitude, pharmacy.longitude),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => _showPharmacyDetails(pharmacy),
              child: Container(
                decoration: BoxDecoration(
                  color: pharmacy.isOpen ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_pharmacy,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        );
      }
    });
  }

  void _showPharmacyDetails(Pharmacy pharmacy) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PharmacyDetailsSheet(pharmacy: pharmacy),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmácias Próximas'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.primaryLight,
          tabs: const [
            Tab(icon: Icon(Icons.map), text: 'Mapa'),
            Tab(icon: Icon(Icons.list), text: 'Lista'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar farmácias...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchNearbyPharmacies(query: '');
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (query) {
                _searchNearbyPharmacies(query: query);
              },
            ),
          ),
          Expanded(
            child: BlocConsumer<PharmacyBloc, PharmacyState>(
              listener: (context, state) {
                if (state is PharmacyLoaded) {
                  _updateMapMarkers(state.pharmacies);
                } else if (state is PharmacyError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              builder: (context, state) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMapView(state),
                    _buildListView(state),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView(PharmacyState state) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentPosition != null
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
            : _initialPosition,
        initialZoom: 14.0,
        minZoom: 5.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.dose_certa',
          maxZoom: 18,
        ),
        MarkerLayer(markers: _markers),
      ],
    );
  }

  Widget _buildListView(PharmacyState state) {
    if (state is PharmacyLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is PharmacyLoaded) {
      final favoriteIds = state.favorites.map((p) => p.id).toSet();
      final nonFavoriteResults =
          state.pharmacies.where((p) => !favoriteIds.contains(p.id)).toList();

      if (state.favorites.isEmpty && nonFavoriteResults.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_pharmacy_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Nenhuma farmácia encontrada',
                  style: TextStyle(fontSize: 16)),
              Text('Tente aumentar o raio de busca',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
      }

      return ListView(
        children: [
          if (state.favorites.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Favoritas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ...state.favorites.map(
            (pharmacy) => _PharmacyListTile(
              pharmacy: pharmacy,
              isFavorite: true,
              onToggleFavorite: () {
                context
                    .read<PharmacyBloc>()
                    .add(RemoveFavoritePharmacy(pharmacy.id));
              },
            ),
          ),
          if (state.favorites.isNotEmpty && nonFavoriteResults.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'Resultados',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ...nonFavoriteResults.map(
            (pharmacy) => _PharmacyListTile(
              pharmacy: pharmacy,
              isFavorite: false,
              onToggleFavorite: () {
                context.read<PharmacyBloc>().add(AddFavoritePharmacy(pharmacy));
              },
            ),
          ),
        ],
      );
    } else if (state is PharmacyError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.message),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _searchNearbyPharmacies,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    return const Center(
        child: Text('Toque no botão de localização para buscar farmácias'));
  }
}

class _PharmacyListTile extends StatelessWidget {
  final Pharmacy pharmacy;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const _PharmacyListTile({
    required this.pharmacy,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: pharmacy.isOpen ? Colors.green : Colors.red,
          child: Icon(
            Icons.local_pharmacy,
            color: Colors.white,
          ),
        ),
        title: Text(pharmacy.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pharmacy.address),
            if (pharmacy.distanceKm != null)
              Text('Distância: ${pharmacy.distanceText}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: pharmacy.isOpen ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    pharmacy.statusText,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                if (pharmacy.rating != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      Text(pharmacy.rating!.toStringAsFixed(1)),
                    ],
                  ),
              ],
            ),
            IconButton(
              tooltip: isFavorite
                  ? 'Remover dos favoritos'
                  : 'Adicionar aos favoritos',
              onPressed: onToggleFavorite,
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : null,
              ),
            ),
          ],
        ),
        onTap: () => _showPharmacyDetails(context, pharmacy),
      ),
    );
  }

  void _showPharmacyDetails(BuildContext context, Pharmacy pharmacy) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PharmacyDetailsSheet(pharmacy: pharmacy),
    );
  }
}

class _PharmacyDetailsSheet extends StatelessWidget {
  final Pharmacy pharmacy;

  const _PharmacyDetailsSheet({required this.pharmacy});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PharmacyBloc, PharmacyState>(
      builder: (context, state) {
        final favorites =
            state is PharmacyLoaded ? state.favorites : const <Pharmacy>[];
        final isFavorite = favorites.any((p) => p.id == pharmacy.id);

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: pharmacy.isOpen ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Icon(
                            Icons.local_pharmacy,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pharmacy.name,
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: pharmacy.isOpen
                                      ? Colors.green
                                      : Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  pharmacy.statusText,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: isFavorite
                              ? 'Remover dos favoritos'
                              : 'Adicionar aos favoritos',
                          onPressed: () {
                            final bloc = context.read<PharmacyBloc>();
                            if (isFavorite) {
                              bloc.add(RemoveFavoritePharmacy(pharmacy.id));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Removida dos favoritos')),
                              );
                            } else {
                              bloc.add(AddFavoritePharmacy(pharmacy));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Adicionada aos favoritos')),
                              );
                            }
                          },
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (pharmacy.rating != null)
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          const SizedBox(width: 8),
                          Text(
                              '${pharmacy.rating!.toStringAsFixed(1)} estrelas'),
                        ],
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.location_on),
                        const SizedBox(width: 8),
                        Expanded(child: Text(pharmacy.address)),
                      ],
                    ),
                    if (pharmacy.distanceKm != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.directions_walk),
                          const SizedBox(width: 8),
                          Text('Distância: ${pharmacy.distanceText}'),
                        ],
                      ),
                    ],
                    if (pharmacy.phone != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone),
                          const SizedBox(width: 8),
                          Text(pharmacy.phone!),
                        ],
                      ),
                    ],
                    if (pharmacy.openingHours != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time),
                          const SizedBox(width: 8),
                          Text(pharmacy.openingHours!),
                        ],
                      ),
                    ],
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openInMaps(pharmacy),
                            icon: const Icon(Icons.directions),
                            label: const Text('Como chegar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _callPharmacy(pharmacy.phone),
                            icon: const Icon(Icons.phone),
                            label: const Text('Ligar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openInMaps(Pharmacy pharmacy) async {
    final String googleUrl =
        'https://www.google.com/maps/search/?api=1&query=${pharmacy.latitude},${pharmacy.longitude}';
    if (await canLaunchUrl(Uri.parse(googleUrl))) {
      await launchUrl(Uri.parse(googleUrl));
    }
  }

  void _callPharmacy(String? phone) async {
    if (phone != null && phone.isNotEmpty) {
      final String telUrl = 'tel:$phone';
      if (await canLaunchUrl(Uri.parse(telUrl))) {
        await launchUrl(Uri.parse(telUrl));
      }
    }
  }
}
