// controladores/rutaController.ts
import { Request, Response } from 'express';
import { IRutaRepositorio } from '../dominio/Repositorios/IRutaRepositorio';

export class RutaController {
    constructor(private rutaRepo: IRutaRepositorio) { }

    // GET /rutas  — listar todas las rutas
    async listar(req: Request, res: Response): Promise<void> {
        try {
            const rutas = await this.rutaRepo.obtenerTodos();
            res.status(200).json(rutas);
        } catch (error: any) {
            res.status(500).json({ error: error.message });
        }
    }

    // GET /rutas/:id  — obtener una ruta con sus puntos
    async obtenerPorId(req: Request, res: Response): Promise<void> {
        try {
            const ruta = await this.rutaRepo.obtenerPorId(req.params.id as string);
            if (!ruta) {
                res.status(404).json({ error: `Ruta ${req.params.id} no encontrada` });
                return;
            }
            res.status(200).json(ruta);
        } catch (error: any) {
            res.status(500).json({ error: error.message });
        }
    }

    // DELETE /rutas/:id  — eliminar ruta
    async eliminar(req: Request, res: Response): Promise<void> {
        try {
            await this.rutaRepo.eliminar(req.params.id as string);
            res.status(200).json({ mensaje: `Ruta ${req.params.id} eliminada` });
        } catch (error: any) {
            res.status(500).json({ error: error.message });
        }
    }
}
