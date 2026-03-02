import { IUsuarioRepositorio } from "../../dominio/Repositorios/IUsuarioRepositorio";
import { Usuario } from "../../dominio/Entidades/usuarios";

export class Login {
    /**
     * Valida las credenciales de un usuario.
     * Ahora ya NO tiene queries directos, usa el Repositorio.
     */
    constructor(private usuarioRepo: IUsuarioRepositorio) { }

    async ejecutar(email: string, contrasena: string): Promise<Usuario | null> {
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
