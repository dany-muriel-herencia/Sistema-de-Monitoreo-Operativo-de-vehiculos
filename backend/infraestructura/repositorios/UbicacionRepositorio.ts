import { IUbicacionRepositorio } from "../../dominio/Repositorios/IUbicacionRepositorio";
import { UbicacionGPS } from "../../dominio/Entidades/UbicacionGPS";
import { pool } from "../../db";

export class UbicacionRepositorio implements IUbicacionRepositorio {

    async guardar(ubicacion: UbicacionGPS): Promise<void> {
        await pool.query(
             'INSERT INTO ubicaciones_gps (viaje_id, timestamp, latitud, longitud, velocidad) VALUES (?, ?, ?, ?, ?)',
            [ubicacion.getIdViaje(), ubicacion.getFechaHora(), ubicacion.getLatitud(), ubicacion.getLongitud(), ubicacion.getVelocidad()]
         );
    }

    async obtenerPorViaje(idViaje: string): Promise<UbicacionGPS[]> {
         const [rows]: any = await pool.query(
            'SELECT * FROM ubicaciones_gps WHERE viaje_id = ? ORDER BY timestamp ASC',
            [idViaje]
        );

        return rows.map((row: any) => new UbicacionGPS(
            row.viaje_id.toString(),
            Number(row.latitud),
             Number(row.longitud),
            row.timestamp,
             Number(row.velocidad)
        ));
    }

            async obtenerUltimaPorViaje(idViaje: string): Promise<UbicacionGPS | null> {
                const [rows]: any = await pool.query(
                    'SELECT * FROM ubicaciones_gps WHERE viaje_id = ? ORDER BY timestamp DESC LIMIT 1',
                    [idViaje]
                );

                if (rows.length === 0) return null;

                const row = rows[0];
                return new UbicacionGPS(
                    row.viaje_id.toString(),
                    Number(row.latitud),
                    Number(row.longitud),
                    row.timestamp,
                    Number(row.velocidad)
                );
            }
        }
