// infraestructura/repositorios/AlertaRutaRepositorio.ts
import { IAlertaRutaRepositorio } from "../../dominio/Repositorios/IAlertaRutaRepositorio";
import { AlertaRuta } from "../../dominio/Entidades/AlertaRuta";
import { TipoAlerta } from "../../dominio/emuns/TipoAlerta";
import { pool } from "../../db";

export class AlertaRutaRepositorio implements IAlertaRutaRepositorio {

    // ─── Mapea una fila de BD → instancia AlertaRuta ──────────────────────────
    private mapearFila(row: any): AlertaRuta {
        return new AlertaRuta(
            row.id.toString(),
            row.tipo_nombre as TipoAlerta,
            row.mensaje ?? '',
            new Date(row.timestamp),
            Boolean(row.resuelta)
        );
    }

    // ─── Guardar una alerta asociada a un viaje ───────────────────────────────
    async guardar(alerta: AlertaRuta, idViaje: string): Promise<void> {
        const [tipoResult]: any = await pool.query(
            'SELECT id FROM tipo_alerta WHERE nombre = ?',
            [alerta.getTipo()]
        );
        const tipoId = tipoResult[0]?.id;
        if (!tipoId) throw new Error(`TipoAlerta desconocido: ${alerta.getTipo()}`);

        await pool.query(
            `INSERT INTO alertas_ruta (viaje_id, tipo_alerta_id, timestamp, mensaje, resuelta)
             VALUES (?, ?, ?, ?, ?)`,
            [
                idViaje,
                tipoId,
                alerta.getTimestamp(),
                alerta.getDescripcion(),
                alerta.estaResuelta()
            ]
        );
    }

    // ─── Todas las alertas de un viaje ────────────────────────────────────────
    async obtenerPorViaje(idViaje: string): Promise<AlertaRuta[]> {
        const [rows]: any = await pool.query(
            `SELECT ar.*, ta.nombre AS tipo_nombre
             FROM alertas_ruta ar
             JOIN tipo_alerta ta ON ar.tipo_alerta_id = ta.id
             WHERE ar.viaje_id = ?
             ORDER BY ar.timestamp ASC`,
            [idViaje]
        );
        return rows.map((row: any) => this.mapearFila(row));
    }

    // ─── Solo las alertas NO resueltas de un viaje ────────────────────────────
    async obtenerPendientes(idViaje: string): Promise<AlertaRuta[]> {
        const [rows]: any = await pool.query(
            `SELECT ar.*, ta.nombre AS tipo_nombre
             FROM alertas_ruta ar
             JOIN tipo_alerta ta ON ar.tipo_alerta_id = ta.id
             WHERE ar.viaje_id = ? AND ar.resuelta = FALSE
             ORDER BY ar.timestamp ASC`,
            [idViaje]
        );
        return rows.map((row: any) => this.mapearFila(row));
    }

    // ─── Marcar una alerta como resuelta ─────────────────────────────────────
    async marcarResuelta(id: string): Promise<void> {
        await pool.query(
            'UPDATE alertas_ruta SET resuelta = TRUE WHERE id = ?',
            [id]
        );
    }
}
