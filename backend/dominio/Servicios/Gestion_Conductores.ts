import { Conductor } from "../Entidades/Conductor";
import { IConductorRepositorio } from "../Repositorios/IConductorRepositorio";

export class Gestion_Conductores {
    constructor(private repository: IConductorRepositorio) { }

    /**
     * Registra un nuevo conductor en el sistema.
     */
    async registrarConductor(conductor: Conductor): Promise<void> {
        // En una implementación real, podrías buscar por email antes de guardar
        await this.repository.guardar(conductor);
        console.log(`Conductor ${conductor.getNombre()} registrado con éxito.`);
    }

    /**
     * Busca un conductor por su ID.
     */
    async obtenerConductor(id: string): Promise<Conductor> {
        const conductor = await this.repository.obtenerPorId(id);
        if (!conductor) {
            throw new Error(`Conductor con ID ${id} no encontrado.`);
        }
        return conductor;
    }

    /**
     * Lista los conductores que están disponibles para un viaje.
     */
    async listarDisponibles(): Promise<Conductor[]> {
        const todos = await this.repository.obtenerTodos();
        return todos.filter(c => c.isDisponible());
    }

    /**
     * Elimina (o deshabilita) un conductor del sistema.
     */
    async darDeBajaConductor(id: string): Promise<void> {
        await this.repository.eliminar(id);
        console.log(`Conductor con ID ${id} dado de baja.`);
    }
}