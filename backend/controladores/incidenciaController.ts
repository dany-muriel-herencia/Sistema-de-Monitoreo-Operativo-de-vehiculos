// controladores/incidenciaController.ts
import { Request, Response } from 'express';
import { RegistrarIncidencia } from '../aplicacion/casosUso/RegistrarIncidencia';
import { TipoAlerta } from '../dominio/emuns/TipoAlerta';
import { TipoEvento } from '../dominio/emuns/TipoEvento';
import { EstadoVehiculo } from '../dominio/emuns/EstadoVehiculo';
import { EstadoViaje } from '../dominio/emuns/EstadoViaje';

export class IncidenciaController {
    constructor(private registrarIncidenciaUC: RegistrarIncidencia) { }

    // POST /incidencias  — registrar una alerta+evento desde el conductor
    async registrar(req: Request, res: Response): Promise<void> {
        try {
            const { idViaje, tipoAlerta, tipoEvento, descripcion } = req.body;

            // Validar que los valores sean enums válidos
            if (!Object.values(TipoAlerta).includes(tipoAlerta)) {
                res.status(400).json({
                    error: `TipoAlerta inválido. Valores permitidos: ${Object.values(TipoAlerta).join(', ')}`
                });
                return;
            }
            if (!Object.values(TipoEvento).includes(tipoEvento)) {
                res.status(400).json({
                    error: `TipoEvento inválido. Valores permitidos: ${Object.values(TipoEvento).join(', ')}`
                });
                return;
            }

            await this.registrarIncidenciaUC.ejecutar({
                idViaje,
                tipoAlerta: tipoAlerta as TipoAlerta,
                tipoEvento: tipoEvento as TipoEvento,
                descripcion: descripcion ?? ''
            });

            res.status(201).json({ mensaje: 'Incidencia registrada con éxito' });
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    }

    // GET /enums  — devuelve todos los enums para que el frontend no use strings mágicos
    obtenerEnums(_req: Request, res: Response): void {
        res.status(200).json({
            EstadoVehiculo: Object.values(EstadoVehiculo),
            EstadoViaje: Object.values(EstadoViaje),
            TipoAlerta: Object.values(TipoAlerta),
            TipoEvento: Object.values(TipoEvento)
        });
    }
}
