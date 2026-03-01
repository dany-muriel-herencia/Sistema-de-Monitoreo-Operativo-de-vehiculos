// infraestructura/repositorios/EventoOperacionRepositorio.ts
import { IEventoOperacionRepositorio } from "../../dominio/Repositorios/IEventoOperacionRepositorio";
import { EventoOperacion } from "../../dominio/Entidades/EventoOperacion";
import { TipoEvento } from "../../dominio/emuns/TipoEvento";
import { pool } from "../../db";

export class EventoOperacionRepositorio implements IEventoOperacionRepositorio {

    // ─── Mapea una fila de BD → instancia EventoOperacion ────────────────────
    private mapearFila(row: any): EventoOperacion {
        return new EventoOperacion(
            row.id.toString(),
            new Date(row.timestamp),
            row.tipo_nombre as TipoEvento,
            row.descripcion ?? ''
        );
    }

    // ─── Guardar un evento asociado a un viaje ────────────────────────────────
    async guardar(evento: EventoOperacion, idViaje: string): Promise<void> {
        const [tipoResult]: any = await pool.query(
            'SELECT id FROM tipo_evento WHERE nombre = ?',
            [evento.getTipo()]
        );
        const tipoId = tipoResult[0]?.id;
        if (!tipoId) throw new Error(`TipoEvento desconocido: ${evento.getTipo()}`);

        await pool.query(
            `INSERT INTO eventos_operacion (viaje_id, timestamp, tipo_evento_id, descripcion)
             VALUES (?, ?, ?, ?)`,
            [
                idViaje,
                evento.getTimestamp(),
                tipoId,
                evento.getDescripcion()
            ]
        );
    }

    // ─── Todos los eventos de un viaje en orden cronológico ───────────────────
    async obtenerPorViaje(idViaje: string): Promise<EventoOperacion[]> {
        const [rows]: any = await pool.query(
            `SELECT eo.*, te.nombre AS tipo_nombre
             FROM eventos_operacion eo
             JOIN tipo_evento te ON eo.tipo_evento_id = te.id
             WHERE eo.viaje_id = ?
             ORDER BY eo.timestamp ASC`,
            [idViaje]
        );
        return rows.map((row: any) => this.mapearFila(row));
    }
}
