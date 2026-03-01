import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_provider.dart';

class MapaVehiculos extends ConsumerStatefulWidget {
  @override
  _MapaVehiculosState createState() => _MapaVehiculosState();
}

class _MapaVehiculosState extends ConsumerState<MapaVehiculos> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  @override
  void didUpdateWidget(covariant MapaVehiculos oldWidget) {
    super.didUpdateWidget(oldWidget);
    _actualizarMarcadores(ref.read(adminProvider));
  }

  void _actualizarMarcadores(AdminState state) {
    _markers.clear();
    // Aquí deberías tener las últimas ubicaciones de cada vehículo.
    // Por ahora, simulamos algunos puntos fijos.
    _markers.add(
      Marker(
        markerId: MarkerId('vehiculo1'),
        position: LatLng(40.416775, -3.703790),
        infoWindow: InfoWindow(title: 'Vehículo ABC-123'),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(40.416775, -3.703790),
        zoom: 12,
      ),
      markers: _markers,
      onMapCreated: (controller) {
        _mapController = controller;
      },
    );
  }
}