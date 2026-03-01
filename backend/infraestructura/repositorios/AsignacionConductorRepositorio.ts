// infraestructura/repositorios/AsignacionConductorRepositorio.ts
import { IAsignacionConductorRepositorio } from "../../dominio/Repositorios/IAsignacionConductorRepositorio";
import { AsignacionConductor } from "../../dominio/Entidades/AsignacionConductor";
import { pool } from "../../db";

export class AsignacionConductorRepositorio implements IAsignacionConductorRepositorio {

    // ─── Mapea una fila de BD → instancia AsignacionConductor ────────────────
    private mapearFila(row: any): AsignacionConductor {
        return new AsignacionConductor(
            row.id.toString(),
            row.conductor_id.toString(),
            row.vehiculo_id.toString(),
            new Date(row.fecha_inicio),
            row.fecha_fin ? new Date(row.fecha_fin) : null
        );
    }

    // ─── Registrar una nueva asignación conductor-vehículo ────────────────────
    async guardar(asignacion: AsignacionConductor): Promise<void> {
        await pool.query(
            `INSERT INTO asignaciones_conductor (conductor_id, vehiculo_id, fecha_inicio, fecha_fin)
             VALUES (?, ?, ?, ?)`,
            [
                asignacion.getIdConductor(),
                asignacion.getIdVehiculo(),
                asignacion.getFechaInicio(),
                asignacion.getFechaFin()
            ]
        );
    }

    // ─── Obtener la asignación ACTIVA de un conductor (fecha_fin IS NULL) ─────
    async obtenerActivaPorConductor(idConductor: string): Promise<AsignacionConductor | null> {
        const [rows]: any = await pool.query(
            `SELECT * FROM asignaciones_conductor
             WHERE conductor_id = ? AND fecha_fin IS NULL
             LIMIT 1`,
            [idConductor]
        );
        if (rows.length === 0) return null;
        return this.mapearFila(rows[0]);
    }

    // ─── Obtener la asignación ACTIVA de un vehículo (fecha_fin IS NULL) ──────
    async obtenerActivaPorVehiculo(idVehiculo: string): Promise<AsignacionConductor | null> {
        const [rows]: any = await pool.query(
            `SELECT * FROM asignaciones_conductor
             WHERE vehiculo_id = ? AND fecha_fin IS NULL
             LIMIT 1`,
            [idVehiculo]
        );
        if (rows.length === 0) return null;
        return this.mapearFila(rows[0]);
    }

    // ─── Historial completo de asignaciones de un conductor ───────────────────
    async obtenerHistorialConductor(idConductor: string): Promise<AsignacionConductor[]> {
        const [rows]: any = await pool.query(
            `SELECT * FROM asignaciones_conductor
             WHERE conductor_id = ?
             ORDER BY fecha_inicio DESC`,
            [idConductor]
        );
        return rows.map((row: any) => this.mapearFila(row));
    }

    // ─── Finalizar una asignación activa (pone fecha_fin) ─────────────────────
    async finalizarAsignacion(idAsignacion: string, fechaFin: Date): Promise<void> {
        await pool.query(
            'UPDATE asignaciones_conductor SET fecha_fin = ? WHERE id = ?',
            [fechaFin, idAsignacion]
        );
    }
}
