import { Conductor } from "../Entidades/Conductor";

export interface IConductorRepositorio {
    guardar(conductor: Conductor): Promise<void>;
    obtenerPorId(id: string): Promise<Conductor | null>;
    obtenerTodos(): Promise<Conductor[]>;
    actualizar(conductor: Conductor): Promise<void>;
    eliminar(id: string): Promise<void>;
}
