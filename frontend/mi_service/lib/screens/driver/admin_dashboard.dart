import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../admin/mapa_vehiculos.dart';
import '../admin/lista_alertas.dart';
import '../admin/crud_vehiculos_conductores.dart';

class AdminDashboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(adminProvider);
    final authNotifier = ref.read(authProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Panel Administrador'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await authNotifier.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: adminState.isLoading
          ? Center(child: CircularProgressIndicator())
          : Row(
              children: [
                Expanded(flex: 2, child: MapaVehiculos()),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Expanded(child: ListaAlertas(alertas: adminState.alertas)),
                      Expanded(child: CrudVehiculosConductores()),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}