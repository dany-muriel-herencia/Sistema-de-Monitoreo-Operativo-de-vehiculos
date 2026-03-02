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
            console.log("Creando vehículo:", req.body);
            const { marca, placa, modelo, capacidad, kilometraje, anio, año } = req.body;
            const vehiculo = new Vehiculo(
                null,                        // id lo asigna la BD (AUTO_INCREMENT)
                marca,
                placa,
                modelo,
                Number(capacidad),
                Number(kilometraje ?? 0),
                EstadoVehiculo.DISPONIBLE,   // nuevo vehículo siempre inicia disponible
                Number(anio ?? año ?? 0)
            );
            await this.gestionVehiculosUC.registrarVehiculo(vehiculo);
            res.status(201).json({
                mensaje: `Vehículo ${placa} registrado con éxito`,
                data: { placa, marca, modelo }
            });
        } catch (error: any) {
            console.error("Error al crear vehículo:", error);
            res.status(400).json({ error: error.message });
        }
    }

    // GET /vehiculos  — listar toda la flota
    async listar(req: Request, res: Response): Promise<void> {
        try {
            console.log("VehiculoController: Solicitando lista de vehículos...");
            const vehiculos = await this.gestionVehiculosUC.listarVehiculos();
            console.log(`VehiculoController: Obtenidos ${vehiculos.length} vehículos.`);

            const data = vehiculos.map(v => {
                return {
                    id: v.getId(),
                    marca: v.getMarca(),
                    placa: v.getPlaca(),
                    modelo: v.getModelo(),
                    capacidad: v.getCapacidad(),
                    kilometraje: v.getKilometraje(),
                    estado: v.getEstado(),
                    anio: v.getAnio()
                };
            });
            res.status(200).json(data);
        } catch (error: any) {
            console.error("Error al listar vehículos:", error);
            res.status(500).json({
                error: error.message,
                stack: error.stack,
                context: "VehiculoController.listar"
            });
        }
    }

    // GET /vehiculos/:placa  — obtener uno por placa
    async obtenerPorPlaca(req: Request, res: Response): Promise<void> {
        try {
            const v = await this.gestionVehiculosUC.obtenerVehiculo(req.params.placa as string);
            res.status(200).json({
                id: v.getId(),
                marca: v.getMarca(),
                placa: v.getPlaca(),
                modelo: v.getModelo(),
                capacidad: v.getCapacidad(),
                kilometraje: v.getKilometraje(),
                estado: v.getEstado(),
                anio: v.getAnio()
            });
        } catch (error: any) {
            console.error("Error al obtener vehículo:", error);
            res.status(404).json({ error: error.message });
        }
    }

    // DELETE /vehiculos/:placa  — eliminar vehículo
    async eliminar(req: Request, res: Response): Promise<void> {
        try {
            const placa = req.params.placa as string;
            console.log(`Intentando eliminar vehículo con placa: ${placa}`);
            await this.gestionVehiculosUC.eliminarVehiculo(placa);
            res.status(200).json({ mensaje: `Vehículo ${placa} eliminado` });
        } catch (error: any) {
            console.error("Error al eliminar vehículo:", error);
            res.status(500).json({ error: error.message });
        }
    }
}