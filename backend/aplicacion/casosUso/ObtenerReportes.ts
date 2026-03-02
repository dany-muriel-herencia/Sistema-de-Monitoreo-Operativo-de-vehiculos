import { IViajeRepositorio } from "../../dominio/Repositorios/IViajeRepositorio";
import { IVehiculoRepositorio } from "../../dominio/Repositorios/IVehiculoRepositorio";
import { IConductorRepositorio } from "../../dominio/Repositorios/IConductorRepositorio";
import { EstadoVehiculo } from "../../dominio/emuns/EstadoVehiculo";

export class ObtenerReportes {
    constructor(
        private viajeRepo: IViajeRepositorio,
        private vehiculoRepo: IVehiculoRepositorio,
        private conductorRepo: IConductorRepositorio
    ) { }

    async resumenGeneral() {
        const [viajes, vehiculos, conductores] = await Promise.all([
            this.viajeRepo.obtenerTodos(),
            this.vehiculoRepo.obtenerTodos(),
            this.conductorRepo.obtenerTodos()
        ]);

        const totalViajes = viajes.length;
        const viajesFinalizados = viajes.filter((v: any) => v.estado === 'FINALIZADO').length;
        const flotaActiva = vehiculos.filter(v => v.getEstado() === EstadoVehiculo.EN_RUTA).length;

        // Calcular kilómetros totales (si tenemos esa data en el historial o vehiculos)
        const kmTotales = vehiculos.reduce((acc, v) => acc + v.getKilometraje(), 0);

        // Ranking de conductores (quien tiene más viajes)
        const rankingConductores = conductores.map(c => {
            const numViajes = viajes.filter((v: any) => {
                const cId = typeof v.getIdConductor === 'function' ? v.getIdConductor() : v.conductor_id;
                return cId == c.getId();
            }).length;
            return {
                nombre: c.getNombre(),
                viajes: numViajes
            };
        }).sort((a, b) => b.viajes - a.viajes).slice(0, 5);

        return {
            estadisticas: {
                totalViajes,
                viajesFinalizados,
                vehiculosEnRuta: flotaActiva,
                kilometrajeFlota: kmTotales,
                totalConductores: conductores.length
            },
            rankingConductores,
            viajesRecientes: viajes.slice(0, 10).map((v: any) => ({
                id: typeof v.getId === 'function' ? v.getId() : v.id,
                fecha: typeof v.getFechaInicio === 'function' ? v.getFechaInicio() : v.fecha_hora_inicio,
                estado: typeof v.getEstado === 'function' ? v.getEstado() : v.estado,
                placa: typeof v.getIdVehiculo === 'function' ? v.getIdVehiculo() : v.vehiculo_id
            }))
        };
    }

    async exportarCSV(): Promise<string> {
        const viajes = await this.viajeRepo.obtenerTodos();
        let csv = "ID,Fecha,Estado,Vehiculo,Conductor\n";

        viajes.forEach((v: any) => {
            const id = typeof v.getId === 'function' ? v.getId() : v.id;
            const fecha = typeof v.getFechaInicio === 'function' ? v.getFechaInicio() : v.fecha_hora_inicio;
            const estado = typeof v.getEstado === 'function' ? v.getEstado() : v.estado;
            const vehiculo = typeof v.getIdVehiculo === 'function' ? v.getIdVehiculo() : v.vehiculo_id;
            const conductor = typeof v.getIdConductor === 'function' ? v.getIdConductor() : v.conductor_id;

            csv += `${id},${fecha},${estado},${vehiculo},${conductor}\n`;
        });

        return csv;
    }
}
