import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/ruta.dart';

/// Mapa de vista general que muestra TODAS las rutas con geometría OSRM real.
/// Cada ruta se calcula de forma async y se actualiza en el mapa
/// a medida que OSRM responde. Mientras tanto muestra líneas rectas temporales.
class RutasOverviewMapaWidget extends StatefulWidget {
  final List<Ruta> rutas;
  final String? selectedRutaId;

  const RutasOverviewMapaWidget({
    super.key,
    required this.rutas,
    this.selectedRutaId,
  });

  @override
  State<RutasOverviewMapaWidget> createState() =>
      _RutasOverviewMapaWidgetState();
}

class _RutasOverviewMapaWidgetState extends State<RutasOverviewMapaWidget> {
  /// Guarda la polilínea OSRM calculada para cada ruta (clave = ruta.id)
  final Map<String, List<LatLng>> _polilineas = {};

  /// Cuántas rutas ya terminaron de calcularse
  int _calculadas = 0;

  @override
  void initState() {
    super.initState();
    _calcularTodasLasRutas();
  }

  @override
  void didUpdateWidget(covariant RutasOverviewMapaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rutas != oldWidget.rutas) {
      _polilineas.clear();
      _calculadas = 0;
      _calcularTodasLasRutas();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  OSRM
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

  Future<void> _calcularTodasLasRutas() async {
    // Primero ponemos líneas rectas como placeholder para todas las rutas
    setState(() {
      for (final ruta in widget.rutas) {
        if (ruta.puntos.length >= 2) {
          _polilineas[ruta.id] =
              ruta.puntos.map((p) => LatLng(p.latitud, p.longitud)).toList();
        }
      }
    });

    // Luego calculamos OSRM para cada ruta de forma independiente
    for (final ruta in widget.rutas) {
      if (!mounted) return;
      if (ruta.puntos.length >= 2) {
        _calcularOsrmParaRuta(ruta); // sin await → todas corren en paralelo
      }
    }
  }

  Future<void> _calcularOsrmParaRuta(Ruta ruta) async {
    try {
      final coords = ruta.puntos
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
            _polilineas[ruta.id] = puntos;
            _calculadas++;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('[OSRM Overview] ruta=${ruta.id} error=$e');
    }
    // Fallback ya está puesto (línea recta del initState)
    if (mounted) setState(() => _calculadas++);
  }

  // ═══════════════════════════════════════════════════════════════
  //  COLORES por ruta
  // ═══════════════════════════════════════════════════════════════

  static const List<Color> _palette = [
    Color(0xFF1565C0), // azul oscuro
    Color(0xFFC62828), // rojo
    Color(0xFF2E7D32), // verde
    Color(0xFFE65100), // naranja
    Color(0xFF6A1B9A), // morado
    Color(0xFF00695C), // teal
    Color(0xFF283593), // indigo
    Color(0xFFAD1457), // rosa
    Color(0xFF0097A7), // cyan
    Color(0xFFF57F17), // amber
  ];

  Color _colorParaRuta(String id) {
    int hash = 0;
    for (int i = 0; i < id.length; i++) {
      hash = id.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return _palette[hash.abs() % _palette.length];
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // Si hay una ruta seleccionada, intentamos centrar en ella,
    // de lo contrario, al primer punto de la primera ruta.
    LatLng centro = const LatLng(-18.0146, -70.2536);
    if (widget.selectedRutaId != null) {
      final selectedRuta = widget.rutas.firstWhere(
        (r) => r.id == widget.selectedRutaId,
        orElse: () => widget.rutas.first,
      );
      if (selectedRuta.puntos.isNotEmpty) {
        centro = LatLng(selectedRuta.puntos[0].latitud, selectedRuta.puntos[0].longitud);
      }
    } else if (widget.rutas.isNotEmpty && widget.rutas[0].puntos.isNotEmpty) {
      centro = LatLng(widget.rutas[0].puntos[0].latitud, widget.rutas[0].puntos[0].longitud);
    }

    final bool todoCalculado = _calculadas >= widget.rutas.where((r) => r.puntos.length >= 2).length;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: centro,
              initialZoom: 12.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.monitoreo.flota',
              ),

              // ── HALOS de cada polilínea ────────────────────────────────────
              PolylineLayer(
                polylines: widget.rutas
                    .where((ruta) =>
                        _polilineas.containsKey(ruta.id) &&
                        _polilineas[ruta.id]!.length >= 2)
                    .map((ruta) {
                  final isSelected = widget.selectedRutaId == null || widget.selectedRutaId == ruta.id;
                  final color = _colorParaRuta(ruta.id);
                  return Polyline(
                    points: _polilineas[ruta.id]!,
                    color: color.withValues(alpha: isSelected ? 0.35 : 0.1),
                    strokeWidth: isSelected ? 12 : 6,
                  );
                }).toList(),
              ),

              // ── POLILÍNEAS principales (OSRM o rectas provisionales) ───────
              PolylineLayer(
                polylines: (() {
                  final list = widget.rutas
                      .where((ruta) =>
                          _polilineas.containsKey(ruta.id) &&
                          _polilineas[ruta.id]!.length >= 2)
                      .toList();
                  // Ordenar para que la seleccionada se dibuje al final (encima)
                  list.sort((a, b) {
                    if (a.id == widget.selectedRutaId) return 1;
                    if (b.id == widget.selectedRutaId) return -1;
                    return 0;
                  });
                  return list.map((ruta) {
                    final isSelected = widget.selectedRutaId == null || widget.selectedRutaId == ruta.id;
                    final isDimmed = widget.selectedRutaId != null && widget.selectedRutaId != ruta.id;
                    final color = _colorParaRuta(ruta.id);
                    return Polyline(
                      points: _polilineas[ruta.id]!,
                      color: isDimmed ? color.withValues(alpha: 0.3) : color,
                      strokeWidth: isSelected ? 5.5 : 3.0,
                      borderColor: isDimmed ? Colors.transparent : Colors.white,
                      borderStrokeWidth: isDimmed ? 0 : 1.5,
                    );
                  }).toList();
                })(),
              ),

              // ── MARCADORES de inicio y fin de cada ruta ────────────────────
              MarkerLayer(
                markers: widget.rutas
                    .where((r) => r.puntos.length >= 2)
                    .expand((ruta) {
                  final isDimmed = widget.selectedRutaId != null && widget.selectedRutaId != ruta.id;
                  final color = _colorParaRuta(ruta.id);
                  final drawColor = isDimmed ? color.withValues(alpha: 0.4) : color;
                  final inicio = LatLng(
                    ruta.puntos.first.latitud,
                    ruta.puntos.first.longitud,
                  );
                  final fin = LatLng(
                    ruta.puntos.last.latitud,
                    ruta.puntos.last.longitud,
                  );
                  return [
                    _marcador(inicio, drawColor, Icons.play_arrow, ruta.nombre, isDimmed),
                    _marcador(fin, drawColor, Icons.flag, ruta.nombre, isDimmed),
                  ];
                }).toList(),
              ),
            ],
          ),
        ),

        // Badge "Calculando..." mientras OSRM trabaja
        if (!todoCalculado)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF8E24ED).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Calculando rutas reales...',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

        // Badge "Rutas reales" cuando todo está calculado
        if (todoCalculado && _polilineas.isNotEmpty)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green.shade700.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 13),
                  SizedBox(width: 5),
                  Text(
                    'Rutas por calles reales',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Marker _marcador(LatLng punto, Color color, IconData icon, String nombre, bool isDimmed) {
    return Marker(
      point: punto,
      width: isDimmed ? 28 : 36,
      height: isDimmed ? 28 : 36,
      child: Tooltip(
        message: nombre,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: isDimmed ? Colors.transparent : Colors.white, width: isDimmed ? 0 : 2.5),
            boxShadow: [
              if (!isDimmed)
                BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)
            ],
          ),
          child: Icon(icon, color: Colors.white.withValues(alpha: isDimmed ? 0.6 : 1.0), size: isDimmed ? 14 : 16),
        ),
      ),
    );
  }
}
