import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/viaje.dart';
import '../../providers/viaje_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/location_service.dart';

class TripControl extends ConsumerStatefulWidget {
  final Viaje viaje;
  const TripControl({required this.viaje});

  @override
  _TripControlState createState() => _TripControlState();
}

class _TripControlState extends ConsumerState<TripControl> {
  final _kmFinalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Si el viaje ya está en curso, iniciar tracking
    if (widget.viaje.estado == 'EN_CURSO') {
      ref.read(locationProvider.notifier).startTracking(widget.viaje.id);
    }
  }

  @override
  void dispose() {
    ref.read(locationProvider.notifier).stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viajeNotifier = ref.read(viajeProvider.notifier);
    final locationState = ref.watch(locationProvider);
    final viaje = widget.viaje;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('Viaje #${viaje.id}', style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 8),
                  Text('Vehículo: ${viaje.vehiculoId}'),
                  Text('Estado: ${viaje.estado}'),
                  if (locationState.isTracking)
                    Text('Enviando ubicación...', style: TextStyle(color: Colors.green)),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          if (viaje.estado == 'PLANIFICADO')
            ElevatedButton(
              onPressed: () async {
                await viajeNotifier.iniciarViaje(viaje.id);
                ref.read(locationProvider.notifier).startTracking(viaje.id);
              },
              child: Text('INICIAR VIAJE'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          if (viaje.estado == 'EN_CURSO')
            Column(
              children: [
                TextField(
                  controller: _kmFinalController,
                  decoration: InputDecoration(labelText: 'Kilometraje final'),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    final km = double.tryParse(_kmFinalController.text);
                    await viajeNotifier.finalizarViaje(viaje.id, kmFinal: km);
                    ref.read(locationProvider.notifier).stopTracking();
                  },
                  child: Text('FINALIZAR VIAJE'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
        ],
      ),
    );
  }
}