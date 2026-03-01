import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import 'viaje_provider.dart';

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier(ref);
});

class LocationState {
  final bool isTracking;
  final Position? lastPosition;
  final String? error;

  LocationState({this.isTracking = false, this.lastPosition, this.error});

  LocationState copyWith({bool? isTracking, Position? lastPosition, String? error}) {
    return LocationState(
      isTracking: isTracking ?? this.isTracking,
      lastPosition: lastPosition ?? this.lastPosition,
      error: error,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier(this.ref) : super(LocationState());

  final Ref ref;
  final LocationService _locationService = LocationService();

  Future<void> startTracking(int viajeId) async {
    final hasPermission = await _locationService.requestPermission();
    if (!hasPermission) {
      state = state.copyWith(error: 'Permiso de ubicación denegado');
      return;
    }

    state = state.copyWith(isTracking: true);
    ref.read(viajeProvider.notifier).setSendingLocation(true);

    _locationService.startSendingLocation(viajeId, (ubicacion) async {
      try {
        await ApiService().enviarUbicacion(ubicacion);
      } catch (e) {
        state = state.copyWith(error: e.toString());
      }
    });

    _locationService.startListening((position) {
      state = state.copyWith(lastPosition: position);
    });
  }

  void stopTracking() {
    _locationService.stopListening();
    state = state.copyWith(isTracking: false);
    ref.read(viajeProvider.notifier).setSendingLocation(false);
  }
}