// infraestructura/repositorios/UsuarioRepositorio.ts
import { IUsuarioRepositorio } from "../../dominio/Repositorios/IUsuarioRepositorio";
import { usuario } from "../../dominio/Entidades/usuario";
import { pool } from "../../db";

export class UsuarioRepositorio implements IUsuarioRepositorio {

    // ─── Mapea una fila de BD → instancia usuario ─────────────────────────────
    private mapearFila(row: any): usuario {
        return new usuario(
            row.id.toString(),
            row.nombre,
            row.email,
            row.contraseña,
            row.rol // Agregamos el rol de la BD
        );
    }

    // ─── Buscar usuario por email (usado en Login) ────────────────────────────
    async obtenerPorEmail(email: string): Promise<usuario | null> {
        const [rows]: any = await pool.query(
            'SELECT id, nombre, email, contraseña, rol FROM usuarios WHERE email = ?',
            [email]
        );
        if (rows.length === 0) return null;
        return this.mapearFila(rows[0]);
    }

    // ─── Registrar nuevo usuario ──────────────────────────────────────────────
    async guardar(user: usuario): Promise<void> {
        await pool.query(
            'INSERT INTO usuarios (nombre, email, contraseña, rol) VALUES (?, ?, ?, ?)',
            [user.getNombre(), user.getEmail(), user.getContraseña(), user.getRol()]
        );
    }
}
