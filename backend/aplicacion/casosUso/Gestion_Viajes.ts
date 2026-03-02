// aplicacion/casosUso/Gestion_Viajes.ts
import { Viaje } from "../../dominio/Entidades/Viaje";
import { Vehiculo } from "../../dominio/Entidades/Vehiculo";
import { Conductor } from "../../dominio/Entidades/Conductores";
import { IViajeRepositorio } from "../../dominio/Repositorios/IViajeRepositorio";
import { IVehiculoRepositorio } from "../../dominio/Repositorios/IVehiculoRepositorio";
import { EstadoVehiculo } from "../../dominio/emuns/EstadoVehiculo";
import { EstadoViaje } from "../../dominio/emuns/EstadoViaje";

export class Gestion_Viajes {
    constructor(
        private repository: IViajeRepositorio,
        private vehiculoRepo?: IVehiculoRepositorio  // opcional para no romper DI existente
    ) { }


    async planificarViaje(id: string, conductor: Conductor, vehiculo: Vehiculo, idRuta: string): Promise<Viaje> {
        if (!conductor.EstadoDisponible()) {
            throw new Error("El conductor no está disponible.");
        }
        if (!vehiculo.estaDisponibleParaViaje()) {
            throw new Error(`El vehículo ${vehiculo.getPlaca()} no está disponible (estado: ${vehiculo.getEstado()}).`);
        }

        const idVehiculo = vehiculo.getId()?.toString() || '';
        const nuevoViaje = new Viaje(id, conductor.getId()!.toString(), idVehiculo, idRuta);
        await this.repository.guardar(nuevoViaje);

        console.log(`[Viaje] ${id} planificado — conductor: ${conductor.getNombre()}, vehículo: ${vehiculo.getPlaca()}`);
        return nuevoViaje;
    }


    async iniciarViaje(idViaje: string, conductor: Conductor): Promise<void> {
        const viaje = await this.repository.obtenerPorId(idViaje);
        if (!viaje) throw new Error("Viaje no encontrado.");

        // Método del dominio que cambia estado a EN_CURSO y registra evento INICIO_RUTA
        conductor.aceptarviaje(viaje);
        await this.repository.actualizarEstado(idViaje, viaje.getEstado());

        // Marcar el vehículo como EN_RUTA en la BD
        if (this.vehiculoRepo) {
            try {
                const placa = viaje.getIdVehiculo(); // el repo guarda la placa
                const vehiculo = await this.vehiculoRepo.obtenerPorPlaca(placa);
                if (vehiculo) {
                    vehiculo.actualizarEstado(EstadoVehiculo.EN_RUTA);
                    await this.vehiculoRepo.actualizar(vehiculo);
                }
            } catch (e) {
                console.error('[Viaje] No se pudo actualizar estado del vehículo a EN_RUTA:', e);
            }
        }

        console.log(`[Viaje] ${idViaje} iniciado por conductor ${conductor.getNombre()}.`);
    }


    async finalizarViaje(idViaje: string, conductor: Conductor, vehiculo: Vehiculo, kmFinales: number): Promise<void> {
        const viaje = await this.repository.obtenerPorId(idViaje);
        if (!viaje) throw new Error("Viaje no encontrado.");

        // Método del dominio: cambia estado a FINALIZADO y registra evento FIN_RUTA
        conductor.finalizarviaje(viaje);

        const kmRecorridos = kmFinales - vehiculo.getKilometraje();
        if (kmRecorridos > 0) {
            vehiculo.registrarUso(kmRecorridos);
        }

        await this.repository.actualizarEstado(idViaje, viaje.getEstado());

        // Liberar el vehículo: volver a DISPONIBLE
        if (this.vehiculoRepo) {
            try {
                const placa = viaje.getIdVehiculo();
                const vehActual = await this.vehiculoRepo.obtenerPorPlaca(placa);
                if (vehActual) {
                    vehActual.actualizarEstado(EstadoVehiculo.DISPONIBLE);
                    vehActual.registrarUso(kmRecorridos > 0 ? kmRecorridos : 0);
                    await this.vehiculoRepo.actualizar(vehActual);
                }
            } catch (e) {
                console.error('[Viaje] No se pudo liberar el vehículo:', e);
            }
        }

        console.log(`[Viaje] ${idViaje} finalizado. KM recorridos: ${kmRecorridos}.`);
    }


    async cancelarViaje(idViaje: string, motivo: string): Promise<void> {
        const viaje = await this.repository.obtenerPorId(idViaje);
        if (!viaje) throw new Error("Viaje no encontrado.");

        // Sólo se puede cancelar si está PLANIFICADO
        if (viaje.getEstado() !== EstadoViaje.PLANIFICADO) {
            throw new Error(`No se puede cancelar un viaje en estado: ${viaje.getEstado()}`);
        }

        viaje.cancelar(motivo);
        await this.repository.actualizarEstado(idViaje, EstadoViaje.CANCELADO);

        console.log(`[Viaje] ${idViaje} cancelado. Motivo: ${motivo}`);
    }


    async listarTodos(): Promise<Viaje[]> {
        return await this.repository.obtenerTodos();
    }

    async listarViajesEnCurso(): Promise<Viaje[]> {
        return await this.repository.listarEnCurso();
    }

    async historialPorConductor(idConductor: string): Promise<Viaje[]> {
        return await this.repository.obtenerHistorialConductor(idConductor);
    }

    async actualizarAsignacion(idViaje: string, idConductor: string, idVehiculo: string): Promise<void> {
        const viaje = await this.repository.obtenerPorId(idViaje);
        if (!viaje) throw new Error("Viaje no encontrado");

        viaje.setIdConductor(idConductor);
        viaje.setIdVehiculo(idVehiculo);

        await this.repository.actualizar(viaje);
    }

    async eliminarViaje(id: string): Promise<void> {
        await this.repository.eliminar(id);
    }
}
