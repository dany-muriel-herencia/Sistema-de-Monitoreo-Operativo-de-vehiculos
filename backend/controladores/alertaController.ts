// controladores/alertaController.ts
import { Request, Response } from 'express';
import { IAlertaRutaRepositorio } from '../dominio/Repositorios/IAlertaRutaRepositorio';

export class AlertaController {
    constructor(private alertaRepo: IAlertaRutaRepositorio) { }

    // GET /alertas/viaje/:idViaje  — todas las alertas de un viaje
    async obtenerPorViaje(req: Request, res: Response): Promise<void> {
        try {
            const alertas = await this.alertaRepo.obtenerPorViaje(req.params.idViaje as string);
            res.status(200).json(alertas);
        } catch (error: any) {
            res.status(500).json({ error: error.message });
        }
    }

    // GET /alertas/viaje/:idViaje/pendientes  — alertas sin resolver
    async obtenerPendientes(req: Request, res: Response): Promise<void> {
        try {
            const pendientes = await this.alertaRepo.obtenerPendientes(req.params.idViaje as string);
            res.status(200).json(pendientes);
        } catch (error: any) {
            res.status(500).json({ error: error.message });
        }
    }

    // PATCH /alertas/:id/resolver  — marcar alerta como resuelta
    async resolver(req: Request, res: Response): Promise<void> {
        try {
            await this.alertaRepo.marcarResuelta(req.params.id as string);
            res.status(200).json({ mensaje: `Alerta ${req.params.id} resuelta` });
        } catch (error: any) {
            res.status(500).json({ error: error.message });
        }
    }
}
