// controladores/asignacionController.ts
import { Request, Response } from 'express';
import { IAsignacionConductorRepositorio } from '../dominio/Repositorios/IAsignacionConductorRepositorio';

export class AsignacionController {
    constructor(private asignacionRepo: IAsignacionConductorRepositorio) { }

    // GET /asignaciones/conductor/:id  — historial de asignaciones de un conductor
    async historialConductor(req: Request, res: Response): Promise<void> {
        try {
            const historial = await this.asignacionRepo.obtenerHistorialConductor(req.params.id as string);
            res.status(200).json(historial);
        } catch (error: any) {
            res.status(500).json({ error: error.message });
        }
    }

    // GET /asignaciones/conductor/:id/activa  — asignación activa de un conductor
    async activaConductor(req: Request, res: Response): Promise<void> {
        try {
            const activa = await this.asignacionRepo.obtenerActivaPorConductor(req.params.id as string);
            if (!activa) {
                res.status(404).json({ error: "El conductor no tiene asignación activa" });
                return;
            }
            res.status(200).json(activa);
        } catch (error: any) {
            res.status(500).json({ error: error.message });
        }
    }

    // GET /asignaciones/vehiculo/:placa/activa  — asignación activa de un vehículo
    async activaVehiculo(req: Request, res: Response): Promise<void> {
        try {
            const activa = await this.asignacionRepo.obtenerActivaPorVehiculo(req.params.placa as string);
            if (!activa) {
                res.status(404).json({ error: "El vehículo no tiene asignación activa" });
                return;
            }
            res.status(200).json(activa);
        } catch (error: any) {
            res.status(500).json({ error: error.message });
        }
    }
}
