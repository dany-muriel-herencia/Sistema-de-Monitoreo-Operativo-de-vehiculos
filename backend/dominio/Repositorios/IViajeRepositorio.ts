import { Viaje } from "../Entidades/Viaje";

export interface IViajeRepositorio {
    guardar(viaje: Viaje): Promise<void>;
    obtenerPorId(id: string): Promise<Viaje | null>;
    obtenerTodos(): Promise<Viaje[]>;
    actualizarEstado(id: string, nuevoEstado: string): Promise<void>;
    listarEnCurso(): Promise<Viaje[]>;
    obtenerHistorialConductor(idConductor: string): Promise<Viaje[]>;
}
