import { Ruta } from "../Entidades/Ruta";
import { UbicacionGPS } from "../Entidades/UbicacionGPS";
import { PuntoGeo } from "../Entidades/PuntoGeo";

export class CalculadorRutas {
    /**
     * Evalúa distancias y duraciones entre puntos de ruta.
     */
    evaluarRuta(ruta: Ruta): { distanciaTotal: number; duracionEstimada: number } {
        return {
            distanciaTotal: ruta.getDistanciaTotal(),
            duracionEstimada: ruta.getDuracionEstimada().enMinutos()
        };
    }


    calcularDesviacion(ruta: Ruta, ubicacionActual: UbicacionGPS): { desviacion: number; siguientePunto: PuntoGeo | null } {
        const desviacion = ruta.calcularDesviacion(ubicacionActual);
        const siguientePunto = ruta.obtenerSiguienteUbicacion(ubicacionActual);

        return {
            desviacion,
            siguientePunto
        };
    }
}
