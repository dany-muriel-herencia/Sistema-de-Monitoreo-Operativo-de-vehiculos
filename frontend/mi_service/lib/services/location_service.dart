import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import '../models/ubicacion.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  bool _isListening = false;
  Stream<Position>? _positionStream;

  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition();
  }

  void startListening(Function(Position) onPositionChanged) {
    if (_isListening) return;
    _isListening = true;
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // metros
      ),
    );
    _positionStream!.listen((position) {
      onPositionChanged(position);
    });
  }

  void stopListening() {
    _isListening = false;
    // No podemos cancelar el stream directamente, pero podemos dejar de escuchar
    // En la práctica, el stream se cierra al salir de la app.
  }

  // Enviar ubicación cada 20 segundos mientras el viaje está activo
  void startSendingLocation(int viajeId, Function(Ubicacion) sendCallback) {
    const interval = Duration(seconds: 20);
    DateTime lastSent = DateTime.now();
    startListening((position) {
      final now = DateTime.now();
      if (now.difference(lastSent) >= interval) {
        lastSent = now;
        final ubicacion = Ubicacion(
          viajeId: viajeId,
          timestamp: now,
          latitud: position.latitude,
          longitud: position.longitude,
          velocidad: position.speed,
        );
        sendCallback(ubicacion);
        if (kDebugMode) {
          print('Ubicación enviada: $ubicacion');
        }
      }
    });
  }
}