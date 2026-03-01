import { Vehiculo } from "../../dominio/Entidades/Vehiculo";
import { IVehiculoRepositorio } from "../../dominio/Repositorios/IVehiculoRepositorio";

export class GestionVehiculos {
    constructor(private repository: IVehiculoRepositorio) { }


    async registrarVehiculo(vehiculo: Vehiculo): Promise<void> {
        const existe = await this.repository.obtenerPorPlaca(vehiculo.getPlaca());
        if (existe) {
            throw new Error(`El vehículo con placa ${vehiculo.getPlaca()} ya está registrado.`);
        }
        await this.repository.guardar(vehiculo);
        console.log(`Vehículo ${vehiculo.getPlaca()} registrado con éxito.`);
    }


    async obtenerVehiculo(placa: string): Promise<Vehiculo> {
        const vehiculo = await this.repository.obtenerPorPlaca(placa);
        if (!vehiculo) {
            throw new Error(`Vehículo con placa ${placa} no encontrado.`);
        }
        return vehiculo;
    }


    async listarVehiculos(): Promise<Vehiculo[]> {
        return await this.repository.obtenerTodos();
    }


    async eliminarVehiculo(placa: string): Promise<void> {
        await this.repository.eliminar(placa);
        console.log(`Vehículo ${placa} eliminado del sistema.`);
    }
}
