import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../models/ruta.dart';

/// Mapa que ve el conductor: muestra su ubicación en tiempo real
/// y, opcionalmente, los puntos de la ruta asignada.
class DriverMapaScreen extends StatefulWidget {
  final List<PuntoRuta> puntosRuta;
  final String nombreRuta;

  const DriverMapaScreen({
    super.key,
    required this.puntosRuta,
    required this.nombreRuta,
  });

  @override
  State<DriverMapaScreen> createState() => _DriverMapaScreenState();
}

class _DriverMapaScreenState extends State<DriverMapaScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _posicionSubscription;

  LatLng? _miUbicacion;
  double _miVelocidad = 0;
  bool _siguiendoUbicacion = true;
  bool _isSatellite = false;
  bool _permisoOk = false;

  static const LatLng _defaultCenter = LatLng(-12.046374, -77.042793);

  @override
  void initState() {
    super.initState();
    _iniciarGPS();
  }

  @override
  void dispose() {
    _posicionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _iniciarGPS() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _mostrarError('El GPS del dispositivo está desactivado.');
      return;
    }

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        _mostrarError('Permiso de GPS denegado.');
        return;
      }
    }
    if (permiso == LocationPermission.deniedForever) {
      _mostrarError('Permiso de GPS denegado permanentemente.');
      return;
    }

    setState(() => _permisoOk = true);

    // Obtener posición inmediata
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _actualizarPosicion(pos);
    } catch (_) {}

    // Suscribirse al stream
    _posicionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_actualizarPosicion);
  }

  void _actualizarPosicion(Position pos) {
    final nuevaPos = LatLng(pos.latitude, pos.longitude);
    setState(() {
      _miUbicacion = nuevaPos;
      _miVelocidad = pos.speed * 3.6; // m/s → km/h
    });
    if (_siguiendoUbicacion) {
      _mapController.move(nuevaPos, _mapController.camera.zoom);
    }
  }

  void _mostrarError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  List<LatLng> get _puntosLatLng =>
      widget.puntosRuta.map((p) => LatLng(p.latitud, p.longitud)).toList();

  @override
  Widget build(BuildContext context) {
    final center = _miUbicacion ??
        (_puntosLatLng.isNotEmpty ? _puntosLatLng.first : _defaultCenter);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mi Ubicación', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (widget.nombreRuta.isNotEmpty)
              Text('Ruta: ${widget.nombreRuta}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isSatellite ? Icons.map : Icons.satellite_alt),
            onPressed: () => setState(() => _isSatellite = !_isSatellite),
            tooltip: 'Cambiar tipo de mapa',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 15.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onMapEvent: (event) {
                // Si el usuario mueve el mapa manualmente, desactiva el seguimiento
                if (event is MapEventScrollWheelZoom ||
                    event is MapEventMove && event.source != MapEventSource.mapController) {
                  if (_siguiendoUbicacion) {
                    setState(() => _siguiendoUbicacion = false);
                  }
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _isSatellite
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                    : 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.flota.monitoreo',
              ),

              // Línea de la ruta asignada
              if (_puntosLatLng.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _puntosLatLng,
                      color: Colors.orange.shade600,
                      strokeWidth: 5.0,
                    ),
                  ],
                ),

              // Puntos de parada de la ruta
              if (_puntosLatLng.isNotEmpty)
                MarkerLayer(
                  markers: _puntosLatLng.asMap().entries.map((e) {
                    final i = e.key;
                    final p = e.value;
                    final isFirst = i == 0;
                    final isLast = i == _puntosLatLng.length - 1;
                    return Marker(
                      point: p,
                      width: 32,
                      height: 32,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isFirst
                              ? Colors.green
                              : isLast
                                  ? Colors.red
                                  : Colors.orange.shade600,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

              // Marcador del conductor (yo)
              if (_miUbicacion != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _miUbicacion!,
                      width: 60,
                      height: 70,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade900,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: Text(
                              '${_miVelocidad.toStringAsFixed(0)} km/h',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade700,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
                            ),
                            child: const Icon(Icons.person_pin, color: Colors.white, size: 22),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ── PANEL INFERIOR: estado y velocidad ─────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12)],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoTile(
                    icon: Icons.speed,
                    label: 'Velocidad',
                    value: _miUbicacion != null
                        ? '${_miVelocidad.toStringAsFixed(0)} km/h'
                        : '-- km/h',
                    color: _miVelocidad > 80 ? Colors.red : Colors.green,
                  ),
                  _infoTile(
                    icon: Icons.location_on,
                    label: 'Coordenadas',
                    value: _miUbicacion != null
                        ? '${_miUbicacion!.latitude.toStringAsFixed(5)}, ${_miUbicacion!.longitude.toStringAsFixed(5)}'
                        : 'Buscando GPS...',
                    color: Colors.blue,
                  ),
                  _infoTile(
                    icon: Icons.gps_fixed,
                    label: 'GPS',
                    value: _miUbicacion != null ? 'Activo ✓' : 'Buscando...',
                    color: _miUbicacion != null ? Colors.green : Colors.orange,
                  ),
                ],
              ),
            ),
          ),

          // ── BOTÓN: Centrar en mi ubicación ─────────────────────
          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton.small(
              heroTag: 'center_btn',
              backgroundColor: Colors.white,
              onPressed: () {
                if (_miUbicacion != null) {
                  setState(() => _siguiendoUbicacion = true);
                  _mapController.move(_miUbicacion!, 16.0);
                }
              },
              child: Icon(
                _siguiendoUbicacion ? Icons.gps_fixed : Icons.gps_not_fixed,
                color: Colors.blue.shade700,
              ),
            ),
          ),

          // Mensaje si no hay permiso de GPS
          if (!_permisoOk && _miUbicacion == null)
            Center(
              child: Card(
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.gps_off, size: 48, color: Colors.orange),
                      const SizedBox(height: 16),
                      const Text('Esperando permiso de GPS...',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _iniciarGPS,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
      ],
    );
  }
}
