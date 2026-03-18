import 'dart:async';
import 'package:flutter/material.dart';
import '../models/conductor.dart';
import '../models/vehiculo.dart';
import '../models/viaje.dart';
import '../services/conductor_service.dart';
import '../services/vehiculo_service.dart';
import '../services/viaje_service.dart';
import '../services/reporte_service.dart';
import '../widgets/add_conductor_dialog.dart';
import '../widgets/add_vehiculo_dialog.dart';
import '../widgets/asignar_vehiculo_dialog.dart';
import '../screens/admin/monitoreo_mapa_screen.dart';
import '../screens/admin/crear_ruta_mapa_screen.dart';
import '../screens/admin/planificador_ruta_osrm_screen.dart';
import '../models/ruta.dart';
import '../services/ruta_service.dart';
import '../widgets/rutas_overview_mapa_widget.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _conductorService = ConductorService();
  final _vehiculoService = VehiculoService();
  final _viajeService = ViajeService();
  final _reporteService = ReporteService();
  final _rutaService = RutaService();

  late Future<List<Conductor>> _conductoresFuture;
  late Future<List<Vehiculo>> _vehiculosFuture;
  late Future<List<Viaje>> _viajesFuture;
  late Future<List<Ruta>> _rutasFuture;
  late Future<List<dynamic>> _monitoreoFuture;
  late Future<Map<String, dynamic>> _reportesFuture;

  // Timer para actualización en tiempo real del monitoreo
  Timer? _monitoreoTimer;

  // Ruta seleccionada en la vista general
  String? _selectedRutaId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      setState(() {});
      // Activa/desactiva el timer según la pestaña activa
      if (_tabController.index == 4) {
        _startMonitoreoTimer();
      } else {
        _monitoreoTimer?.cancel();
      }
    });
    _refreshAll();
  }

  void _startMonitoreoTimer() {
    _monitoreoTimer?.cancel();
    _monitoreoTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      setState(() {
        _monitoreoFuture = _viajeService.obtenerMonitoreo();
      });
    });
  }

  @override
  void dispose() {
    _monitoreoTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _refreshAll() {
    setState(() {
      _conductoresFuture = _conductorService.obtenerConductores();
      _vehiculosFuture = _vehiculoService.obtenerVehiculos();
      _viajesFuture = _viajeService.obtenerViajes();
      _rutasFuture = _rutaService.obtenerRutas();
      _monitoreoFuture = _viajeService.obtenerMonitoreo();

      _reportesFuture = _reporteService.obtenerResumenGeneral();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(180),
        child: Container(
          padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
          decoration: const BoxDecoration(
            color: Color(0xFF8E24ED),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.menu, color: Colors.white),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    tooltip: 'Cerrar sesión',
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Panel de Control',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Resumen operativo de la flota',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(color: const Color(0xFF8E24ED)),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildConductorList(),
                  _buildVehiculoList(),
                  _buildRutaList(),
                  _buildViajeList(),
                  _buildMonitoreoList(),
                  _buildReportesView(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: _tabController.index,
            onTap: (index) => _tabController.animateTo(index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF8E24ED),
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Personal'),
              BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Flota'),
              BottomNavigationBarItem(icon: Icon(Icons.route), label: 'Rutas'),
              BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Planes'),
              BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'Vivo'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Info'),
            ],
          ),
        ),
      ),
      floatingActionButton: (_tabController.index >= 4)
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                bool? result;

                if (_tabController.index == 2) {
                  // Rutas: abrir pantalla del mapa para dibujar
                  result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CrearRutaMapaScreen(),
                    ),
                  );
                } else {
                  // Conductores, Vehículos, Viajes: dialog normal
                  Widget dialog;
                  if (_tabController.index == 0) {
                    dialog = const AddConductorDialog();
                  } else if (_tabController.index == 1) {
                    dialog = const AddVehiculoDialog();
                  } else {
                    dialog = const AsignarVehiculoDialog();
                  }
                  result = await showDialog<bool>(
                    context: context,
                    builder: (context) => dialog,
                  );
                }
                if (result == true) _refreshAll();
              },
              label: Text(_getActionLabel()),
              icon: const Icon(Icons.add),
              backgroundColor: const Color(0xFF8E24ED),
              foregroundColor: Colors.white,
            ),
    );
  }

  String _getActionLabel() {
    if (_tabController.index == 0) return 'Nuevo Conductor';
    if (_tabController.index == 1) return 'Nuevo Vehículo';
    if (_tabController.index == 2) return 'Nueva Ruta';
    return 'Asignar / Planificar';
  }

  Widget _buildPanel({required Widget child, EdgeInsetsGeometry? margin}) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // --- MÉTODOS DE CONSTRUCCIÓN DE LISTAS (Conductores, Vehículos, Viajes, Monitoreo igual que antes) ---

  Widget _buildConductorList() {
    return FutureBuilder<List<Conductor>>(
      future: _conductoresFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return _buildError(snapshot.error.toString());
        final items = snapshot.data ?? [];
        if (items.isEmpty)
          return const Center(child: Text('No hay registros.'));

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildPanel(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: item.disponible
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  child: Icon(
                    Icons.person,
                    color: item.disponible ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(item.nombre),
                subtitle: Text('ID: ${item.id}\nLicencia: ${item.licencia}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) =>
                              AddConductorDialog(conductor: item),
                        );
                        if (result == true) _refreshAll();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeleteConductor(item),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVehiculoList() {
    return FutureBuilder<List<Vehiculo>>(
      future: _vehiculosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return _buildError(snapshot.error.toString());
        final items = snapshot.data ?? [];
        if (items.isEmpty)
          return const Center(child: Text('No hay registros.'));

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            bool available = item.estado.toUpperCase() == 'DISPONIBLE';
            return _buildPanel(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: available
                      ? Colors.blue.shade100
                      : Colors.orange.shade100,
                  child: Icon(
                    Icons.directions_car,
                    color: available ? Colors.blue : Colors.orange,
                  ),
                ),
                title: Text('${item.marca} ${item.modelo}'),
                subtitle: Text('Placa: ${item.placa}\nEstado: ${item.estado}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) =>
                              AddVehiculoDialog(vehiculo: item),
                        );
                        if (result == true) _refreshAll();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeleteVehiculo(item),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRutaList() {
    return FutureBuilder<List<Ruta>>(
      future: _rutasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return _buildError(snapshot.error.toString());
        final items = snapshot.data ?? [];
        if (items.isEmpty)
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.route, size: 64, color: Colors.grey),
                const SizedBox(height: 12),
                const Text(
                  'No hay rutas creadas.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CrearRutaMapaScreen(),
                      ),
                    );
                    if (result == true) _refreshAll();
                  },
                  icon: const Icon(Icons.add_location_alt),
                  label: const Text('Crear primera ruta'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PlanificadorRutaOsrmScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.alt_route, color: Color(0xFF1565C0)),
                  label: const Text(
                    'Planificar con OSRM',
                    style: TextStyle(color: Color(0xFF1565C0)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1565C0)),
                  ),
                ),
              ],
            ),
          );

        return Column(
          children: [
            // Botón planificador OSRM
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PlanificadorRutaOsrmScreen(),
                  ),
                ),
                icon: const Icon(Icons.alt_route),
                label: const Text('Planificador de Ruta OSRM  (ETA + calles reales)'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            // Mapa con todas las rutas
            Container(
              height: 250,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              child: RutasOverviewMapaWidget(rutas: items, selectedRutaId: _selectedRutaId),
            ),
            
            // Lista de rutas debajo
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final routeColor = _generateColor(item.id);
                  return _buildPanel(
                    child: ListTile(
                      onTap: () {
                        setState(() {
                          _selectedRutaId = item.id;
                        });
                      },
                      selected: _selectedRutaId == item.id,
                      selectedTileColor: routeColor.withValues(alpha: 0.1),
                      leading: CircleAvatar(
                        backgroundColor: routeColor.withValues(alpha: 0.1),
                        child: Icon(Icons.route, color: routeColor),
                      ),
                      title: Text(
                        item.nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${item.distanciaTotal.toStringAsFixed(1)} km  •  ${item.duracionEstimadaMinutos} min',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () async {
                              final result = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CrearRutaMapaScreen(rutaExistente: item),
                                ),
                              );
                              if (result == true) _refreshAll();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDeleteRuta(item),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildViajeList() {
    return FutureBuilder<List<Viaje>>(
      future: _viajesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return _buildError(snapshot.error.toString());
        final items = snapshot.data ?? [];
        if (items.isEmpty)
          return const Center(child: Text('No hay viajes planificados.'));

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildPanel(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.map)),
                title: Text('Viaje #${item.id}'),
                subtitle: Text(
                  'Estado: ${item.estado}\nConductor: ${item.conductorId}\nVehículo: ${item.vehiculoId}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.estado == 'PLANIFICADO')
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          final result = await showDialog<bool>(
                            context: context,
                            builder: (context) =>
                                AsignarVehiculoDialog(viaje: item),
                          );
                          if (result == true) _refreshAll();
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeleteViaje(item),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMonitoreoList() {
    return FutureBuilder<List<dynamic>>(
      future: _monitoreoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return _buildError(snapshot.error.toString());
        final items = snapshot.data ?? [];
        if (items.isEmpty)
          return const Center(
            child: Text('No hay viajes activos en este momento.'),
          );

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MonitoreoMapaScreen(monitoreoData: items),
                    ),
                  );
                },
                icon: const Icon(Icons.map_outlined),
                label: const Text('Ver todos en el Mapa'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final ubicacion = item['ultimaUbicacion'];

                  return _buildPanel(
                    child: ExpansionTile(
                      leading: const Icon(
                        Icons.satellite_alt,
                        color: Colors.blue,
                      ),
                      title: Text('Vehículo: ${item['placa']}'),
                      subtitle: Text('Conductor: ${item['conductor']}'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (ubicacion != null) ...[
                                Text('Latitud: ${ubicacion['latitud']}'),
                                Text('Longitud: ${ubicacion['longitud']}'),
                                Text(
                                  'Velocidad: ${ubicacion['velocidad']} km/h',
                                ),
                                Text(
                                  'Último reporte: ${ubicacion['timestamp']}',
                                ),
                              ] else
                                const Text(
                                  'Esperando primer reporte de GPS...',
                                  style: TextStyle(color: Colors.orange),
                                ),
                              const SizedBox(height: 8),
                              Text('ID Viaje: ${item['idViaje']}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportesView() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _reportesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return _buildError(snapshot.error.toString());

        final data = snapshot.data!;
        final stats = data['estadisticas'];
        final ranking = data['rankingConductores'] as List;
        final recientes = data['viajesRecientes'] as List;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPanel(
                margin: const EdgeInsets.only(bottom: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 140,
                        width: double.infinity,
                        child: Image.asset(
                          'assets/dashboard_bg.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: const Color(0xFF0B5563)),
                        ),
                      ),
                      Container(
                        height: 140,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Color(0xBB082E38), Color(0x33082E38)],
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.bottomLeft,
                        child: const Text(
                          'Vision general de la flota',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Text(
                'Resumen de Flota',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  _buildStatCard(
                    'Total Viajes',
                    stats['totalViajes'].toString(),
                    Icons.history,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'En Ruta',
                    stats['vehiculosEnRuta'].toString(),
                    Icons.local_shipping,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    'KM Totales',
                    stats['kilometrajeFlota'].toString(),
                    Icons.speed,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Conductores',
                    stats['totalConductores'].toString(),
                    Icons.people,
                    Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Top 5 Conductores',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildPanel(
                child: Column(
                  children: ranking
                      .map<Widget>(
                        (c) => ListTile(
                          leading: const Icon(Icons.star, color: Colors.amber),
                          title: Text(c['nombre']),
                          trailing: Text(
                            '${c['viajes']} viajes',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Recientes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildPanel(
                child: Column(
                  children: recientes
                      .map<Widget>(
                        (v) => ListTile(
                          title: Text('Viaje #${v['id']} - ${v['placa']}'),
                          subtitle: Text('Estado: ${v['estado']}'),
                          trailing: Text(
                            v['fecha']?.toString().split('T')[0] ?? '',
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final url = _reporteService.getExportUrl();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Descargando reporte desde: $url'),
                      ),
                    );
                    // Como estamos en web, lo más sencillo es abrir la URL en otra pestaña
                    // El navegador detectará que es un attachment y lo descargará.
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Exportar Resumen a CSV'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      color: color.withOpacity(0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Color _generateColor(String id) {
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
      Colors.amber,
    ];
    int hash = 0;
    for (int i = 0; i < id.length; i++) {
      hash = id.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return colors[hash.abs() % colors.length];
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error de conexión con el backend: $error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshAll,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteConductor(Conductor item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar'),
        content: Text('¿Eliminar a ${item.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _conductorService.eliminarConductor(item.id);
                _refreshAll();
              } catch (e) {
                _showErrorSnackBar(e.toString());
              }
            },
            child: const Text(
              'Sí, eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteVehiculo(Vehiculo item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar'),
        content: Text('¿Eliminar vehículo ${item.placa}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _vehiculoService.eliminarVehiculo(item.placa);
                _refreshAll();
              } catch (e) {
                _showErrorSnackBar(e.toString());
              }
            },
            child: const Text(
              'Sí, eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRuta(Ruta item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Ruta'),
        content: Text('¿Eliminar la ruta "${item.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _rutaService.eliminarRuta(item.id);
                _refreshAll();
              } catch (e) {
                _showErrorSnackBar(e.toString());
              }
            },
            child: const Text(
              'Sí, eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteViaje(Viaje item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Viaje'),
        content: Text('¿Eliminar el viaje #${item.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _viajeService.eliminarViaje(item.id);
                _refreshAll();
              } catch (e) {
                _showErrorSnackBar(e.toString());
              }
            },
            child: const Text(
              'Sí, eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
