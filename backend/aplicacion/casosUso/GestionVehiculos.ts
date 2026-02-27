import { Vehiculo } from "../Entidades/Vehiculo";
import { IVehiculoRepositorio } from "../Repositorios/IVehiculoRepositorio";

export class GestionVehiculos {
    constructor(private repository: IVehiculoRepositorio) { }


    async registrarVehiculo(vehiculo: Vehiculo): Promise<void> {
        const existe = await this.repository.obtenerPorPlaca(vehiculo.getplaca());
        if (existe) {
            throw new Error(`El vehículo con placa ${vehiculo.getplaca()} ya está registrado.`);
        }
        await this.repository.guardar(vehiculo);
        console.log(`Vehículo ${vehiculo.getplaca()} registrado con éxito.`);
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
