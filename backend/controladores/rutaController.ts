// controladores/rutaController.ts
import { Request, Response } from 'express';
import { IRutaRepositorio } from '../dominio/Repositorios/IRutaRepositorio';
import { PuntoGeo } from '../dominio/Entidades/PuntoGeo';
import { Duracion } from '../dominio/Entidades/Duracion';
import { Ruta } from '../dominio/Entidades/Ruta';
import { CrearRuta } from '../aplicacion/casosUso/crearRuta';


export class RutaController {
    constructor(
        private rutaRepo: IRutaRepositorio,
        private crearRutaUC: CrearRuta
    ) { }

    // POST /rutas — crear nueva ruta de transporte
    async registrar(req: Request, res: Response): Promise<void> {
        try {
            await this.crearRutaUC.ejecutar(req.body);
            res.status(201).json({ mensaje: "Ruta creada con éxito" });
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    }


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

    async eliminar(req: Request, res: Response): Promise<void> {
        try {
            await this.rutaRepo.eliminar(req.params.id as string);
            res.status(200).json({ mensaje: `Ruta ${req.params.id} eliminada` });
        } catch (error: any) {
            res.status(500).json({ error: error.message });
        }
    }

    // PUT /rutas/:id — actualizar ruta
    async actualizar(req: Request, res: Response): Promise<void> {
        try {
            const id = req.params.id as string;
            const { nombre, distanciaTotal, duracionEstimadaMinutos, puntos } = req.body;

            const ruta = await this.rutaRepo.obtenerPorId(id);
            if (!ruta) {
                res.status(404).json({ error: "Ruta no encontrada" });
                return;
            }

            // Mapear nuevos puntos si vienen en la petición
            let puntosGeo: PuntoGeo[] = [];
            if (puntos && Array.isArray(puntos)) {
                puntosGeo = puntos.map((p: any) => new PuntoGeo(
                    "", // ID no necesario para actualización ya que se limpian/insertan
                    p.lat,
                    p.lng,
                    p.orden,
                    ""
                ));
            } else {
                puntosGeo = ruta.getPuntos();
            }

            const duracion = new Duracion(
                Math.floor(duracionEstimadaMinutos / 60),
                duracionEstimadaMinutos % 60
            );

            const rutaActualizada = new Ruta(id, nombre, distanciaTotal, duracion, puntosGeo);
            await this.rutaRepo.actualizar(rutaActualizada);
            res.status(200).json({ mensaje: "Ruta actualizada correctamente" });
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    }
}

