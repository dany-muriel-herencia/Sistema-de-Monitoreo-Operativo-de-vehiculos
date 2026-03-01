import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/viaje_provider.dart';
// import '../../providers/location_provider.dart'; // Mantener si se usa después
import 'trip_control.dart';

class DriverDashboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viajeState = ref.watch(viajeProvider);
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Panel Conductor'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(child: Text(authState.user?.nombre ?? '')),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await authNotifier.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: viajeState.isLoading
          ? Center(child: CircularProgressIndicator())
          : viajeState.viajeActual != null
              ? TripControl(viaje: viajeState.viajeActual!)
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('No tienes un viaje asignado.'),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(viajeProvider.notifier).cargarViaje();
                        },
                        child: Text('Actualizar'),
                      ),
                    ],
                  ),
                ),
    );
  }
}