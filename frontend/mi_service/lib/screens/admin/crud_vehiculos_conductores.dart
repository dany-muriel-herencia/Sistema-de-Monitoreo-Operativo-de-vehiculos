import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_provider.dart';

class CrudVehiculosConductores extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(adminProvider);

    return DefaultTabController(
      length: 2,
      child: Card(
        margin: EdgeInsets.all(8),
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: 'Vehículos'),
                Tab(text: 'Conductores'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Lista de vehículos
                  ListView.builder(
                    itemCount: adminState.vehiculos.length,
                    itemBuilder: (context, index) {
                      final v = adminState.vehiculos[index];
                      return ListTile(
                        title: Text('${v.marca} ${v.modelo}'),
                        subtitle: Text('Placa: ${v.placa} - ${v.estado}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: Icon(Icons.edit), onPressed: () {}),
                            IconButton(icon: Icon(Icons.delete), onPressed: () {}),
                          ],
                        ),
                      );
                    },
                  ),
                  // Lista de conductores
                  ListView.builder(
                    itemCount: adminState.conductores.length,
                    itemBuilder: (context, index) {
                      final c = adminState.conductores[index];
                      return ListTile(
                        title: Text(c.nombre),
                        subtitle: Text('Licencia: ${c.licencia} - ${c.disponible ? 'Disponible' : 'No disponible'}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: Icon(Icons.edit), onPressed: () {}),
                            IconButton(icon: Icon(Icons.delete), onPressed: () {}),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}