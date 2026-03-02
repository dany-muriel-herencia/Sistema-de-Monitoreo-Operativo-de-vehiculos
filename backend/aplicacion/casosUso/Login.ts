import { IUsuarioRepositorio } from "../../dominio/Repositorios/IUsuarioRepositorio";
import { usuario } from "../../dominio/Entidades/usuario";

export class Login {

    constructor(private usuarioRepo: IUsuarioRepositorio) { }

    async ejecutar(email: string, contrasena: string): Promise<usuario | null> {
        console.log(`[LOGIN] Intentando ingresar con email: "${email}"`);

        const userEntity = await this.usuarioRepo.obtenerPorEmail(email.trim().toLowerCase());

        if (!userEntity) {
            console.log(`[LOGIN] Usuario no encontrado: ${email}`);
            throw new Error("Usuario no encontrado.");
        }

        console.log(`[LOGIN] Usuario encontrado en BD. Comparando contraseñas...`);

        // Verificamos la contraseña usando la lógica de la entidad
        if (userEntity.login(email, contrasena)) {
            console.log(`[LOGIN] Login exitoso para: ${email}`);
            return userEntity;
        } else {
            console.log(`[LOGIN] Contraseña incorrecta para: ${email}`);
            throw new Error("Contraseña incorrecta.");
        }
    }
}
