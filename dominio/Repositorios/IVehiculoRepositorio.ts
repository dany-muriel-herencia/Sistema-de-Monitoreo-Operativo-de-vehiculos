import { Vehiculo } from "../Entidades/Vehiculo";

export interface IVehiculoRepositorio {
    guardar(vehiculo: Vehiculo): Promise<void>;
    obtenerPorPlaca(placa: string): Promise<Vehiculo | null>;
    obtenerTodos(): Promise<Vehiculo[]>;
    actualizar(vehiculo: Vehiculo): Promise<void>;
    eliminar(placa: string): Promise<void>;
}
