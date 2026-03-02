import 'package:flutter/material.dart';
import '../models/conductor.dart';
import '../models/vehiculo.dart';
import '../models/viaje.dart';
import '../services/conductor_service.dart';
import '../services/vehiculo_service.dart';
import '../services/viaje_service.dart';
import '../widgets/add_conductor_dialog.dart';
import '../widgets/add_vehiculo_dialog.dart';
import '../widgets/asignar_vehiculo_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _conductorService = ConductorService();
  final _vehiculoService = VehiculoService();
  final _viajeService = ViajeService();

  late Future<List<Conductor>> _conductoresFuture;
  late Future<List<Vehiculo>> _vehiculosFuture;
  late Future<List<Viaje>> _viajesFuture;
  late Future<List<dynamic>> _monitoreoFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _refreshAll();
  }

  void _refreshAll() {
    setState(() {
      _conductoresFuture = _conductorService.obtenerConductores();
      _vehiculosFuture = _vehiculoService.obtenerVehiculos();
      _viajesFuture = _viajeService.obtenerViajes();
      _monitoreoFuture = _viajeService.obtenerMonitoreo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Conductores'),
            Tab(icon: Icon(Icons.directions_car), text: 'Vehículos'),
            Tab(icon: Icon(Icons.map), text: 'Viajes'),
            Tab(icon: Icon(Icons.track_changes), text: 'Monitoreo'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshAll),
          IconButton(
            icon: const Icon(Icons.logout), 
            onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConductorList(),
          _buildVehiculoList(),
          _buildViajeList(),
          _buildMonitoreoList(),
        ],
      ),
      floatingActionButton: _tabController.index == 3 ? null : FloatingActionButton.extended(
        onPressed: () async {
          Widget dialog;
          if (_tabController.index == 0) {
            dialog = const AddConductorDialog();
          } else if (_tabController.index == 1) {
            dialog = const AddVehiculoDialog();
          } else {
            dialog = const AsignarVehiculoDialog();
          }

          final result = await showDialog<bool>(
            context: context,
            builder: (context) => dialog,
          );
          if (result == true) _refreshAll();
        },
        label: Text(_getActionLabel()),
        icon: const Icon(Icons.add),
      ),
    );
  }

  String _getActionLabel() {
    if (_tabController.index == 0) return 'Nuevo Conductor';
    if (_tabController.index == 1) return 'Nuevo Vehículo';
    return 'Asignar / Planificar';
  }

  Widget _buildConductorList() {
    return FutureBuilder<List<Conductor>>(
      future: _conductoresFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return _buildError(snapshot.error.toString());
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const Center(child: Text('No hay registros.'));

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: item.disponible ? Colors.green.shade100 : Colors.red.shade100,
                  child: Icon(Icons.person, color: item.disponible ? Colors.green : Colors.red),
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
                          builder: (context) => AddConductorDialog(conductor: item),
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
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return _buildError(snapshot.error.toString());
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const Center(child: Text('No hay registros.'));

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            bool available = item.estado.toUpperCase() == 'DISPONIBLE';
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: available ? Colors.blue.shade100 : Colors.orange.shade100,
                  child: Icon(Icons.directions_car, color: available ? Colors.blue : Colors.orange),
                ),
                title: Text('${item.marca} ${item.modelo}'),
                subtitle: Text('Placa: ${item.placa}\nEstado: ${item.estado}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDeleteVehiculo(item),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildViajeList() {
    return FutureBuilder<List<Viaje>>(
      future: _viajesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return _buildError(snapshot.error.toString());
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const Center(child: Text('No hay viajes planificados.'));

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.map)),
                title: Text('Viaje #${item.id}'),
                subtitle: Text('Estado: ${item.estado}\nConductor: ${item.conductorId}\nVehículo: ${item.vehiculoId}'),
                trailing: (item.estado == 'PLANIFICADO') 
                  ? IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) => AsignarVehiculoDialog(viaje: item),
                        );
                        if (result == true) _refreshAll();
                      },
                    )
                  : null,
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
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return _buildError(snapshot.error.toString());
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const Center(child: Text('No hay viajes activos en este momento.'));

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final ubicacion = item['ultimaUbicacion'];
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ExpansionTile(
                leading: const Icon(Icons.satellite_alt, color: Colors.blue),
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
                          Text('Velocidad: ${ubicacion['velocidad']} km/h'),
                          Text('Último reporte: ${ubicacion['timestamp']}'),
                        ] else
                          const Text('Esperando primer reporte de GPS...', style: TextStyle(color: Colors.orange)),
                        const SizedBox(height: 8),
                        Text('ID Viaje: ${item['idViaje']}'),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
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
            Text('Error de conexión con el backend: $error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _refreshAll, child: const Text('Reintentar')),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
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
            child: const Text('Sí, eliminar', style: TextStyle(color: Colors.red)),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
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
            child: const Text('Sí, eliminar', style: TextStyle(color: Colors.red)),
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
