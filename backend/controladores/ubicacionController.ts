// controladores/ubicacionController.ts
import { Request, Response } from 'express';
import { CrearUbicacion } from '../aplicacion/casosUso/crearUbicacion';
import { IUbicacionRepositorio } from '../dominio/Repositorios/IUbicacionRepositorio';

export class UbicacionController {
    constructor(
        private crearUbicacionUC: CrearUbicacion,
        private ubicacionRepo: IUbicacionRepositorio
    ) { }

    // POST /ubicaciones  — registrar nueva posición GPS de un viaje
    async registrar(req: Request, res: Response): Promise<void> {
        try {
            await this.crearUbicacionUC.ejecutar(req.body);
            res.status(201).json({ mensaje: "Ubicación GPS registrada" });
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    }

    // GET /ubicaciones/viaje/:idViaje  — recorrido completo de un viaje
    async obtenerPorViaje(req: Request, res: Response): Promise<void> {
        try {
            const idViaje = req.params.idViaje as string;
            const ubicaciones = await this.ubicacionRepo.obtenerPorViaje(idViaje);
            res.status(200).json(ubicaciones);
        } catch (error: any) {
            res.status(500).json({ error: error.message });
        }
    }

    // GET /ubicaciones/viaje/:idViaje/ultima  — última posición conocida
    async obtenerUltima(req: Request, res: Response): Promise<void> {
        try {
            const idViaje = req.params.idViaje as string;
            const ultima = await this.ubicacionRepo.obtenerUltimaPorViaje(idViaje);
            if (!ultima) {
                res.status(404).json({ error: "No hay ubicaciones para este viaje" });
                return;
            }
            res.status(200).json(ultima);
        } catch (error: any) {
            res.status(500).json({ error: error.message });
        }
    }
}
