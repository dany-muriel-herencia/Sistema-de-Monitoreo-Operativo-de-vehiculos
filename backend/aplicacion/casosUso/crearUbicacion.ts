import { IUbicacionRepositorio } from "../../dominio/Repositorios/IUbicacionRepositorio";
import { UbicacionGPS } from "../../dominio/Entidades/UbicacionGPS";
import { UbicacionDTO } from "../dtos/UbicacionDTO";

export class CrearUbicacion {
    constructor(private ubicacionRepo: IUbicacionRepositorio) { }

    async ejecutar(datos: UbicacionDTO): Promise<void> {
        const nuevaUbicacion = new UbicacionGPS(
            datos.idviaje,
            datos.latitud,
            datos.longitud,
            new Date(),
            datos.velocidad || 0
        );

        await this.ubicacionRepo.guardar(nuevaUbicacion);

        // Aquí podrías disparar el Servicio de Monitoreo para ver si hay alertas
        console.log(`Ubicación registrada para el vehículo ${datos.idVehiculo}`);
    }
}
