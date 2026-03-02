import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_provider.dart';

class MapaVehiculos extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(adminProvider);
    final vehiculos = adminState.vehiculos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Estado de Vehículos (${vehiculos.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: vehiculos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('Sin vehículos registrados', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: vehiculos.length,
                  itemBuilder: (context, index) {
                    final v = vehiculos[index];
                    final color = v.estado == 'EN_RUTA'
                        ? Colors.green
                        : v.estado == 'EN_MANTENIMIENTO'
                            ? Colors.orange
                            : Colors.blue;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.15),
                          child: Icon(Icons.directions_car, color: color),
                        ),
                        title: Text('${v.marca} ${v.modelo}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Placa: ${v.placa} · ${v.anio}'),
                        trailing: Chip(
                          label: Text(v.estado,
                              style: TextStyle(color: color, fontSize: 11)),
                          backgroundColor: color.withOpacity(0.1),
                          side: BorderSide(color: color.withOpacity(0.3)),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}