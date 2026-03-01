// infraestructura/repositorios/UbicacionRepositorio.ts
import { IUbicacionRepositorio } from "../../dominio/Repositorios/IUbicacionRepositorio";
import { UbicacionGPS } from "../../dominio/Entidades/UbicacionGPS";
import { pool } from "../../db";

export class UbicacionRepositorio implements IUbicacionRepositorio {

    // ─── Mapea una fila de BD → instancia UbicacionGPS ───────────────────────
    private mapearFila(row: any): UbicacionGPS {
        return new UbicacionGPS(
            row.viaje_id.toString(),
            Number(row.latitud),
            Number(row.longitud),
            new Date(row.timestamp),
            Number(row.velocidad)
        );
    }

    // ─── Guardar una nueva ubicación GPS ─────────────────────────────────────
    async guardar(ubicacion: UbicacionGPS): Promise<void> {
        await pool.query(
            'INSERT INTO ubicaciones_gps (viaje_id, latitud, longitud, timestamp, velocidad) VALUES (?, ?, ?, ?, ?)',
            [
                ubicacion.getIdViaje(),
                ubicacion.getLatitud(),
                ubicacion.getLongitud(),
                ubicacion.getFechaHora(),
                ubicacion.getVelocidad()
            ]
        );
    }

    // ─── Obtener todas las ubicaciones de un viaje (orden cronológico) ────────
    async obtenerPorViaje(idViaje: string): Promise<UbicacionGPS[]> {
        const [rows]: any = await pool.query(
            'SELECT * FROM ubicaciones_gps WHERE viaje_id = ? ORDER BY timestamp ASC',
            [idViaje]
        );
        return rows.map((row: any) => this.mapearFila(row));
    }

    // ─── Obtener la última ubicación registrada de un viaje ───────────────────
    async obtenerUltimaPorViaje(idViaje: string): Promise<UbicacionGPS | null> {
        const [rows]: any = await pool.query(
            'SELECT * FROM ubicaciones_gps WHERE viaje_id = ? ORDER BY timestamp DESC LIMIT 1',
            [idViaje]
        );
        if (rows.length === 0) return null;
        return this.mapearFila(rows[0]);
    }
}
