
import 'package:flutter/material.dart';
import '../../models/alerta.dart';

class ListaAlertas extends StatelessWidget {
  final List<Alerta> alertas;
  const ListaAlertas({required this.alertas});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text('Alertas Pendientes', style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: alertas.length,
              itemBuilder: (context, index) {
                final alerta = alertas[index];
                return ListTile(
                  leading: Icon(Icons.warning, color: Colors.orange),
                  title: Text(alerta.tipo),
                  subtitle: Text('Viaje ${alerta.viajeId} - ${alerta.mensaje ?? ''}'),
                  trailing: Text(TimeOfDay.fromDateTime(alerta.timestamp).format(context)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}