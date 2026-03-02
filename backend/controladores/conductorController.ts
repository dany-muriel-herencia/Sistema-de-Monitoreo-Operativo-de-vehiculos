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
            console.log("Creando conductor:", req.body);
            const nuevo = await this.crearConductorUC.ejecutar(req.body);
            res.status(201).json({
                mensaje: "Conductor registrado con éxito",
                data: {
                    id: nuevo.getId(),
                    nombre: nuevo.getNombre(),
                    email: nuevo.getEmail(),
                    licencia: nuevo.getLicencia()
                }
            });
        } catch (error: any) {
            console.error("Error al crear conductor:", error);
            res.status(400).json({ error: error.message });
        }
    }

    // GET /conductores  — listar todos los conductores
    async listar(req: Request, res: Response): Promise<void> {
        try {
            const conductores = await this.obtenerConductoresUC.ejecutar();
            const data = conductores.map(c => {
                return {
                    id: c.getId(),
                    nombre: c.getNombre(),
                    email: c.getEmail(),
                    licencia: c.getLicencia(),
                    telefono: c.getTelefono(),
                    sueldo: c.getSueldo(),
                    edad: c.getEdad(),
                    disponible: c.EstadoDisponible()
                };
            });
            res.status(200).json(data);
        } catch (error: any) {
            console.error("Error al listar conductores:", error);
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
            const c = await this.gestionConductoresUC.obtenerConductor(req.params.id as string);
            res.status(200).json({
                id: c.getId(),
                nombre: c.getNombre(),
                email: c.getEmail(),
                licencia: c.getLicencia(),
                telefono: c.getTelefono(),
                sueldo: c.getSueldo(),
                edad: c.getEdad(),
                disponible: c.EstadoDisponible()
            });
        } catch (error: any) {
            console.error("Error al obtener conductor:", error);
            res.status(404).json({ error: error.message });
        }
    }

    // DELETE /conductores/:id  — dar de baja
    async eliminar(req: Request, res: Response): Promise<void> {
        try {
            const id = req.params.id as string;
            console.log(`Intentando eliminar conductor con ID: ${id}`);
            await this.gestionConductoresUC.darDeBajaConductor(id);
            res.status(200).json({ mensaje: `Conductor ${id} dado de baja` });
        } catch (error: any) {
            console.error("Error al eliminar conductor:", error);
            res.status(500).json({ error: error.message });
        }
    }
}