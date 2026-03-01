// controladores/vehiculoController.ts
import { Request, Response } from 'express';
import { GestionVehiculos } from '../aplicacion/casosUso/GestionVehiculos';
import { Vehiculo } from '../dominio/Entidades/Vehiculo';
import { EstadoVehiculo } from '../dominio/emuns/EstadoVehiculo';

export class VehiculoController {
    constructor(private gestionVehiculosUC: GestionVehiculos) { }

    // POST /vehiculos  — registrar un vehículo nuevo
    async crear(req: Request, res: Response): Promise<void> {
        try {
            const { marca, placa, modelo, capacidad, kilometraje, año } = req.body;
            const vehiculo = new Vehiculo(
                null,                        // id lo asigna la BD (AUTO_INCREMENT)
                marca,
                placa,
                modelo,
                Number(capacidad),
                Number(kilometraje ?? 0),
                EstadoVehiculo.DISPONIBLE,   // nuevo vehículo siempre inicia disponible
                Number(año)
            );
            await this.gestionVehiculosUC.registrarVehiculo(vehiculo);
            res.status(201).json({ mensaje: `Vehículo ${placa} registrado con éxito` });
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    }

    // GET /vehiculos  — listar toda la flota
    async listar(req: Request, res: Response): Promise<void> {
        try {
            const vehiculos = await this.gestionVehiculosUC.listarVehiculos();
            res.status(200).json(vehiculos);
        } catch (error: any) {
            res.status(500).json({ error: error.message });
        }
    }

    // GET /vehiculos/:placa  — obtener uno por placa
    async obtenerPorPlaca(req: Request, res: Response): Promise<void> {
        try {
            const vehiculo = await this.gestionVehiculosUC.obtenerVehiculo(req.params.placa as string);
            res.status(200).json(vehiculo);
        } catch (error: any) {
            res.status(404).json({ error: error.message });
        }
    }

    // DELETE /vehiculos/:placa  — eliminar vehículo
    async eliminar(req: Request, res: Response): Promise<void> {
        try {
            await this.gestionVehiculosUC.eliminarVehiculo(req.params.placa as string);
            res.status(200).json({ mensaje: `Vehículo ${req.params.placa} eliminado` });
        } catch (error: any) {
            res.status(500).json({ error: error.message });
        }
    }
}