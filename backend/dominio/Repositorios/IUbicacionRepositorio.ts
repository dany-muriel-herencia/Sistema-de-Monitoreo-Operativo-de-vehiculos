import { UbicacionGPS } from "../Entidades/UbicacionGPS";

export interface IUbicacionRepositorio {
    guardar(ubicacion: UbicacionGPS): Promise<void>;
    obtenerPorViaje(idViaje: string): Promise<UbicacionGPS[]>;
    obtenerUltimaPorViaje(idViaje: string): Promise<UbicacionGPS | null>;
}
