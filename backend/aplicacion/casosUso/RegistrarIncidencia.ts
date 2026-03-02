// aplicacion/casosUso/RegistrarIncidencia.ts
import { IViajeRepositorio } from "../../dominio/Repositorios/IViajeRepositorio";
import { IAlertaRutaRepositorio } from "../../dominio/Repositorios/IAlertaRutaRepositorio";
import { IEventoOperacionRepositorio } from "../../dominio/Repositorios/IEventoOperacionRepositorio";
import { TipoAlerta } from "../../dominio/emuns/TipoAlerta";
import { TipoEvento } from "../../dominio/emuns/TipoEvento";

export interface IncidenciaDTO {
    idViaje: string;
    tipoAlerta: TipoAlerta;
    tipoEvento: TipoEvento;
    descripcion: string;
}

export class RegistrarIncidencia {
    constructor(
        private viajeRepo: IViajeRepositorio,
        private alertaRepo: IAlertaRutaRepositorio,
        private eventoRepo: IEventoOperacionRepositorio
    ) { }

    async ejecutar(datos: IncidenciaDTO): Promise<void> {
        const viaje = await this.viajeRepo.obtenerPorId(datos.idViaje);
        if (!viaje) throw new Error(`Viaje ${datos.idViaje} no encontrado`);

        // Usa los métodos del dominio que ya generan el evento + alerta juntos
        const { evento, alerta } = viaje.registrarIncidencia(
            datos.tipoEvento,
            datos.tipoAlerta,
            datos.descripcion
        );

        // Persistir en BD
        await this.alertaRepo.guardar(alerta, datos.idViaje);
        await this.eventoRepo.guardar(evento, datos.idViaje);

        console.log(`[Incidencia] Viaje ${datos.idViaje} — ${datos.tipoAlerta}: ${datos.descripcion}`);
    }
}
