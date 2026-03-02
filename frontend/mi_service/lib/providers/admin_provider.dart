import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehiculo.dart';
import '../models/conductor.dart';
import '../models/alerta.dart';
import '../services/api_service.dart';

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier();
});

class AdminState {
  final List<Vehiculo> vehiculos;
  final List<Conductor> conductores;
  final List<Alerta> alertas;
  final bool isLoading;
  final String? error;

  AdminState({
    this.vehiculos = const [],
    this.conductores = const [],
    this.alertas = const [],
    this.isLoading = false,
    this.error,
  });

  AdminState copyWith({
    List<Vehiculo>? vehiculos,
    List<Conductor>? conductores,
    List<Alerta>? alertas,
    bool? isLoading,
    String? error,
  }) {
    return AdminState(
      vehiculos: vehiculos ?? this.vehiculos,
      conductores: conductores ?? this.conductores,
      alertas: alertas ?? this.alertas,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  AdminNotifier() : super(AdminState()) {
    cargarDatos();
  }

  final _api = ApiService();

  Future<void> cargarDatos() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 1. Cargar Vehículos
      List<Vehiculo> vehiculos = [];
      try {
        final List<dynamic> vehiculosJson = await _api.get('/vehiculos');
        vehiculos = vehiculosJson.map((v) => Vehiculo.fromJson(v)).toList();
      } catch (e) {
        print('Error cargando vehículos: $e');
      }
 
      // 2. Cargar Conductores
      List<Conductor> conductores = [];
      try {
        final List<dynamic> conductoresJson = await _api.get('/conductores');
        conductores = conductoresJson.map((c) => Conductor.fromJson(c)).toList();
      } catch (e) {
        print('Error cargando conductores: $e');
      }
 
      // 3. Cargar Alertas (iterando viajes activos)
      List<Alerta> alertas = [];
      try {
        final List<dynamic> viajesEnCurso = await _api.get('/viajes/en-curso');
        for (var viaje in viajesEnCurso) {
          try {
            final viajeId = int.tryParse(viaje['id'].toString()) ?? 0;
            if (viajeId > 0) {
              final List<dynamic> alertasJson = await _api.get('/alertas/viaje/$viajeId/pendientes');
              alertas.addAll(alertasJson.map((a) => Alerta.fromJson(a)));
            }
          } catch (e) {
            print('Error cargando alertas para viaje: $e');
          }
        }
      } catch (e) {
        print('Error cargando viajes en curso: $e');
      }

      state = state.copyWith(
        vehiculos: vehiculos,
        conductores: conductores,
        alertas: alertas,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: 'Error general: $e', isLoading: false);
    }
  }

  Future<void> crearVehiculo(Map<String, dynamic> data) async {
    // Llamar a POST /vehiculos
    // Luego recargar
  }

  // Similar para editar, eliminar, etc.
}