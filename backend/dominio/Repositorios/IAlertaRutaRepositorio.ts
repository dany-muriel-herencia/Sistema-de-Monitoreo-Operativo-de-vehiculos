// dominio/Repositorios/IAlertaRutaRepositorio.ts
import { AlertaRuta } from "../Entidades/AlertaRuta";

export interface IAlertaRutaRepositorio {
    guardar(alerta: AlertaRuta, idViaje: string): Promise<void>;
    obtenerPorViaje(idViaje: string): Promise<AlertaRuta[]>;
    obtenerPendientes(idViaje: string): Promise<AlertaRuta[]>;
    marcarResuelta(id: string): Promise<void>;
}
