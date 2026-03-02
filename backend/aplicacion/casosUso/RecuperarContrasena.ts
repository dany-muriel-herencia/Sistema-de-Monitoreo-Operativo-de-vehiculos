import { IUsuarioRepositorio } from "../../dominio/Repositorios/IUsuarioRepositorio";

export class RecuperarContrasena {
    constructor(private usuarioRepo: IUsuarioRepositorio) { }

    async ejecutar(email: string, nuevaContrasena: string): Promise<void> {
        const usuario = await this.usuarioRepo.obtenerPorEmail(email);
        if (!usuario) {
            throw new Error("No existe un usuario con ese email");
        }

        // Usamos la lógica de la entidad para cambiar el estado
        usuario.recuperarContraseña(email, nuevaContrasena);

        // Persistimos en el repositorio
        await this.usuarioRepo.actualizar(usuario);
    }
}
