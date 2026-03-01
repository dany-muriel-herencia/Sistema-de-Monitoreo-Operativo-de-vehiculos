// controladores/eventoController.ts
import { Request, Response } from 'express';
import { IEventoOperacionRepositorio } from '../dominio/Repositorios/IEventoOperacionRepositorio';

export class EventoController {
    constructor(private eventoRepo: IEventoOperacionRepositorio) { }

    // GET /eventos/viaje/:idViaje  — todos los eventos de un viaje
    async obtenerPorViaje(req: Request, res: Response): Promise<void> {
        try {
            const eventos = await this.eventoRepo.obtenerPorViaje(req.params.idViaje as string);
            res.status(200).json(eventos);
        } catch (error: any) {
            res.status(500).json({ error: error.message });
        }
    }
}
