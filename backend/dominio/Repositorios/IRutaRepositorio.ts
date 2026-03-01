// dominio/Repositorios/IRutaRepositorio.ts
import { Ruta } from "../Entidades/Ruta";

export interface IRutaRepositorio {
    guardar(ruta: Ruta): Promise<void>;
    obtenerPorId(id: string): Promise<Ruta | null>;
    obtenerTodos(): Promise<Ruta[]>;
    actualizar(ruta: Ruta): Promise<void>;
    eliminar(id: string): Promise<void>;
}
