import { IViajeRepositorio } from "../../dominio/Repositorios/IViajeRepositorio";
import { IUbicacionRepositorio } from "../../dominio/Repositorios/IUbicacionRepositorio";
import { IConductorRepositorio } from "../../dominio/Repositorios/IConductorRepositorio";

export class MonitoreoRealTime {
    constructor(
        private viajeRepo: IViajeRepositorio,
        private ubicacionRepo: IUbicacionRepositorio,
        private conductorRepo: IConductorRepositorio
    ) { }

    async ejecutar() {
        const viajesActivos = await this.viajeRepo.listarEnCurso();

        const monitoreo = await Promise.all(viajesActivos.map(async (viaje: any) => {
            const idViaje = typeof viaje.getId === 'function' ? viaje.getId() : viaje.id;
            const conductorId = typeof viaje.getIdConductor === 'function' ? viaje.getIdConductor() : viaje.conductor_id;
            const placa = typeof viaje.getIdVehiculo === 'function' ? viaje.getIdVehiculo() : viaje.vehiculo_id;

            const [ultimaUbicacion, conductor] = await Promise.all([
                this.ubicacionRepo.obtenerUltimaPorViaje(idViaje),
                this.conductorRepo.obtenerPorId(conductorId)
            ]);

            return {
                idViaje,
                conductor: conductor ? conductor.getNombre() : "Desconocido",
                placa,
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
