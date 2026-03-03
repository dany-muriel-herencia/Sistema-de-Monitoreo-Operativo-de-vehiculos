import { IViajeRepositorio } from "../../dominio/Repositorios/IViajeRepositorio";
import { IUbicacionRepositorio } from "../../dominio/Repositorios/IUbicacionRepositorio";
import { IConductorRepositorio } from "../../dominio/Repositorios/IConductorRepositorio";
import { IRutaRepositorio } from "../../dominio/Repositorios/IRutaRepositorio";

export class MonitoreoRealTime {
    constructor(
        private viajeRepo: IViajeRepositorio,
        private ubicacionRepo: IUbicacionRepositorio,
        private conductorRepo: IConductorRepositorio,
        private rutaRepo: IRutaRepositorio
    ) { }

    async ejecutar() {
        const viajesActivos = await this.viajeRepo.listarEnCurso();

        const monitoreo = await Promise.all(viajesActivos.map(async (viaje: any) => {
            const idViaje = typeof viaje.getId === 'function' ? viaje.getId() : viaje.id;
            const conductorId = typeof viaje.getIdConductor === 'function' ? viaje.getIdConductor() : viaje.conductor_id;
            const placa = typeof viaje.getIdVehiculo === 'function' ? viaje.getIdVehiculo() : viaje.vehiculo_id;

            const [ultimaUbicacion, conductor, ruta] = await Promise.all([
                this.ubicacionRepo.obtenerUltimaPorViaje(idViaje),
                this.conductorRepo.obtenerPorId(conductorId),
                viaje.getIdRuta ? this.rutaRepo.obtenerPorId(viaje.getIdRuta()) : null
            ]);

            let proximaParada = null;
            if (ruta && ultimaUbicacion) {
                const punto = ruta.obtenerSiguienteUbicacion(ultimaUbicacion);
                if (punto) {
                    proximaParada = punto.getDescripcion();
                }
            }

            return {
                idViaje,
                conductor: conductor ? conductor.getNombre() : "Desconocido",
                placa,
                ruta: ruta ? ruta.getNombre() : "Sin ruta",
                proximaParada: proximaParada || "Llegando a destino / Final",
                estado: typeof viaje.getEstado === 'function' ? viaje.getEstado() : viaje.estado,
                ultimaUbicacion: ultimaUbicacion ? {
                    latitud: ultimaUbicacion.getLatitud(),
                    longitud: ultimaUbicacion.getLongitud(),
                    velocidad: ultimaUbicacion.getVelocidad(),
                    timestamp: ultimaUbicacion.getFechaHora()
                } : null
            };
        }));

        return monitoreo;
    }
}
