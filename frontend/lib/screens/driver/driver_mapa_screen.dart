import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  bool _isSearching = false;
  final _searchController = TextEditingController();

  List<LatLng> _rutaOsrm = [];
  bool _calculandoRuta = false;

  static const LatLng _defaultCenter = LatLng(-18.0146, -70.2536); // Tacna, Perú

  @override
  void initState() {
    super.initState();
    _iniciarGPS();
    _calcularRutaOsrm();
  }

  // ═══════════════════════════════════════════════════════════════
  //  OSRM: Trazado por calles reales
  // ═══════════════════════════════════════════════════════════════

  List<LatLng> _decodificarPolyline6(String encoded) {
    final List<LatLng> result = [];
    int index = 0;
    final int len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, r = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        r |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (r & 1) != 0 ? ~(r >> 1) : r >> 1;
      shift = 0; r = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        r |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (r & 1) != 0 ? ~(r >> 1) : r >> 1;
      result.add(LatLng(lat / 1e6, lng / 1e6));
    }
    return result;
  }

  Future<void> _calcularRutaOsrm() async {
    if (widget.puntosRuta.length < 2) return;
    setState(() => _calculandoRuta = true);

    try {
      final coords = widget.puntosRuta
          .map((p) => '${p.longitud},${p.latitud}')
          .join(';');

      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$coords'
        '?overview=full&geometries=polyline6&steps=false',
      );

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['code'] == 'Ok') {
          final geometry = data['routes'][0]['geometry'] as String;
          final puntos = _decodificarPolyline6(geometry);
          setState(() {
            _rutaOsrm = puntos;
            _calculandoRuta = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('[OSRM Driver] error=$e');
    }
    
    if (mounted) setState(() => _calculandoRuta = false);
  }

  @override
  void dispose() {
    _posicionSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _buscarDireccion(String query) async {
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final point = LatLng(lat, lon);
          
          setState(() => _siguiendoUbicacion = false);
          _mapController.move(point, 16.0);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ubicación: ${data[0]['display_name']}'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (_) {} 
    finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  String _obtenerProximaParada() {
    if (_miUbicacion == null || widget.puntosRuta.isEmpty) return 'Iniciando...';

    int indiceMasCercano = 0;
    double distMin = double.infinity;
    const distance = Distance();

    for (int i = 0; i < widget.puntosRuta.length; i++) {
        final p = widget.puntosRuta[i];
        final dist = distance.as(LengthUnit.Meter, _miUbicacion!, LatLng(p.latitud, p.longitud));
        if (dist < distMin) {
            distMin = dist;
            indiceMasCercano = i;
        }
    }

    // Si estamos en el último punto, ya llegamos
    if (indiceMasCercano == widget.puntosRuta.length - 1 && distMin < 50) {
        return '¡Has llegado a tu destino!';
    }

    // El siguiente punto es el proximo en la lista
    int nextIdx = indiceMasCercano + 1;
    if (nextIdx >= widget.puntosRuta.length) return 'Final de Ruta';
    
    return 'Dirígete a: Parada ${nextIdx + 1}';
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
              if (_rutaOsrm.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    // Halo decorativo
                    Polyline(
                      points: _rutaOsrm,
                      color: Colors.orange.withValues(alpha: 0.3),
                      strokeWidth: 10.0,
                    ),
                    // Línea principal por calle
                    Polyline(
                      points: _rutaOsrm,
                      color: Colors.orange.shade700,
                      strokeWidth: 5.0,
                      borderColor: Colors.white,
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                )
              else if (_puntosLatLng.length >= 2)
                PolylineLayer(
                  polylines: [
                    // Fallback (línea recta punteada) mientras carga o si falla
                    Polyline(
                      points: _puntosLatLng,
                      color: Colors.orange.shade600.withValues(alpha: 0.5),
                      strokeWidth: 4.0,
                      isDotted: true,
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

                    if (!isFirst && !isLast) {
                      return Marker(
                        point: p,
                        width: 24,
                        height: 24,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.orange.shade600,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    }

                    return Marker(
                      point: p,
                      width: 45,
                      height: 45,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.location_on,
                            color: isFirst ? Colors.green.shade700 : Colors.red.shade700,
                            size: 45,
                          ),
                          Positioned(
                            top: 6,
                            child: Icon(
                              isFirst ? Icons.home : Icons.flag,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
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

          // ── BARRA DE BÚSQUEDA ──────────────────────────────────
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Column(
              children: [
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Buscar casa, calle o lugar...',
                        border: InputBorder.none,
                        icon: const Icon(Icons.search, color: Colors.blue, size: 20),
                        suffixIcon: _isSearching 
                          ? const SizedBox(width: 18, height: 18, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                          : IconButton(
                              icon: const Icon(Icons.clear, size: 18), 
                              onPressed: () => _searchController.clear()
                            ),
                      ),
                      onSubmitted: _buscarDireccion,
                    ),
                  ),
                ),
                if (widget.puntosRuta.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Card(
                      color: Colors.blue.shade800,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.near_me, color: Colors.white, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _obtenerProximaParada(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15
                                    ),
                                  ),
                                  Text(
                                    'Ruta: ${widget.nombreRuta}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white24,
                                shape: BoxShape.circle
                              ),
                              child: const Icon(Icons.turn_right, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── PANEL INFERIOR: estado y velocidad ─────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12)],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
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
                          ? '${_miUbicacion!.latitude.toStringAsFixed(4)}, ${_miUbicacion!.longitude.toStringAsFixed(4)}'
                          : 'GPS...',
                      color: Colors.blue,
                    ),
                    _infoTile(
                      icon: Icons.flag,
                      label: 'Destino',
                      value: '${widget.puntosRuta.length} paradas',
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── BOTÓN: Centrar en mi ubicación ─────────────────────
          Positioned(
            right: 16,
            bottom: 120, // Subido un poco para no tapar el panel de abajo
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  backgroundColor: Colors.white,
                  onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
                  child: const Icon(Icons.add, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  backgroundColor: Colors.white,
                  onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
                  child: const Icon(Icons.remove, color: Colors.blue),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'center_btn',
                  mini: true,
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
              ],
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
