// infraestructura/repositorios/VehiculoRepositorio.ts
import { IVehiculoRepositorio } from "../../dominio/Repositorios/IVehiculoRepositorio";
import { Vehiculo } from "../../dominio/Entidades/Vehiculo";
import { EstadoVehiculo } from "../../dominio/emuns/EstadoVehiculo";
import { pool } from "../../db";

export class VehiculoRepositorio implements IVehiculoRepositorio {

    // ─── Mapea una fila de BD → instancia Vehiculo ───────────────────────────
    private mapearFila(row: any): Vehiculo {
        try {
            return new Vehiculo(
                row.id,
                row.marca,
                row.placa,
                row.modelo,
                Number(row.capacidad),
                Number(row.kilometraje),
                row.estado_nombre as EstadoVehiculo,
                Number(row.anio ?? row.año ?? 0)
            );
        } catch (error) {
            console.error("Error en VehiculoRepositorio.mapearFila:", error, row);
            throw error;
        }
    }

    // ─── Insertar un nuevo vehículo ───────────────────────────────────────────
    async guardar(vehiculo: Vehiculo): Promise<void> {
        const [estadoResult]: any = await pool.query(
            'SELECT id FROM estado_vehiculo WHERE nombre = ?',
            [vehiculo.getEstado()]
        );
        const estadoId = estadoResult[0]?.id;
        if (!estadoId) throw new Error(`Estado desconocido: ${vehiculo.getEstado()}`);

        await pool.query(
            'INSERT INTO vehiculos (marca, placa, modelo, año, capacidad, kilometraje, estado_id) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [
                vehiculo.getMarca(),
                vehiculo.getPlaca(),
                vehiculo.getModelo(),
                vehiculo.getAnio(),
                vehiculo.getCapacidad(),
                vehiculo.getKilometraje(),
                estadoId
            ]
        );
    }

    // ─── Buscar vehículo por placa ────────────────────────────────────────────
    async obtenerPorPlaca(placa: string): Promise<Vehiculo | null> {
        const [rows]: any = await pool.query(
            `SELECT v.id, v.marca, v.placa, v.modelo, v.año as anio, v.capacidad, v.kilometraje, v.estado_id, ev.nombre AS estado_nombre
             FROM vehiculos v
             JOIN estado_vehiculo ev ON v.estado_id = ev.id
             WHERE v.placa = ?`,
            [placa]
        );
        if (rows.length === 0) return null;
        return this.mapearFila(rows[0]);
    }

    // ─── Obtener todos los vehículos ──────────────────────────────────────────
    async obtenerTodos(): Promise<Vehiculo[]> {
        const [rows]: any = await pool.query(
            `SELECT v.id, v.marca, v.placa, v.modelo, v.año as anio, v.capacidad, v.kilometraje, v.estado_id, ev.nombre AS estado_nombre
             FROM vehiculos v
             JOIN estado_vehiculo ev ON v.estado_id = ev.id`
        );
        return rows.map((row: any) => this.mapearFila(row));
    }

    // ─── Actualizar datos de un vehículo ──────────────────────────────────────
    async actualizar(vehiculo: Vehiculo): Promise<void> {
        const [estadoResult]: any = await pool.query(
            'SELECT id FROM estado_vehiculo WHERE nombre = ?',
            [vehiculo.getEstado()]
        );
        const estadoId = estadoResult[0]?.id;
        if (!estadoId) throw new Error(`Estado desconocido: ${vehiculo.getEstado()}`);

        await pool.query(
            `UPDATE vehiculos
             SET marca = ?, modelo = ?, año = ?, capacidad = ?, kilometraje = ?, estado_id = ?
             WHERE placa = ?`,
            [
                vehiculo.getMarca(),
                vehiculo.getModelo(),
                vehiculo.getAnio(),
                vehiculo.getCapacidad(),
                vehiculo.getKilometraje(),
                estadoId,
                vehiculo.getPlaca()
            ]
        );
    }

    // ─── Eliminar vehículo por placa ──────────────────────────────────────────
    async eliminar(placa: string): Promise<void> {
        try {
            await pool.query('DELETE FROM vehiculos WHERE placa = ?', [placa]);
        } catch (error: any) {
            console.error("DB Error en VehiculoRepositorio.eliminar:", error);
            if (error.code === 'ER_ROW_IS_REFERENCED_2') {
                throw new Error("No se puede eliminar el vehículo porque está asignado a un viaje.");
            }
            throw error;
        }
    }
}
