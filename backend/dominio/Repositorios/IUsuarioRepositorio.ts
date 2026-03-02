import { Usuario } from "../Entidades/usuarios";

export interface IUsuarioRepositorio {
    obtenerPorEmail(email: string): Promise<Usuario | null>;
    guardar(user: Usuario): Promise<void>;
    actualizar(user: Usuario): Promise<void>;
}
