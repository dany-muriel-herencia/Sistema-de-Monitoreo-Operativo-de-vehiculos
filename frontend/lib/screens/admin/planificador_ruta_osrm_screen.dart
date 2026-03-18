import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// =============================================================================
//  PlanificadorRutaOsrmScreen
// =============================================================================
//  Pantalla interactiva de planificación de rutas usando:
//    • flutter_map   → renderizado del mapa (OpenStreetMap)
//    • OSRM v1       → cálculo de ruta siguiendo calles reales (gratuito)
//    • Nominatim     → geocodificación inversa / búsqueda (gratuito)
//
//  Flujo del usuario:
//    1er tap  → coloca marcador INICIO  (verde)
//    2do tap  → coloca marcador FIN (rojo) y llama a OSRM automáticamente
//    3er tap+ → reinicia y vuelve al paso 1
// =============================================================================

/// Estado interno de la selección
enum _SelectionState { none, startSelected, routeReady }

class PlanificadorRutaOsrmScreen extends StatefulWidget {
  /// Centro inicial del mapa. Por defecto: Tacna, Perú.
  final LatLng centroInicial;

  const PlanificadorRutaOsrmScreen({
    super.key,
    this.centroInicial = const LatLng(-18.0146, -70.2536),
  });

  @override
  State<PlanificadorRutaOsrmScreen> createState() =>
      _PlanificadorRutaOsrmScreenState();
}

class _PlanificadorRutaOsrmScreenState
    extends State<PlanificadorRutaOsrmScreen>
    with TickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────────────────────
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();

  // ── Estado de la ruta ────────────────────────────────────────────────────────
  _SelectionState _estado = _SelectionState.none;
  LatLng? _puntoInicio;
  LatLng? _puntoFin;
  List<LatLng> _polilinea = []; // Geometría decodificada de OSRM

  // ── Datos de la respuesta OSRM ───────────────────────────────────────────────
  double _distanciaKm = 0;
  int _duracionMin = 0;

  // ── UI State ─────────────────────────────────────────────────────────────────
  bool _cargando = false;       // Indicador mientras OSRM responde
  bool _buscando = false;       // Indicador mientras Nominatim responde
  bool _isSatellite = false;    // Modo satélite/normal
  String? _mensajeError;        // Mensaje de error visible al usuario

  // ── Animaciones ──────────────────────────────────────────────────────────────
  late final AnimationController _panelCtrl;
  late final Animation<double> _panelAnimation;

  @override
  void initState() {
    super.initState();
    _panelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _panelAnimation = CurvedAnimation(
      parent: _panelCtrl,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _panelCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  LÓGICA DE TAP EN EL MAPA
  // ═══════════════════════════════════════════════════════════════════════════

  void _onMapTap(TapPosition _, LatLng punto) {
    // Si ya tenemos ruta o inicio+fin → reiniciamos todo
    if (_estado == _SelectionState.routeReady ||
        (_puntoInicio != null && _puntoFin != null)) {
      _resetear();
    }

    if (_puntoInicio == null) {
      // Primer tap → marcador INICIO
      setState(() {
        _puntoInicio = punto;
        _estado = _SelectionState.startSelected;
        _mensajeError = null;
      });
    } else {
      // Segundo tap → marcador FIN + llamada OSRM
      setState(() => _puntoFin = punto);
      _calcularRutaOsrm(_puntoInicio!, punto);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  OSRM: CÁLCULO DE RUTA POR CALLES REALES
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _calcularRutaOsrm(LatLng inicio, LatLng fin) async {
    setState(() {
      _cargando = true;
      _mensajeError = null;
      _polilinea = [];
    });

    // Formato: /route/v1/{profile}/{lon},{lat};{lon},{lat}?overview=full&geometries=polyline6
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${inicio.longitude},${inicio.latitude};'
      '${fin.longitude},${fin.latitude}'
      '?overview=full&geometries=polyline6&steps=false',
    );

    try {
      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (data['code'] != 'Ok') {
        throw Exception('OSRM: ${data['code']} - ${data['message'] ?? ''}');
      }

      final route = data['routes'][0] as Map<String, dynamic>;
      final geometryEncoded = route['geometry'] as String;
      final distanciaM = (route['distance'] as num).toDouble();
      final duracionS = (route['duration'] as num).toDouble();

      final puntos = _decodificarPolyline6(geometryEncoded);

      setState(() {
        _polilinea = puntos;
        _distanciaKm = distanciaM / 1000;
        _duracionMin = (duracionS / 60).round();
        _estado = _SelectionState.routeReady;
        _cargando = false;
      });

      _panelCtrl.forward(from: 0);
      _ajustarCamaraARuta(puntos);
    } catch (e) {
      setState(() {
        _cargando = false;
        _mensajeError = 'No se pudo calcular la ruta.\n${e.toString()}';
        // Dejamos marcadores pero sin polilínea
        _estado = _SelectionState.routeReady;
      });
      _panelCtrl.forward(from: 0);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  DECODIFICACIÓN DE POLYLINE6 (Google Encoded Polyline con 6 decimales)
  // ═══════════════════════════════════════════════════════════════════════════

  List<LatLng> _decodificarPolyline6(String encoded) {
    final List<LatLng> result = [];
    int index = 0;
    final int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      // Decodifica latitud
      int b, shift = 0, result0 = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result0 |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlat = (result0 & 1) != 0 ? ~(result0 >> 1) : (result0 >> 1);
      lat += dlat;

      // Decodifica longitud
      shift = 0;
      result0 = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result0 |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlng = (result0 & 1) != 0 ? ~(result0 >> 1) : (result0 >> 1);
      lng += dlng;

      // OSRM polyline6 usa 1e-6
      result.add(LatLng(lat / 1e6, lng / 1e6));
    }
    return result;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  AJUSTAR CÁMARA PARA MOSTRAR TODA LA RUTA (BOUNDING BOX)
  // ═══════════════════════════════════════════════════════════════════════════

  void _ajustarCamaraARuta(List<LatLng> puntos) {
    if (puntos.isEmpty) return;

    double minLat = puntos.first.latitude;
    double maxLat = puntos.first.latitude;
    double minLng = puntos.first.longitude;
    double maxLng = puntos.first.longitude;

    for (final p in puntos) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(40, 160, 40, 200),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BÚSQUEDA DE DIRECCIÓN (Nominatim)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _buscarDireccion(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _buscando = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}&format=json&limit=1&countrycodes=pe',
      );
      final res = await http
          .get(url)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List<dynamic>;
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat'] as String);
          final lon = double.parse(data[0]['lon'] as String);
          _mapController.move(LatLng(lat, lon), 16.0);
        } else {
          _mostrarSnack('No se encontró la dirección.', Colors.orange);
        }
      }
    } catch (_) {
      _mostrarSnack('Error en la búsqueda de dirección.', Colors.red);
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  RESETEAR TODO
  // ═══════════════════════════════════════════════════════════════════════════

  void _resetear() {
    _panelCtrl.reverse();
    setState(() {
      _puntoInicio = null;
      _puntoFin = null;
      _polilinea = [];
      _distanciaKm = 0;
      _duracionMin = 0;
      _estado = _SelectionState.none;
      _mensajeError = null;
    });
  }

  void _mostrarSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // ── MAPA ──────────────────────────────────────────────────────────
          _buildMapa(),

          // ── BARRA DE BÚSQUEDA ─────────────────────────────────────────────
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _buildSearchBar(),
          ),

          // ── INSTRUCCIONES / ESTADO ────────────────────────────────────────
          Positioned(
            top: 76,
            left: 12,
            right: 12,
            child: _buildInstruccionesBanner(),
          ),

          // ── INDICADOR DE CARGA ────────────────────────────────────────────
          if (_cargando) _buildLoadingOverlay(),

          // ── PANEL INFERIOR (ETA + distancia) ─────────────────────────────
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildInfoPanel(),
          ),

          // ── CONTROLES DE ZOOM ─────────────────────────────────────────────
          Positioned(
            right: 12,
            bottom: _estado == _SelectionState.routeReady ? 170 : 80,
            child: _buildZoomControls(),
          ),
        ],
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.alt_route, size: 22),
          SizedBox(width: 8),
          Text(
            'Planificador de Ruta OSRM',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1A0533),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        // Toggle satélite
        IconButton(
          icon: Icon(
            _isSatellite ? Icons.map_outlined : Icons.satellite_alt,
            color: Colors.white70,
          ),
          tooltip: 'Cambiar capa del mapa',
          onPressed: () => setState(() => _isSatellite = !_isSatellite),
        ),
        // Botón limpiar
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          tooltip: 'Reiniciar selección',
          onPressed: _estado == _SelectionState.none ? null : _resetear,
        ),
      ],
    );
  }

  // ── Mapa principal ──────────────────────────────────────────────────────────

  Widget _buildMapa() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.centroInicial,
        initialZoom: 14.0,
        onTap: _onMapTap,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // Capa de tiles
        TileLayer(
          urlTemplate: _isSatellite
              ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
              : 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.monitoreo.flota',
        ),

        // Sombra/halo de la polilínea para mayor visibilidad
        if (_polilinea.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _polilinea,
                color: Colors.white.withValues(alpha: 0.25),
                strokeWidth: 9.0,
              ),
            ],
          ),

        // Polilínea principal (ruta OSRM)
        if (_polilinea.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _polilinea,
                color: const Color(0xFF1565C0), // Azul oscuro
                strokeWidth: 5.5,
                borderColor: const Color(0xFF42A5F5),
                borderStrokeWidth: 1.0,
              ),
            ],
          ),

        // Marcadores de inicio y fin
        MarkerLayer(
          markers: _buildMarcadores(),
        ),
      ],
    );
  }

  List<Marker> _buildMarcadores() {
    final List<Marker> markers = [];

    if (_puntoInicio != null) {
      markers.add(_crearMarcador(
        punto: _puntoInicio!,
        color: const Color(0xFF2E7D32),
        icono: Icons.play_arrow,
        etiqueta: 'A',
        pulseGreen: true,
      ));
    }

    if (_puntoFin != null) {
      markers.add(_crearMarcador(
        punto: _puntoFin!,
        color: const Color(0xFFC62828),
        icono: Icons.flag,
        etiqueta: 'B',
        pulseGreen: false,
      ));
    }

    return markers;
  }

  Marker _crearMarcador({
    required LatLng punto,
    required Color color,
    required IconData icono,
    required String etiqueta,
    required bool pulseGreen,
  }) {
    return Marker(
      point: punto,
      width: 56,
      height: 68,
      alignment: const Alignment(0, -1), // ancla en la punta inferior
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Círculo "cabeza"
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icono, color: Colors.white, size: 22),
          ),
          // Triángulo apuntando hacia abajo
          CustomPaint(
            size: const Size(12, 10),
            painter: _TrianglePainter(color: color),
          ),
        ],
      ),
    );
  }

  // ── Barra de búsqueda ───────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar dirección en Perú...',
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF8E24ED)),
          suffixIcon: _buscando
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {});
                      },
                    )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: _buscarDireccion,
      ),
    );
  }

  // ── Banner de instrucciones ─────────────────────────────────────────────────

  Widget _buildInstruccionesBanner() {
    String texto;
    Color bgColor;
    IconData icono;

    switch (_estado) {
      case _SelectionState.none:
        texto = 'Toca el mapa para colocar el punto de INICIO';
        bgColor = const Color(0xFF2E7D32);
        icono = Icons.touch_app;
        break;
      case _SelectionState.startSelected:
        texto = 'Toca el mapa para colocar el punto de FIN';
        bgColor = const Color(0xFFC62828);
        icono = Icons.touch_app;
        break;
      case _SelectionState.routeReady:
        return const SizedBox.shrink(); // El panel inferior reemplaza esto
    }

    return AnimatedOpacity(
      opacity: _estado != _SelectionState.routeReady ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                texto,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Overlay de carga ────────────────────────────────────────────────────────

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.35),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: Color(0xFF1565C0),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Calculando ruta...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Consultando servidor OSRM',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Panel de información (ETA + distancia) ──────────────────────────────────

  Widget _buildInfoPanel() {
    if (_estado != _SelectionState.routeReady) return const SizedBox.shrink();

    return SizeTransition(
      sizeFactor: _panelAnimation,
      axisAlignment: -1,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF1565C0)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1565C0).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: _mensajeError != null
            ? _buildErrorContent()
            : _buildRouteContent(),
      ),
    );
  }

  Widget _buildRouteContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Encabezado
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.directions_bus, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ruta Calculada',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Siguiendo calles reales • OSRM',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Botón reiniciar
              GestureDetector(
                onTap: _resetear,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.refresh, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),

          // Métricas: Tiempo y Distancia
          Row(
            children: [
              Expanded(
                child: _buildMetricaTile(
                  icono: Icons.access_time_filled,
                  valor: _duracionMin < 60
                      ? '$_duracionMin min'
                      : '${(_duracionMin / 60).floor()}h ${_duracionMin % 60}min',
                  etiqueta: 'Tiempo estimado',
                  color: const Color(0xFF4FC3F7),
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white24,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              Expanded(
                child: _buildMetricaTile(
                  icono: Icons.straighten,
                  valor: '${_distanciaKm.toStringAsFixed(2)} km',
                  etiqueta: 'Distancia total',
                  color: const Color(0xFF80CBC4),
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white24,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              Expanded(
                child: _buildMetricaTile(
                  icono: Icons.speed,
                  valor: '~40 km/h',
                  etiqueta: 'Velocidad prom.',
                  color: const Color(0xFFFFCC80),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Barra de progreso decorativa
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(
                colors: [Color(0xFF4FC3F7), Color(0xFF1E88E5), Color(0xFF80CBC4)],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Consejo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, color: Colors.white54, size: 13),
              const SizedBox(width: 4),
              Text(
                'Toca el mapa nuevamente para trazar una nueva ruta',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.orangeAccent, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No se pudo calcular la ruta',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _mensajeError ?? '',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _resetear,
            child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricaTile({
    required IconData icono,
    required String valor,
    required String etiqueta,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          etiqueta,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Controles de zoom ───────────────────────────────────────────────────────

  Widget _buildZoomControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _zoomBtn(
          heroTag: 'osrm_zoom_in',
          icon: Icons.add,
          onPressed: () => _mapController.move(
            _mapController.camera.center,
            _mapController.camera.zoom + 1,
          ),
        ),
        const SizedBox(height: 8),
        _zoomBtn(
          heroTag: 'osrm_zoom_out',
          icon: Icons.remove,
          onPressed: () => _mapController.move(
            _mapController.camera.center,
            _mapController.camera.zoom - 1,
          ),
        ),
        if (_puntoInicio != null && _puntoFin != null) ...[
          const SizedBox(height: 12),
          // Botón "encuadrar toda la ruta"
          _zoomBtn(
            heroTag: 'osrm_fit',
            icon: Icons.fit_screen,
            onPressed: () {
              if (_polilinea.isNotEmpty) {
                _ajustarCamaraARuta(_polilinea);
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _zoomBtn({
    required String heroTag,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return FloatingActionButton.small(
      heroTag: heroTag,
      backgroundColor: Colors.white,
      elevation: 3,
      onPressed: onPressed,
      child: Icon(icon, color: const Color(0xFF8E24ED)),
    );
  }
}

// =============================================================================
//  Painter auxiliar para el triángulo de los marcadores
// =============================================================================
class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final paint = ui.Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter old) => old.color != color;
}
