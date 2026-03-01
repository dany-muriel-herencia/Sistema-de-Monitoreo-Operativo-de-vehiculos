// infraestructura/repositorios/RutaRepositorio.ts
import { IRutaRepositorio } from "../../dominio/Repositorios/IRutaRepositorio";
import { Ruta } from "../../dominio/Entidades/Ruta";
import { PuntoGeo } from "../../dominio/Entidades/PuntoGeo";
import { Duracion } from "../../dominio/Entidades/Duracion";
import { pool } from "../../db";

export class RutaRepositorio implements IRutaRepositorio {

    // ─── Convierte una fila + sus puntos de BD → instancia Ruta ──────────────
    private async cargarPuntos(idRuta: number): Promise<PuntoGeo[]> {
        const [puntos]: any = await pool.query(
            `SELECT * FROM puntos_ruta WHERE ruta_id = ? ORDER BY orden ASC`,
            [idRuta]
        );
        return puntos.map((p: any) => new PuntoGeo(
            p.id.toString(),
            Number(p.latitud),
            Number(p.longitud),
            Number(p.orden),
            '' // puntos_ruta no tiene columna descripcion en la BD
        ));
    }

    private mapearFila(row: any, puntos: PuntoGeo[]): Ruta {
        const totalMinutos = Number(row.duracion_estimada);
        const duracion = new Duracion(
            Math.floor(totalMinutos / 60),
            totalMinutos % 60
        );
        return new Ruta(
            row.id.toString(),
            row.nombre,
            Number(row.distancia_total),
            duracion,
            puntos
        );
    }

    // ─── Insertar una nueva ruta con sus puntos geográficos ───────────────────
    async guardar(ruta: Ruta): Promise<void> {
        const connection = await pool.getConnection();
        try {
            await connection.beginTransaction();

            const [result]: any = await connection.query(
                `INSERT INTO rutas (nombre, distancia_total, duracion_estimada) VALUES (?, ?, ?)`,
                [
                    ruta.getNombre(),
                    ruta.getDistanciaTotal(),
                    ruta.getDuracionEstimada().enMinutos()
                ]
            );
            const idRuta = result.insertId;

            // Insertar cada punto de la ruta
            for (const punto of ruta.getPuntos()) {
                await connection.query(
                    `INSERT INTO puntos_ruta (ruta_id, orden, latitud, longitud) VALUES (?, ?, ?, ?)`,
                    [idRuta, punto.getOrden(), punto.getLatitud(), punto.getLongitud()]
                );
            }

            await connection.commit();
        } catch (error) {
            await connection.rollback();
            throw error;
        } finally {
            connection.release();
        }
    }

    // ─── Obtener una ruta por su ID (incluye puntos) ──────────────────────────
    async obtenerPorId(id: string): Promise<Ruta | null> {
        const [rows]: any = await pool.query(
            'SELECT * FROM rutas WHERE id = ?',
            [id]
        );
        if (rows.length === 0) return null;

        const puntos = await this.cargarPuntos(rows[0].id);
        return this.mapearFila(rows[0], puntos);
    }

    // ─── Obtener todas las rutas (incluye puntos de cada una) ─────────────────
    async obtenerTodos(): Promise<Ruta[]> {
        const [rows]: any = await pool.query('SELECT * FROM rutas');
        const rutas: Ruta[] = [];
        for (const row of rows) {
            const puntos = await this.cargarPuntos(row.id);
            rutas.push(this.mapearFila(row, puntos));
        }
        return rutas;
    }

    // ─── Actualizar nombre o distancia de la ruta ─────────────────────────────
    async actualizar(ruta: Ruta): Promise<void> {
        await pool.query(
            `UPDATE rutas SET nombre = ?, distancia_total = ?, duracion_estimada = ? WHERE id = ?`,
            [
                ruta.getNombre(),
                ruta.getDistanciaTotal(),
                ruta.getDuracionEstimada().enMinutos(),
                ruta.getId()
            ]
        );
    }

    // ─── Eliminar ruta (puntos se eliminan en cascada por FK) ─────────────────
    async eliminar(id: string): Promise<void> {
        await pool.query('DELETE FROM rutas WHERE id = ?', [id]);
    }
}
