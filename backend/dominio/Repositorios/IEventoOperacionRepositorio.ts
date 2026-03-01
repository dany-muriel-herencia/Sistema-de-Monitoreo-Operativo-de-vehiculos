// dominio/Repositorios/IEventoOperacionRepositorio.ts
import { EventoOperacion } from "../Entidades/EventoOperacion";

export interface IEventoOperacionRepositorio {
    guardar(evento: EventoOperacion, idViaje: string): Promise<void>;
    obtenerPorViaje(idViaje: string): Promise<EventoOperacion[]>;
}
