// infraestructura/repositorios/ViajeRepositorio.ts
import { IViajeRepositorio } from "../../dominio/Repositorios/IViajeRepositorio";
import { Viaje } from "../../dominio/Entidades/Viaje";
import { EstadoViaje } from "../../dominio/emuns/EstadoViaje";
import { pool } from "../../db";

export class ViajeRepositorio implements IViajeRepositorio {

    // ─── Mapea una fila de BD → instancia Viaje ──────────────────────────────
    private mapearFila(row: any): Viaje {
        return new Viaje(
            row.id.toString(),
            row.conductor_id.toString(),
            row.vehiculo_id.toString(),
            row.ruta_id.toString(),
            row.estado_nombre as EstadoViaje,        // viene del JOIN con estado_viaje
            row.fecha_hora_inicio ? new Date(row.fecha_hora_inicio) : null,
            row.fecha_hora_fin ? new Date(row.fecha_hora_fin) : null
        );
    }

    // ─── Helper: obtiene el id numérico del estado en la BD ─────────────────
    private async obtenerEstadoId(estado: EstadoViaje): Promise<number> {
        const [rows]: any = await pool.query(
            'SELECT id FROM estado_viaje WHERE nombre = ?', [estado]
        );
        if (!rows[0]) throw new Error(`EstadoViaje desconocido: ${estado}`);
        return rows[0].id;
    }

    // ─── Insertar un nuevo viaje ──────────────────────────────────────────────
    async guardar(viaje: Viaje): Promise<void> {
        const estadoId = await this.obtenerEstadoId(viaje.getEstado());
        await pool.query(
            `INSERT INTO viajes (conductor_id, vehiculo_id, ruta_id, estado_id, fecha_hora_inicio, fecha_hora_fin)
             VALUES (?, ?, ?, ?, ?, ?)`,
            [
                viaje.getIdConductor(),
                viaje.getIdVehiculo(),
                viaje.getIdRuta(),
                estadoId,
                viaje.getFechaInicio(),
                viaje.getFechaFin()
            ]
        );
    }

    // ─── Obtener viaje por ID ─────────────────────────────────────────────────
    async obtenerPorId(id: string): Promise<Viaje | null> {
        const [rows]: any = await pool.query(
            `SELECT v.*, ev.nombre AS estado_nombre
             FROM viajes v
             JOIN estado_viaje ev ON v.estado_id = ev.id
             WHERE v.id = ?`,
            [id]
        );
        if (rows.length === 0) return null;
        return this.mapearFila(rows[0]);
    }

    // ─── Obtener todos los viajes ─────────────────────────────────────────────
    async obtenerTodos(): Promise<Viaje[]> {
        const [rows]: any = await pool.query(
            `SELECT v.*, ev.nombre AS estado_nombre
             FROM viajes v
             JOIN estado_viaje ev ON v.estado_id = ev.id
             ORDER BY v.fecha_hora_inicio DESC`
        );
        return rows.map((row: any) => this.mapearFila(row));
    }

    // ─── Actualizar solo el estado de un viaje ────────────────────────────────
    async actualizarEstado(id: string, nuevoEstado: string): Promise<void> {
        const estadoId = await this.obtenerEstadoId(nuevoEstado as EstadoViaje);
        await pool.query(
            'UPDATE viajes SET estado_id = ? WHERE id = ?',
            [estadoId, id]
        );
    }

    // ─── Listar viajes que están EN_CURSO ─────────────────────────────────────
    async listarEnCurso(): Promise<Viaje[]> {
        const [rows]: any = await pool.query(
            `SELECT v.*, ev.nombre AS estado_nombre
             FROM viajes v
             JOIN estado_viaje ev ON v.estado_id = ev.id
             WHERE ev.nombre = ?`,
            [EstadoViaje.EN_CURSO]
        );
        return rows.map((row: any) => this.mapearFila(row));
    }

    // ─── Historial de viajes de un conductor ──────────────────────────────────
    async obtenerHistorialConductor(idConductor: string): Promise<Viaje[]> {
        const [rows]: any = await pool.query(
            `SELECT v.*, ev.nombre AS estado_nombre
             FROM viajes v
             JOIN estado_viaje ev ON v.estado_id = ev.id
             WHERE v.conductor_id = ?
             ORDER BY v.fecha_hora_inicio DESC`,
            [idConductor]
        );
        return rows.map((row: any) => this.mapearFila(row));
    }
}
