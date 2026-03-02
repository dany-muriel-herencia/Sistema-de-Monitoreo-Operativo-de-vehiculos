// infraestructura/repositorios/UsuarioRepositorio.ts
import { IUsuarioRepositorio } from "../../dominio/Repositorios/IUsuarioRepositorio";
import { Usuario } from "../../dominio/Entidades/usuarios";
import { pool } from "../../db";

export class UsuarioRepositorio implements IUsuarioRepositorio {

    // ─── Mapea una fila de BD → instancia Usuario ─────────────────────────────
    private mapearFila(row: any): Usuario {
        return new Usuario(
            row.id, // ya no convertimos forzadamente a string si es number
            row.nombre,
            row.email,
            row.contrasena || row.contraseña,
            row.rol
        );
    }

    // ─── Buscar usuario por email (usado en Login) ────────────────────────────
    async obtenerPorEmail(email: string): Promise<Usuario | null> {
        const [rows]: any = await pool.query(
            'SELECT id, nombre, email, contraseña as contrasena, rol FROM usuarios WHERE email = ?',
            [email]
        );
        if (rows.length === 0) return null;
        return this.mapearFila(rows[0]);
    }

    // ─── Registrar nuevo usuario ──────────────────────────────────────────────
    async guardar(user: Usuario): Promise<void> {
        const [result]: any = await pool.query(
            'INSERT INTO usuarios (nombre, email, contraseña, rol) VALUES (?, ?, ?, ?)',
            [user.getNombre(), user.getEmail(), user.getContrasena(), user.getRol()]
        );
        // Podríamos asignar el ID generado de vuelta al objeto si fuese necesario
    }

    // ─── Actualizar usuario (ej: para recuperación de contraseña) ────────────
    async actualizar(user: Usuario): Promise<void> {
        await pool.query(
            'UPDATE usuarios SET nombre = ?, contraseña = ? WHERE id = ?',
            [user.getNombre(), user.getContrasena(), user.getId()]
        );
    }
}
