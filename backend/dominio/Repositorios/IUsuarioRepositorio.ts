import { usuario } from "../Entidades/usuario";

export interface IUsuarioRepositorio {
    obtenerPorEmail(email: string): Promise<usuario | null>;
    guardar(user: usuario): Promise<void>;
}
