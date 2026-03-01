import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/viaje.dart';
import '../models/ubicacion.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

final viajeProvider = StateNotifierProvider<ViajeNotifier, ViajeState>((ref) {
  final userId = ref.watch(authProvider.select((value) => value.user?.id));
  return ViajeNotifier(conductorId: userId);
});

class ViajeState {
  final Viaje? viajeActual;
  final bool isLoading;
  final bool isSendingLocation;
  final String? error;

  ViajeState({this.viajeActual, this.isLoading = false, this.isSendingLocation = false, this.error});

  ViajeState copyWith({Viaje? viajeActual, bool? isLoading, bool? isSendingLocation, String? error}) {
    return ViajeState(
      viajeActual: viajeActual ?? this.viajeActual,
      isLoading: isLoading ?? this.isLoading,
      isSendingLocation: isSendingLocation ?? this.isSendingLocation,
      error: error,
    );
  }
}

class ViajeNotifier extends StateNotifier<ViajeState> {
  final int? _conductorId;
  final _api = ApiService();

  ViajeNotifier({int? conductorId})
      : _conductorId = conductorId,
        super(ViajeState()) {
    if (_conductorId != null) cargarViaje();
  }

  Future<void> cargarViaje() async {
    if (_conductorId == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final viajesJson = await _api.getViajesEnCurso();

      // Buscamos el viaje que pertenezca a este conductor (probando todas las variantes de la clave)
      final miViajeData = viajesJson.firstWhere(
        (v) => (v['conductor_id'] == _conductorId || 
                v['idConductor'] == _conductorId || 
                v['conductorId'] == _conductorId ||
                v['usuario_id'] == _conductorId),
        orElse: () => null,
      );

      if (miViajeData != null) {
        state = state.copyWith(viajeActual: Viaje.fromJson(miViajeData));
      } else {
        state = state.copyWith(viajeActual: null);
      }
    } catch (e) {
      state = state.copyWith(error: 'Error al cargar viaje: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> iniciarViaje(int viajeId) async {
    try {
      await _api.iniciarViaje(viajeId);
      state = state.copyWith(
        viajeActual: state.viajeActual?.copyWith(estado: 'EN_CURSO'),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> finalizarViaje(int viajeId, {double? kmFinal}) async {
    try {
      await _api.finalizarViaje(viajeId, kmFinal: kmFinal);
      state = state.copyWith(viajeActual: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void setSendingLocation(bool value) {
    state = state.copyWith(isSendingLocation: value);
  }
}