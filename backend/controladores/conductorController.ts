// controladores/conductorController.ts
import { Request, Response } from 'express';
import { CrearConductor } from '../aplicacion/casosUso/crearConductor';
import { Gestion_Conductores } from '../aplicacion/casosUso/Gestion_Conductores';
import { ObtenerConductores } from '../aplicacion/casosUso/obtenerConductores';

export class ConductorController {
    constructor(
        private crearConductorUC: CrearConductor,
        private gestionConductoresUC: Gestion_Conductores,
        private obtenerConductoresUC: ObtenerConductores
    ) { }

    // POST /conductores  — registrar un conductor nuevo
    async crear(req: Request, res: Response): Promise<void> {
        try {
            const nuevo = await this.crearConductorUC.ejecutar(req.body);
            res.status(201).json({ mensaje: "Conductor registrado con éxito", data: nuevo });
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    }

    // GET /conductores  — listar todos los conductores
    async listar(req: Request, res: Response): Promise<void> {
        try {
            const conductores = await this.obtenerConductoresUC.ejecutar();
            res.status(200).json(conductores);
        } catch (error: any) {
            res.status(500).json({ error: error.message });
        }
    }

    // GET /conductores/disponibles  — solo los disponibles
    async listarDisponibles(req: Request, res: Response): Promise<void> {
        try {
            const disponibles = await this.gestionConductoresUC.listarDisponibles();
            res.status(200).json(disponibles);
        } catch (error: any) {
            res.status(500).json({ error: error.message });
        }
    }

    // GET /conductores/:id  — obtener uno por ID
    async obtenerPorId(req: Request, res: Response): Promise<void> {
        try {
            const conductor = await this.gestionConductoresUC.obtenerConductor(req.params.id as string);
            res.status(200).json(conductor);
        } catch (error: any) {
            res.status(404).json({ error: error.message });
        }
    }

    // DELETE /conductores/:id  — dar de baja
    async eliminar(req: Request, res: Response): Promise<void> {
        try {
            await this.gestionConductoresUC.darDeBajaConductor(req.params.id as string);
            res.status(200).json({ mensaje: `Conductor ${req.params.id} dado de baja` });
        } catch (error: any) {
            res.status(500).json({ error: error.message });
        }
    }
}