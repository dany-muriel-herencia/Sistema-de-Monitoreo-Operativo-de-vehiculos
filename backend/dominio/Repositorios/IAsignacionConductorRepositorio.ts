// dominio/Repositorios/IAsignacionConductorRepositorio.ts
import { AsignacionConductor } from "../Entidades/AsignacionConductor";

export interface IAsignacionConductorRepositorio {
    guardar(asignacion: AsignacionConductor): Promise<void>;
    obtenerActivaPorConductor(idConductor: string): Promise<AsignacionConductor | null>;
    obtenerActivaPorVehiculo(idVehiculo: string): Promise<AsignacionConductor | null>;
    obtenerHistorialConductor(idConductor: string): Promise<AsignacionConductor[]>;
    finalizarAsignacion(idAsignacion: string, fechaFin: Date): Promise<void>;
}
