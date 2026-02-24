import { IConductorRepositorio } from "../../dominio/Repositorios/IConductorRepositorio";
import { Conductor } from "../../dominio/Entidades/Conductor";
import { pool } from "../../db";

export class ConductorRepositorio implements IConductorRepositorio {

    async guardar(conductor: Conductor): Promise<void> {
        const connection = await pool.getConnection();
        try {
            await connection.beginTransaction();

            const [userResult]: any = await connection.query(
                'INSERT INTO usuarios (nombre, email, contraseña, rol) VALUES (?, ?, ?, ?)',
                [conductor.getNombre(), conductor.getEmail(), "password_placeholder", 'conductor']
            );
            const userId = userResult.insertId;

            await connection.query(
                'INSERT INTO conductores (usuario_id, licencia, telefono, sueldo,edad, disponible) VALUES (?, ?, ?, ?, ?,?)',
                [userId, conductor.getLicencia(), conductor.getTelefono(), conductor.getSueldo(),conductor.getEdad(), conductor.EstadoDisponible()]
            );

            await connection.commit();
        } catch (error) {
            await connection.rollback();
            throw error;
        } finally {
            connection.release();
        }
    }

    async obtenerPorId(id: string): Promise<Conductor | null> {
        const [rows]: any = await pool.query(
            `SELECT u.id, u.nombre, u.email, u.contraseña, c.licencia, c.telefono, c.sueldo, c.disponible 
             FROM usuarios u 
             JOIN conductores c ON u.id = c.usuario_id 
             WHERE u.id = ?`,
            [id]
        );

        if (rows.length === 0) return null;

        const row = rows[0];
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

    async obtenerTodos(): Promise<Conductor[]> {
        const [rows]: any = await pool.query(
            `SELECT u.id, u.nombre, u.email, u.contraseña, c.licencia, c.telefono, c.sueldo, c.disponible 
             FROM usuarios u 
             JOIN conductores c ON u.id = c.usuario_id`
        );

        return rows.map((row: any) => new Conductor(
            row.id.toString(),
            row.nombre,
            row.email,
            row.contraseña,
            row.licencia,
            Number(row.telefono),
            Number(row.sueldo),
            Number(row.edad),
            Boolean(row.disponible)
        ));
    }

    async actualizar(conductor: Conductor): Promise<void> {
        const connection = await pool.getConnection();
        try {
            await connection.beginTransaction();

            await connection.query(
                'UPDATE usuarios SET nombre = ?, email = ? WHERE id = ?',
                [conductor.getNombre(), conductor.getEmail(), conductor.getId()]
            );

            await connection.query(
                'UPDATE conductores SET licencia = ?, telefono = ?, sueldo = ?, disponible = ? WHERE usuario_id = ?',
                [conductor.getLicencia(), conductor.getTelefono(), conductor.getSueldo(), conductor.EstadoDisponible(), conductor.getId()]
            );

            await connection.commit();
        } catch (error) {
            await connection.rollback();
            throw error;
        } finally {
            connection.release();
        }
    }

    async eliminar(id: string): Promise<void> {
        await pool.query('DELETE FROM usuarios WHERE id = ?', [id]);
    }
}
