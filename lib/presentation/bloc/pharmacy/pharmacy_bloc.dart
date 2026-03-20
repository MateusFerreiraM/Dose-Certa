import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dose_certa/domain/entities/pharmacy.dart';
import 'package:dose_certa/domain/usecases/pharmacy_usecases.dart';

abstract class PharmacyEvent extends Equatable {
  const PharmacyEvent();
  @override
  List<Object?> get props => [];
}

class LoadPharmacies extends PharmacyEvent {}

class SearchPharmaciesEvent extends PharmacyEvent {
  final double latitude;
  final double longitude;
  final double radius;
  final String? query;

  const SearchPharmaciesEvent({
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.query,
  });

  @override
  List<Object?> get props => [latitude, longitude, radius, query];
}

class AddFavoritePharmacy extends PharmacyEvent {
  final Pharmacy pharmacy;
  const AddFavoritePharmacy(this.pharmacy);
  @override
  List<Object?> get props => [pharmacy];
}

class RemoveFavoritePharmacy extends PharmacyEvent {
  final String pharmacyId;
  const RemoveFavoritePharmacy(this.pharmacyId);
  @override
  List<Object?> get props => [pharmacyId];
}

abstract class PharmacyState extends Equatable {
  const PharmacyState();
  @override
  List<Object?> get props => [];
}

class PharmacyInitial extends PharmacyState {}

class PharmacyLoading extends PharmacyState {}

class PharmacyLoaded extends PharmacyState {
  final List<Pharmacy> pharmacies;
  final List<Pharmacy> favorites;

  const PharmacyLoaded({
    required this.pharmacies,
    this.favorites = const [],
  });

  @override
  List<Object?> get props => [pharmacies, favorites];
}

class PharmacyError extends PharmacyState {
  final String message;
  const PharmacyError(this.message);
  @override
  List<Object?> get props => [message];
}

class PharmacyBloc extends Bloc<PharmacyEvent, PharmacyState> {
  final PharmacyUseCases pharmacyUseCases;

  PharmacyBloc(this.pharmacyUseCases) : super(PharmacyInitial()) {
    on<LoadPharmacies>(_onLoadPharmacies);
    on<SearchPharmaciesEvent>(_onSearchPharmacies);
    on<AddFavoritePharmacy>(_onAddFavorite);
    on<RemoveFavoritePharmacy>(_onRemoveFavorite);
  }

  Future<void> _onLoadPharmacies(
      LoadPharmacies event, Emitter<PharmacyState> emit) async {
    emit(PharmacyLoading());
    try {
      final pharmacies = await pharmacyUseCases.getFavoritePharmacies();
      emit(PharmacyLoaded(pharmacies: [], favorites: pharmacies));
    } catch (e) {
      emit(PharmacyError('Erro ao carregar farmácias: $e'));
    }
  }

  Future<void> _onSearchPharmacies(
      SearchPharmaciesEvent event, Emitter<PharmacyState> emit) async {
    emit(PharmacyLoading());
    try {
      final pharmacies = await pharmacyUseCases.searchNearbyPharmacies(
        latitude: event.latitude,
        longitude: event.longitude,
        radius: event.radius,
        query: event.query,
      );

      final favorites = await pharmacyUseCases.getFavoritePharmacies();

      emit(PharmacyLoaded(pharmacies: pharmacies, favorites: favorites));
    } catch (e) {
      emit(PharmacyError('Erro ao buscar farmácias: $e'));
    }
  }

  Future<void> _onAddFavorite(
      AddFavoritePharmacy event, Emitter<PharmacyState> emit) async {
    try {
      await pharmacyUseCases.addFavoritePharmacy(event.pharmacy);

      if (state is PharmacyLoaded) {
        final currentState = state as PharmacyLoaded;
        final alreadyFavorite =
            currentState.favorites.any((p) => p.id == event.pharmacy.id);
        if (alreadyFavorite) return;

        final updatedFavorites = List<Pharmacy>.from(currentState.favorites)
          ..add(event.pharmacy);

        emit(PharmacyLoaded(
          pharmacies: currentState.pharmacies,
          favorites: updatedFavorites,
        ));
      }
    } catch (e) {
      emit(PharmacyError('Erro ao adicionar favorito: $e'));
    }
  }

  Future<void> _onRemoveFavorite(
      RemoveFavoritePharmacy event, Emitter<PharmacyState> emit) async {
    try {
      await pharmacyUseCases.removeFavoritePharmacy(event.pharmacyId);

      if (state is PharmacyLoaded) {
        final currentState = state as PharmacyLoaded;
        final updatedFavorites = currentState.favorites
            .where((pharmacy) => pharmacy.id != event.pharmacyId)
            .toList();

        emit(PharmacyLoaded(
          pharmacies: currentState.pharmacies,
          favorites: updatedFavorites,
        ));
      }
    } catch (e) {
      emit(PharmacyError('Erro ao remover favorito: $e'));
    }
  }
}
