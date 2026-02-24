import { Conductor } from "../Entidades/Conductor";
import { IConductorRepositorio } from "../Repositorios/IConductorRepositorio";

export class Gestion_Conductores {
    constructor(private repository: IConductorRepositorio) { }

    async registrarConductor(conductor: Conductor): Promise<void> {
    
        await this.repository.guardar(conductor);
        console.log(`Conductor ${conductor.getNombre()} registrado con éxito.`);
    }


    async obtenerConductor(id: string): Promise<Conductor> {
        const conductor = await this.repository.obtenerPorId(id);
        if (!conductor) {
            throw new Error(`Conductor con ID ${id} no encontrado.`);
        }
        return conductor;
    }

    async listarDisponibles(): Promise<Conductor[]> {
        const todos = await this.repository.obtenerTodos();
        return todos.filter(c => c.EstadoDisponible());
    }

    async darDeBajaConductor(id: string): Promise<void> {
        await this.repository.eliminar(id);
        console.log(`Conductor con ID ${id} dado de baja.`);
    }
}