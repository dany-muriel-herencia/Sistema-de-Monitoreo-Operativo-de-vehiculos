// controladores/viajeController.ts
import { Request, Response } from 'express';
import { Gestion_Viajes } from '../aplicacion/casosUso/Gestion_Viajes';
import { Gestion_Conductores } from '../aplicacion/casosUso/Gestion_Conductores';
import { GestionVehiculos } from '../aplicacion/casosUso/GestionVehiculos';

export class ViajeController {
    constructor(
        private gestionViajesUC: Gestion_Viajes,
        private gestionConductoresUC: Gestion_Conductores,
        private gestionVehiculosUC: GestionVehiculos
    ) { }

    // POST /viajes  — planificar un viaje nuevo
    async planificar(req: Request, res: Response): Promise<void> {
        try {
            const { id, idConductor, placa, idRuta } = req.body;
            const conductor = await this.gestionConductoresUC.obtenerConductor(idConductor);
            const vehiculo = await this.gestionVehiculosUC.obtenerVehiculo(placa);
            const viaje = await this.gestionViajesUC.planificarViaje(id, conductor, vehiculo, idRuta);
            res.status(201).json({ mensaje: "Viaje planificado", data: viaje });
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    }

    // PATCH /viajes/:id/iniciar  — iniciar un viaje
    async iniciar(req: Request, res: Response): Promise<void> {
        try {
            const idViaje = req.params.id as string;
            const { idConductor } = req.body;
            const conductor = await this.gestionConductoresUC.obtenerConductor(idConductor);
            await this.gestionViajesUC.iniciarViaje(idViaje, conductor);
            res.status(200).json({ mensaje: "Viaje iniciado correctamente" });
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    }

    // PATCH /viajes/:id/finalizar  — finalizar un viaje
    async finalizar(req: Request, res: Response): Promise<void> {
        try {
            const idViaje = req.params.id as string;
            const { idConductor, placa, kmFinales } = req.body;
            const conductor = await this.gestionConductoresUC.obtenerConductor(idConductor);
            const vehiculo = await this.gestionVehiculosUC.obtenerVehiculo(placa);
            await this.gestionViajesUC.finalizarViaje(idViaje, conductor, vehiculo, Number(kmFinales));
            res.status(200).json({ mensaje: "Viaje finalizado y recursos liberados" });
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    }

    // GET /viajes  — listar todos los viajes
    async listarTodos(req: Request, res: Response): Promise<void> {
        try {
            const viajes = await this.gestionViajesUC.listarTodos();
            res.status(200).json(viajes);
        } catch (error: any) {
            res.status(500).json({ error: error.message });
        }
    }

    // GET /viajes/en-curso  — listar viajes activos
    async listarEnCurso(req: Request, res: Response): Promise<void> {
        try {
            const viajes = await this.gestionViajesUC.listarViajesEnCurso();
            res.status(200).json(viajes);
        } catch (error: any) {
            res.status(500).json({ error: error.message });
        }
    }

    // GET /viajes/historial/:idConductor  — historial de un conductor
    async historialConductor(req: Request, res: Response): Promise<void> {
        try {
            const idConductor = req.params.idConductor as string;
            const historial = await this.gestionViajesUC.historialPorConductor(idConductor);
            res.status(200).json(historial);
        } catch (error: any) {
            res.status(500).json({ error: error.message });
        }
    }
}