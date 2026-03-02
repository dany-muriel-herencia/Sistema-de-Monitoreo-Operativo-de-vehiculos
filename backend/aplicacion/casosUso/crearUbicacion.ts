// aplicacion/casosUso/crearUbicacion.ts
import { IUbicacionRepositorio } from "../../dominio/Repositorios/IUbicacionRepositorio";
import { IAlertaRutaRepositorio } from "../../dominio/Repositorios/IAlertaRutaRepositorio";
import { IEventoOperacionRepositorio } from "../../dominio/Repositorios/IEventoOperacionRepositorio";
import { IViajeRepositorio } from "../../dominio/Repositorios/IViajeRepositorio";
import { UbicacionGPS } from "../../dominio/Entidades/UbicacionGPS";
import { UbicacionDTO } from "../dtos/UbicacionDTO";
import { TipoAlerta } from "../../dominio/emuns/TipoAlerta";
import { TipoEvento } from "../../dominio/emuns/TipoEvento";

// Umbral de velocidad para disparar alerta automática (km/h)
const VELOCIDAD_MAXIMA_PERMITIDA = 80;

export class CrearUbicacion {
    constructor(
        private ubicacionRepo: IUbicacionRepositorio,
        private alertaRepo?: IAlertaRutaRepositorio,
        private eventoRepo?: IEventoOperacionRepositorio,
        private viajeRepo?: IViajeRepositorio
    ) { }

    async ejecutar(datos: UbicacionDTO): Promise<void> {
        const nuevaUbicacion = new UbicacionGPS(
            datos.idviaje,
            datos.latitud,
            datos.longitud,
            new Date(),
            datos.velocidad || 0
        );

        await this.ubicacionRepo.guardar(nuevaUbicacion);
        console.log(`[GPS] Ubicación registrada para viaje ${datos.idviaje} — ${datos.latitud},${datos.longitud} @ ${datos.velocidad?.toFixed(1)} km/h`);

        // ── DETECCIÓN AUTOMÁTICA DE ALERTAS ──────────────────────────────────
        await this._detectarAlertas(datos);
    }

    private async _detectarAlertas(datos: UbicacionDTO): Promise<void> {
        // Solo podemos generar alertas si tenemos los repos necesarios
        if (!this.alertaRepo || !this.eventoRepo || !this.viajeRepo) return;

        const velocidad = datos.velocidad ?? 0;

        // 1. EXCESO DE VELOCIDAD
        if (velocidad > VELOCIDAD_MAXIMA_PERMITIDA) {
            try {
                const viaje = await this.viajeRepo.obtenerPorId(datos.idviaje);
                if (viaje) {
                    const { evento, alerta } = viaje.registrarIncidencia(
                        TipoEvento.EXCESO_VELOCIDAD,
                        TipoAlerta.EXCESO_VELOCIDAD,
                        `Velocidad registrada: ${velocidad.toFixed(1)} km/h (límite: ${VELOCIDAD_MAXIMA_PERMITIDA} km/h)`
                    );
                    await this.alertaRepo.guardar(alerta, datos.idviaje);
                    await this.eventoRepo.guardar(evento, datos.idviaje);
                    console.warn(`[ALERTA] EXCESO_VELOCIDAD en viaje ${datos.idviaje}: ${velocidad.toFixed(1)} km/h`);
                }
            } catch (err) {
                // No fallar la ubicación si la alerta falla
                console.error('[ALERTA] Error al guardar alerta de velocidad:', err);
            }
        }

        // 2. PÉRDIDA DE GPS (velocidad = 0 y datos extraños) — extendible en el futuro
        // 3. Más reglas de negocio pueden añadirse aquí...
    }
}
