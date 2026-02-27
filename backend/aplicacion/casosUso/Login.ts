import { IUsuarioRepositorio } from "../../dominio/Repositorios/IUsuarioRepositorio";
import { usuario } from "../../dominio/Entidades/usuario";

export class Login {
    /**
     * Valida las credenciales de un usuario.
     * Ahora ya NO tiene queries directos, usa el Repositorio.
     */
    constructor(private usuarioRepo: IUsuarioRepositorio) {}

    async ejecutar(email: string, contrasena: string): Promise<usuario | null> {
        const userEntity = await this.usuarioRepo.obtenerPorEmail(email);

        if (!userEntity) {
            throw new Error("Usuario no encontrado.");
        }

        // Verificamos la contraseña usando la lógica de la entidad
        if (userEntity.login(email, contrasena)) {
            return userEntity;
        } else {
            throw new Error("Contraseña incorrecta.");
        }
    }
}
