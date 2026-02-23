import { IVehiculoRepositorio } from "../../dominio/Repositorios/IVehiculoRepositorio";
import { Vehiculo } from "../../dominio/Entidades/Vehiculo";
import { Estado_Vehiculo } from "../../dominio/emuns/Estado_Vehiculo";
import { pool } from "../../db";

export class VehiculoRepositorio implements IVehiculoRepositorio {

    async guardar(vehiculo: Vehiculo): Promise<void> {
        const [estadoResult]: any = await pool.query('SELECT id FROM estado_vehiculo WHERE nombre = ?', [vehiculo.getestado()]);
        const estadoId = estadoResult[0]?.id;

        await pool.query(
            'INSERT INTO vehiculos (placa, modelo, capacidad, kilometraje, estado_id) VALUES (?, ?, ?, ?, ?)',
            [vehiculo.getplaca(), vehiculo.getmodelo(), vehiculo.getcapacidad(), vehiculo.getkilometraje(), estadoId]
        );
    }

    async obtenerPorPlaca(placa: string): Promise<Vehiculo | null> {
        const [rows]: any = await pool.query(
            `SELECT v.*, e.nombre as estado_nombre 
             FROM vehiculos v 
             JOIN estado_vehiculo e ON v.estado_id = e.id 
             WHERE v.placa = ?`,
            [placa]
        );

        if (rows.length === 0) return null;

        const row = rows[0];
        return new Vehiculo(
            row.id.toString(),
            "", 
            row.placa,
            row.modelo,
            row.capacidad,
            row.kilometraje,
            row.estado_nombre as Estado_Vehiculo,
            0 
        );
    }

    async obtenerTodos(): Promise<Vehiculo[]> {
         const [rows]: any = await pool.query(
            `SELECT v.*, e.nombre as estado_nombre 
               FROM vehiculos v 
              JOIN estado_vehiculo e ON v.estado_id = e.id`
        );

         return rows.map((row: any) => new Vehiculo(
            row.id.toString(),
             "",
            row.placa,
            row.modelo,
             row.capacidad,
            row.kilometraje,
             row.estado_nombre as Estado_Vehiculo,
            0
        ));
     }

 async actualizar(vehiculo: Vehiculo): Promise<void> {
         const [estadoResult]: any = await pool.query('SELECT id FROM estado_vehiculo WHERE nombre = ?', [vehiculo.getestado()]);
        const estadoId = estadoResult[0]?.id;

        await pool.query(
             'UPDATE vehiculos SET modelo = ?, capacidad = ?, kilometraje = ?, estado_id = ? WHERE placa = ?',
            [vehiculo.getmodelo(), vehiculo.getcapacidad(), vehiculo.getkilometraje(), estadoId, vehiculo.getplaca()]
        );
    }

 async eliminar(placa: string): Promise<void> {
        await pool.query('DELETE FROM vehiculos WHERE placa = ?', [placa]);
    }
}
