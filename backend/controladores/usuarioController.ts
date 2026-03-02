import { Request, Response } from 'express';
import { Login } from '../aplicacion/casosUso/Login';
import { RecuperarContrasena } from '../aplicacion/casosUso/RecuperarContrasena';

export class UsuarioController {
    constructor(
        private loginUC: Login,
        private recuperarUC: RecuperarContrasena
    ) { }

    async login(req: Request, res: Response): Promise<void> {
        console.log("Intento de login:", req.body.email);
        const { email, password } = req.body;

        try {
            const usuario = await this.loginUC.ejecutar(email, password);
            if (!usuario) {
                res.status(401).json({ error: "Credenciales inválidas" });
                return;
            }

            // No devolver la contraseña al cliente
            const data = {
                id: usuario.getId(),
                nombre: usuario.getNombre(),
                email: usuario.getEmail(),
                rol: usuario.getRol()
            };

            res.json({ mensaje: "Login exitoso", usuario: data });
        } catch (error: any) {
            console.error("Error en login:", error.message);
            res.status(401).json({ error: error.message });
        }
    }

    async recuperarContrasena(req: Request, res: Response): Promise<void> {
        const { email, nuevaContrasena } = req.body;
        try {
            await this.recuperarUC.ejecutar(email, nuevaContrasena);
            res.json({ mensaje: "Contraseña actualizada con éxito" });
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    }
}
