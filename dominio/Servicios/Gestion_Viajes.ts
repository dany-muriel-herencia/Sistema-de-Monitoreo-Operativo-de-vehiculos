import { Viaje } from "../Entidades/Viaje";
import { Vehiculo } from "../Entidades/Vehiculo";
import { Conductor } from "../Entidades/Conductor";
import { IViajeRepositorio } from "../Repositorios/IViajeRepositorio";

export class Gestion_Viajes {
    constructor(private repository: IViajeRepositorio) { }

    /**
     * Planifica un nuevo viaje asignando un conductor y un vehículo.
     */
    async planificarViaje(id: string, conductor: Conductor, vehiculo: Vehiculo, idRuta: string): Promise<Viaje> {
        if (!conductor.isDisponible()) {
            throw new Error("El conductor no está disponible.");
        }
        if (!vehiculo.estaDisponible()) {
            throw new Error("El vehículo no está disponible.");
        }

        const nuevoViaje = new Viaje(id, conductor.getId(), vehiculo.getid(), idRuta);
        await this.repository.guardar(nuevoViaje);

        console.log(`Viaje ${id} planificado con éxito.`);
        return nuevoViaje;
    }

    /**
     * Inicia un viaje planificado.
     */
    async iniciarViaje(idViaje: string, conductor: Conductor): Promise<void> {
        const viaje = await this.repository.obtenerPorId(idViaje);
        if (!viaje) throw new Error("Viaje no encontrado.");

        conductor.aceptarviaje(viaje);
        await this.repository.actualizarEstado(idViaje, viaje.getEstado());

        console.log(`Viaje ${idViaje} iniciado por el conductor ${conductor.getNombre()}.`);
    }

    /**
     * Finaliza un viaje en curso.
     */
    async finalizarViaje(idViaje: string, conductor: Conductor, vehiculo: Vehiculo, kmFinales: number): Promise<void> {
        const viaje = await this.repository.obtenerPorId(idViaje);
        if (!viaje) throw new Error("Viaje no encontrado.");

        conductor.finalizarviaje(viaje);

        // Actualizar kilometraje del vehículo
        const kmRecorridos = kmFinales - vehiculo.getkilometraje();
        if (kmRecorridos > 0) {
            vehiculo.actualizarKilometraje(kmRecorridos);
        }

        await this.repository.actualizarEstado(idViaje, viaje.getEstado());

        console.log(`Viaje ${idViaje} finalizado. Kilómetros recorridos: ${kmRecorridos}.`);
    }

    /**
     * Obtiene todos los viajes en curso.
     */
    async listarViajesEnCurso(): Promise<Viaje[]> {
        return await this.repository.listarEnCurso();
    }

    /**
     * Obtiene el historial de viajes de un conductor.
     */
    async historialPorConductor(idConductor: string): Promise<Viaje[]> {
        return await this.repository.obtenerHistorialConductor(idConductor);
    }
}
