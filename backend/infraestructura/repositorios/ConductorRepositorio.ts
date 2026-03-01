// infraestructura/repositorios/ConductorRepositorio.ts
import { IConductorRepositorio } from "../../dominio/Repositorios/IConductorRepositorio";
import { Conductor } from "../../dominio/Entidades/Conductor";
import { pool } from "../../db";

export class ConductorRepositorio implements IConductorRepositorio {

    // ─── Mapea una fila de BD → instancia Conductor ───────────────────────────
    private mapearFila(row: any): Conductor {
        return new Conductor(
            row.id.toString(),
            row.nombre,
            row.email,
            row.contraseña,
            row.licencia,
            Number(row.telefono),
            Number(row.sueldo),
            Number(row.edad),
            Boolean(row.disponible)
        );
    }

    // ─── Insertar conductor (usa transacción: usuarios + conductores) ──────────
    async guardar(conductor: Conductor): Promise<void> {
        const connection = await pool.getConnection();
        try {
            await connection.beginTransaction();

            const [userResult]: any = await connection.query(
                'INSERT INTO usuarios (nombre, email, contraseña, rol) VALUES (?, ?, ?, ?)',
                [conductor.getNombre(), conductor.getEmail(), conductor.getContraseña(), 'conductor']
            );
            const userId = userResult.insertId;

            await connection.query(
                'INSERT INTO conductores (usuario_id, licencia, telefono, sueldo, edad, disponible) VALUES (?, ?, ?, ?, ?, ?)',
                [
                    userId,
                    conductor.getLicencia(),
                    conductor.getTelefono(),
                    conductor.getSueldo(),
                    conductor.getEdad(),
                    conductor.EstadoDisponible()
                ]
            );

            await connection.commit();
        } catch (error) {
            await connection.rollback();
            throw error;
        } finally {
            connection.release();
        }
    }

    // ─── Buscar conductor por ID ───────────────────────────────────────────────
    async obtenerPorId(id: string): Promise<Conductor | null> {
        const [rows]: any = await pool.query(
            `SELECT u.id, u.nombre, u.email, u.contraseña,
                    c.licencia, c.telefono, c.sueldo, c.edad, c.disponible
             FROM usuarios u
             JOIN conductores c ON u.id = c.usuario_id
             WHERE u.id = ?`,
            [id]
        );
        if (rows.length === 0) return null;
        return this.mapearFila(rows[0]);
    }

    // ─── Obtener todos los conductores ────────────────────────────────────────
    async obtenerTodos(): Promise<Conductor[]> {
        const [rows]: any = await pool.query(
            `SELECT u.id, u.nombre, u.email, u.contraseña,
                    c.licencia, c.telefono, c.sueldo, c.edad, c.disponible
             FROM usuarios u
             JOIN conductores c ON u.id = c.usuario_id`
        );
        return rows.map((row: any) => this.mapearFila(row));
    }

    // ─── Actualizar datos del conductor ───────────────────────────────────────
    async actualizar(conductor: Conductor): Promise<void> {
        const connection = await pool.getConnection();
        try {
            await connection.beginTransaction();

            await connection.query(
                'UPDATE usuarios SET nombre = ?, email = ? WHERE id = ?',
                [conductor.getNombre(), conductor.getEmail(), conductor.getId()]
            );

            await connection.query(
                `UPDATE conductores
                 SET licencia = ?, telefono = ?, sueldo = ?, edad = ?, disponible = ?
                 WHERE usuario_id = ?`,
                [
                    conductor.getLicencia(),
                    conductor.getTelefono(),
                    conductor.getSueldo(),
                    conductor.getEdad(),
                    conductor.EstadoDisponible(),
                    conductor.getId()
                ]
            );

            await connection.commit();
        } catch (error) {
            await connection.rollback();
            throw error;
        } finally {
            connection.release();
        }
    }

    // ─── Eliminar conductor (borra en cascada desde usuarios) ─────────────────
    async eliminar(id: string): Promise<void> {
        await pool.query('DELETE FROM usuarios WHERE id = ?', [id]);
    }
}
