import { IConductorRepositorio } from "../../dominio/Repositorios/IConductorRepositorio";
import { Conductor } from "../../dominio/Entidades/Conductor";

export class ObtenerConductores {
    constructor(private conductorRepo: IConductorRepositorio) {}

    async ejecutar(): Promise<Conductor[]> {
        return await this.conductorRepo.obtenerTodos();
    }

    async ejecutarPorId(id: string): Promise<Conductor | null> {
        return await this.conductorRepo.obtenerPorId(id);
    }
}
