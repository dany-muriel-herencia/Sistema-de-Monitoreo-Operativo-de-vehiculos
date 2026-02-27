import { IUsuarioRepositorio } from "../../dominio/Repositorios/IUsuarioRepositorio";
import { usuario } from "../../dominio/Entidades/usuario";
import { pool } from "../../db";

export class UsuarioRepositorio implements IUsuarioRepositorio {
    async obtenerPorEmail(email: string): Promise<usuario | null> {
        const [rows]: any = await pool.query(
            "SELECT id, nombre, email, contraseña FROM usuarios WHERE email = ?",
            [email]
        );







        if (rows.length === 0) return null;

        const row = rows[0];
        return new usuario(
            row.id.toString(),
            row.nombre,
            row.email,
            row.contraseña
        );
    }

    async guardar(user: usuario): Promise<void> {
        await pool.query(
            "INSERT INTO usuarios (nombre, email, contraseña) VALUES (?, ?, ?)",
            [user.getNombre(), user.getEmail(), "password_placeholder"]
        );
    }
}
