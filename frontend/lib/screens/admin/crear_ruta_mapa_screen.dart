import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/ruta_service.dart';
import '../../models/ruta.dart';

/// Pantalla para crear/editar rutas tocando el mapa.
/// – Los puntos se agregan INMEDIATAMENTE al tocar (sin esperar OSRM).
/// – Después de cada tap, se llama a OSRM de forma desacoplada con TODOS
///   los waypoints a la vez para obtener la geometría real por calles.
/// – Mientras OSRM responde se muestran líneas provisionales entre waypoints.
/// – Si OSRM falla, las líneas provisionales quedan como fallback.
class CrearRutaMapaScreen extends StatefulWidget {
  final Ruta? rutaExistente;
  const CrearRutaMapaScreen({super.key, this.rutaExistente});

  @override
  State<CrearRutaMapaScreen> createState() => _CrearRutaMapaScreenState();
}

class _CrearRutaMapaScreenState extends State<CrearRutaMapaScreen> {
  final MapController _mapController = MapController();
  final RutaService _rutaService = RutaService();
  final _nombreController = TextEditingController();
  final _searchController = TextEditingController();

  /// Puntos seleccionados por el usuario
  final List<LatLng> _waypoints = [];

  /// Geometría real calculada por OSRM (sigue calles)
  List<LatLng> _polilineaOsrm = [];

  /// Métricas de OSRM
  double _distanciaKm = 0;
  double _duracionSeg = 0;

  bool _isSatellite = false;
  bool _isRouting = false;   // OSRM en vuelo
  bool _isSearching = false;
  bool _isSaving = false;
  bool _osrmOk = false;      // true si el último cálculo OSRM tuvo éxito

  static const LatLng _defaultCenter = LatLng(-18.0146, -70.2536);

  @override
  void initState() {
    super.initState();
    if (widget.rutaExistente != null) {
      _nombreController.text = widget.rutaExistente!.nombre;
      final pts = widget.rutaExistente!.puntos
          .map((p) => LatLng(p.latitud, p.longitud))
          .toList();
      _waypoints.addAll(pts);
      if (pts.length >= 2) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _calcularRutaOsrm());
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════
  //  OSRM: calcula la ruta con TODOS los waypoints actuales
  // ══════════════════════════════════════════════════════════════

  List<LatLng> _decodificarPolyline6(String encoded) {
    final List<LatLng> result = [];
    int index = 0;
    final int len = encoded.length;
    int lat = 0;
    int lng = 0;
    while (index < len) {
      int b, shift = 0, r = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        r |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (r & 1) != 0 ? ~(r >> 1) : (r >> 1);

      shift = 0; r = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        r |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (r & 1) != 0 ? ~(r >> 1) : (r >> 1);

      result.add(LatLng(lat / 1e6, lng / 1e6));
    }
    return result;
  }

  Future<void> _calcularRutaOsrm() async {
    if (_waypoints.length < 2) return;
    setState(() {
      _isRouting = true;
      _osrmOk = false;
    });

    try {
      // Un solo request con todos los waypoints: lon,lat;lon,lat;...
      final coords = _waypoints
          .map((p) => '${p.longitude},${p.latitude}')
          .join(';');

      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$coords'
        '?overview=full&geometries=polyline6&steps=false',
      );

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 15));

      debugPrint('[OSRM] status=${response.statusCode}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        debugPrint('[OSRM] code=${data['code']}');

        if (data['code'] == 'Ok') {
          final route = data['routes'][0] as Map<String, dynamic>;
          final puntos = _decodificarPolyline6(route['geometry'] as String);
          final distM = (route['distance'] as num).toDouble();
          final durS = (route['duration'] as num).toDouble();

          debugPrint('[OSRM] ✅ ${puntos.length} puntos, ${distM / 1000} km');

          setState(() {
            _polilineaOsrm = puntos;
            _distanciaKm = distM / 1000;
            _duracionSeg = durS;
            _isRouting = false;
            _osrmOk = true;
          });
          return;
        }
      }

      // Respuesta no-OK de OSRM → fallback
      _aplicarFallback();
    } catch (e) {
      debugPrint('[OSRM] ❌ Error: $e');
      if (mounted) _aplicarFallback();
    }
  }

  /// Fallback: línea recta entre waypoints con distancia estimada
  void _aplicarFallback() {
    double dist = 0;
    if (_waypoints.length >= 2) {
      const dc = Distance();
      for (int i = 0; i < _waypoints.length - 1; i++) {
        dist += dc.as(LengthUnit.Kilometer, _waypoints[i], _waypoints[i + 1]);
      }
    }
    setState(() {
      _polilineaOsrm = List.from(_waypoints);
      _distanciaKm = dist;
      _duracionSeg = (dist / 40.0) * 3600;
      _isRouting = false;
      _osrmOk = false;
    });
  }

  // ══════════════════════════════════════════════════════════════
  //  ACCIONES DEL MAPA
  // ══════════════════════════════════════════════════════════════

  void _onMapTap(TapPosition _, LatLng point) {
    // 1. Agrega el punto INMEDIATAMENTE (sin esperar OSRM)
    setState(() => _waypoints.add(point));

    // 2. Lanza el cálculo OSRM de forma desacoplada (no bloqueante)
    if (_waypoints.length >= 2) {
      _calcularRutaOsrm(); // sin await → no bloquea el tap
    }
  }

  void _deshacerUltimo() {
    if (_waypoints.isEmpty) return;
    setState(() {
      _waypoints.removeLast();
      _polilineaOsrm = [];
      _distanciaKm = 0;
      _duracionSeg = 0;
      _osrmOk = false;
    });
    if (_waypoints.length >= 2) {
      _calcularRutaOsrm();
    }
  }

  void _clearAll() {
    setState(() {
      _waypoints.clear();
      _polilineaOsrm.clear();
      _distanciaKm = 0;
      _duracionSeg = 0;
      _osrmOk = false;
    });
  }

  // ══════════════════════════════════════════════════════════════
  //  BÚSQUEDA DE DIRECCIÓN
  // ══════════════════════════════════════════════════════════════

  Future<void> _buscarDireccion(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}&format=json&limit=1',
      );
      final res = await http
          .get(url)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat'] as String);
          final lon = double.parse(data[0]['lon'] as String);
          _mapController.move(LatLng(lat, lon), 16.0);
        } else {
          _toast('Dirección no encontrada', Colors.orange);
        }
      }
    } catch (_) {
      _toast('Error de búsqueda', Colors.red);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  GUARDAR
  // ══════════════════════════════════════════════════════════════

  Future<void> _guardar() async {
    if (_nombreController.text.trim().isEmpty) {
      _toast('Escribe un nombre para la ruta', Colors.orange);
      return;
    }
    if (_waypoints.length < 2) {
      _toast('Agrega al menos 2 puntos', Colors.orange);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final datos = {
        'nombre': _nombreController.text.trim(),
        'distanciaTotal': double.parse(_distanciaKm.toStringAsFixed(2)),
        'duracionEstimadaMinutos': (_duracionSeg / 60).round().clamp(1, 99999),
        'puntos': _waypoints.asMap().entries.map((e) => {
          'lat': e.value.latitude,
          'lng': e.value.longitude,
          'orden': e.key + 1,
        }).toList(),
      };
      if (widget.rutaExistente != null) {
        await _rutaService.actualizarRuta(widget.rutaExistente!.id, datos);
      } else {
        await _rutaService.crearRuta(datos);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      _toast('Error al guardar: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _toast(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ══════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════

  int get _minutos => (_duracionSeg / 60).round();

  @override
  Widget build(BuildContext context) {
    final center = _waypoints.isNotEmpty ? _waypoints.first : _defaultCenter;

    // La línea a dibujar:
    // – Si OSRM respondió → usa geometría real (sigue calles)
    // – Si está calculando o no hay geometría → usa waypoints (línea recta provisional)
    final List<LatLng> lineaVisible = _polilineaOsrm.isNotEmpty
        ? _polilineaOsrm
        : _waypoints;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.rutaExistente != null ? 'Editar Ruta' : 'Nueva Ruta por Calles',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF8E24ED),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isSatellite ? Icons.map : Icons.satellite_alt),
            onPressed: () => setState(() => _isSatellite = !_isSatellite),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _waypoints.isEmpty ? null : _clearAll,
          ),
        ],
      ),
      body: Stack(
        children: [

          // ── MAPA PRINCIPAL ─────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14.0,
              onTap: _onMapTap,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [

              // Tiles
              TileLayer(
                urlTemplate: _isSatellite
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                    : 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.flota.monitoreo',
              ),

              // ── POLILÍNEA PROVISIONAL (línea recta mientras OSRM calcula) ──
              // Siempre visible si hay 2+ puntos, así el usuario ve algo de inmediato
              if (_waypoints.length >= 2 && _polilineaOsrm.isEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _waypoints,
                      color: Colors.grey.withValues(alpha: 0.6),
                      strokeWidth: 4,
                      // Estilo punteado para denotar que aún no es la ruta real
                      isDotted: true,
                    ),
                  ],
                ),

              // ── POLILÍNEA OSRM (calles reales) — halo ─────────────────────
              if (lineaVisible.length >= 2 && _polilineaOsrm.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: lineaVisible,
                      color: Colors.white.withValues(alpha: 0.4),
                      strokeWidth: 11,
                    ),
                  ],
                ),

              // ── POLILÍNEA OSRM (calles reales) — línea principal ──────────
              if (lineaVisible.length >= 2 && _polilineaOsrm.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: lineaVisible,
                      color: const Color(0xFF8E24ED),
                      strokeWidth: 5.5,
                      borderColor: Colors.white,
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),

              // ── MARCADORES ────────────────────────────────────────────────
              MarkerLayer(
                markers: _waypoints.asMap().entries.map((e) {
                  final i = e.key;
                  final p = e.value;
                  final isFirst = i == 0;
                  final isLast = i == _waypoints.length - 1 && _waypoints.length > 1;
                  final Color bg = isFirst
                      ? Colors.green.shade700
                      : isLast
                          ? Colors.red.shade700
                          : const Color(0xFF8E24ED);

                  return Marker(
                    point: p,
                    width: 46,
                    height: 46,
                    child: Container(
                      decoration: BoxDecoration(
                        color: bg,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: bg.withValues(alpha: 0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: isFirst
                            ? const Icon(Icons.play_arrow, color: Colors.white, size: 22)
                            : isLast
                                ? const Icon(Icons.flag, color: Colors.white, size: 20)
                                : Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // ── OVERLAY "CALCULANDO RUTA..." ──────────────────────────────────
          if (_isRouting)
            Positioned(
              bottom: 130,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8E24ED),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12)],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Calculando ruta por calles (OSRM)...',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── PANEL SUPERIOR: búsqueda + nombre + stats ─────────────────────
          Positioned(
            top: 12, left: 12, right: 12,
            child: Column(
              children: [
                // Barra de búsqueda
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar dirección...',
                        border: InputBorder.none,
                        icon: const Icon(Icons.search, color: Color(0xFF8E24ED)),
                        suffixIcon: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(width: 20, height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => _searchController.clear()),
                      ),
                      onSubmitted: _buscarDireccion,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Card nombre + stats
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _nombreController,
                          decoration: InputDecoration(
                            hintText: 'Nombre de la ruta...',
                            prefixIcon: const Icon(Icons.route, color: Color(0xFF8E24ED)),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            isDense: true,
                          ),
                        ),
                        if (_waypoints.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _chip(Icons.location_on, '${_waypoints.length} pts', const Color(0xFF8E24ED)),
                              _chip(Icons.straighten,
                                  '${_distanciaKm.toStringAsFixed(2)} km', Colors.orange),
                              _chip(Icons.schedule, '$_minutos min', Colors.green),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Badge estado OSRM
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isRouting
                                    ? Icons.hourglass_top
                                    : _osrmOk
                                        ? Icons.check_circle
                                        : Icons.warning_amber,
                                size: 13,
                                color: _isRouting
                                    ? Colors.blue
                                    : _osrmOk
                                        ? Colors.green
                                        : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isRouting
                                    ? 'Calculando ruta real...'
                                    : _osrmOk
                                        ? 'Ruta por calles reales ✓'
                                        : _waypoints.length >= 2
                                            ? 'Ruta provisional (sin OSRM)'
                                            : 'Toca el mapa para trazar',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _isRouting
                                      ? Colors.blue
                                      : _osrmOk
                                          ? Colors.green
                                          : Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── CONTROLES DE ZOOM + DESHACER ──────────────────────────────────
          Positioned(
            right: 12,
            bottom: 120,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'cr_zi',
                  backgroundColor: Colors.white,
                  onPressed: () => _mapController.move(
                    _mapController.camera.center, _mapController.camera.zoom + 1),
                  child: const Icon(Icons.add, color: Color(0xFF8E24ED)),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'cr_zo',
                  backgroundColor: Colors.white,
                  onPressed: () => _mapController.move(
                    _mapController.camera.center, _mapController.camera.zoom - 1),
                  child: const Icon(Icons.remove, color: Color(0xFF8E24ED)),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'cr_undo',
                  mini: true,
                  backgroundColor: Colors.orange,
                  onPressed: _waypoints.isEmpty ? null : _deshacerUltimo,
                  tooltip: 'Deshacer último punto',
                  child: const Icon(Icons.undo, color: Colors.white),
                ),
              ],
            ),
          ),

          // ── LEYENDA ────────────────────────────────────────────────────────
          if (_waypoints.isNotEmpty)
            Positioned(
              left: 12,
              bottom: 90,
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _leyenda(Colors.green.shade700, 'Inicio'),
                      const SizedBox(height: 3),
                      _leyenda(const Color(0xFF8E24ED), 'Parada'),
                      const SizedBox(height: 3),
                      _leyenda(Colors.red.shade700, 'Destino'),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 22, height: 3,
                              color: const Color(0xFF8E24ED)),
                          const SizedBox(width: 4),
                          const Text('Calles reales', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 22, height: 2,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(1),
                              )),
                          const SizedBox(width: 4),
                          const Text('Provisional', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── INSTRUCCIONES INICIALES ────────────────────────────────────────
          if (_waypoints.isEmpty)
            Positioned(
              bottom: 100,
              left: 24,
              right: 24,
              child: Card(
                color: const Color(0xFF8E24ED).withValues(alpha: 0.95),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.touch_app, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Toca el mapa para agregar puntos.\n'
                          'La ruta seguirá las calles automáticamente.',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── BOTÓN GUARDAR ─────────────────────────────────────────────────
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: (_isSaving || _isRouting) ? null : _guardar,
              icon: _isSaving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_alt),
              label: Text(
                widget.rutaExistente != null ? 'ACTUALIZAR RUTA' : 'GUARDAR RUTA',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade400,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPERS ──────────────────────────────────────────────────────────────────

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _leyenda(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 11, height: 11, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
