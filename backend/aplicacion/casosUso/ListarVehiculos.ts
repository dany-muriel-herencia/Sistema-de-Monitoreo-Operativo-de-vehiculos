import { IVehiculoRepositorio } from "../../dominio/Repositorios/IVehiculoRepositorio";
import { Vehiculo } from "../../dominio/Entidades/Vehiculo";

export class ListarVehiculos {
    constructor(private vehiculoRepo: IVehiculoRepositorio) {}

    async ejecutar(): Promise<Vehiculo[]> {
        return await this.vehiculoRepo.obtenerTodos();
    }
}
