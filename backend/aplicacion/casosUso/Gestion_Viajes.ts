import { Viaje } from "../Entidades/Viaje";
import { Vehiculo } from "../Entidades/Vehiculo";
import { Conductor } from "../Entidades/Conductor";
import { IViajeRepositorio } from "../Repositorios/IViajeRepositorio";

export class Gestion_Viajes {
    constructor(private repository: IViajeRepositorio) { }


    async planificarViaje(id: string, conductor: Conductor, vehiculo: Vehiculo, idRuta: string): Promise<Viaje> {
        if (!conductor.EstadoDisponible()) {
            throw new Error("El conductor no está disponible.");
        }
        if (!vehiculo.isDisponible()) {
            throw new Error("El vehículo no está disponible.");
        }
        const nuevoViaje = new Viaje(id, conductor.getId(), vehiculo.getId(), idRuta);
        await this.repository.guardar(nuevoViaje);

        console.log(`Viaje ${id} planificado con éxito.`);
        return nuevoViaje;
    }


    async iniciarViaje(idViaje: string, conductor: Conductor): Promise<void> {
        const viaje = await this.repository.obtenerPorId(idViaje);
        if (!viaje) throw new Error("Viaje no encontrado.");

        conductor.aceptarviaje(viaje);
        await this.repository.actualizarEstado(idViaje, viaje.getEstado());

        console.log(`Viaje ${idViaje} iniciado por el conductor ${conductor.getNombre()}.`);
    }

    
    async finalizarViaje(idViaje: string, conductor: Conductor, vehiculo: Vehiculo, kmFinales: number): Promise<void> {
        const viaje = await this.repository.obtenerPorId(idViaje);
        if (!viaje) throw new Error("Viaje no encontrado.");

        conductor.finalizarviaje(viaje);

        const kmRecorridos = kmFinales - vehiculo.getkilometraje();
        if (kmRecorridos > 0) {
            vehiculo.actualizarKilometraje(kmRecorridos);
        }

        await this.repository.actualizarEstado(idViaje, viaje.getEstado());

        console.log(`Viaje ${idViaje} finalizado. Kilómetros recorridos: ${kmRecorridos}.`);
    }


    async listarViajesEnCurso(): Promise<Viaje[]> {
        return await this.repository.listarEnCurso();
    }

    

    async historialPorConductor(idConductor: string): Promise<Viaje[]> {
        return await this.repository.obtenerHistorialConductor(idConductor);
    }
}
