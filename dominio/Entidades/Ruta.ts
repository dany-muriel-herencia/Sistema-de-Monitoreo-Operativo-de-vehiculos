import { PuntoGeo } from "./PuntoGeo.js";
import { Duracion } from "./Duracion.js";
import { UbicacionGPS } from "./UbicacionGPS.js";

export class Ruta {
    private id: string;
    private nombre: string;
    private puntos: PuntoGeo[];
    private distanciaTotal: number;
    private duracionEstimada: Duracion;

    constructor(
        id: string,
        nombre: string,
        distanciaTotal: number,
        duracionEstimada: Duracion,
        puntos: PuntoGeo[] = []
    ) {
        this.id = id;
        this.nombre = nombre;
        this.distanciaTotal = distanciaTotal;
        this.duracionEstimada = duracionEstimada;
        this.puntos = puntos;
    }

    /**
     * Calcula la distancia mínima (en metros) entre la ubicación actual
     * del vehículo y el punto más cercano de la ruta.
     * Útil para detectar desviaciones.
     */
    calcularDesviacion(ubicacion: UbicacionGPS): number {
        if (this.puntos.length === 0) return 0;

        // Convertir la ubicación en un PuntoGeo temporal para usar Haversine
        const puntoActual = new PuntoGeo(
            "-1",
            ubicacion.getLatitud(),
            ubicacion.getLongitud(),
            -1,
            "posicion_actual"
        );

        // Distancia mínima al punto más cercano de la ruta
        let distanciaMinima = Infinity;
        for (const punto of this.puntos) {
            const dist = puntoActual.calcularDistancia(punto);
            if (dist < distanciaMinima) distanciaMinima = dist;
        }
        return distanciaMinima; // en metros
    }

    /**
     * Dado donde está el vehículo ahora, devuelve el siguiente
     * punto de la ruta que debe alcanzar.
     */
    obtenerSiguienteUbicacion(ubicacionActual: UbicacionGPS): PuntoGeo | null {
        if (this.puntos.length === 0) return null;

        const puntoActual = new PuntoGeo(
            "-1",
            ubicacionActual.getLatitud(),
            ubicacionActual.getLongitud(),
            -1,
            "posicion_actual"
        );

        // Encontrar el punto más cercano de la ruta
        let indiceMasCercano = 0;
        let distanciaMinima = Infinity;
        for (let i = 0; i < this.puntos.length; i++) {
            const dist = puntoActual.calcularDistancia(this.puntos[i]!);
            if (dist < distanciaMinima) {
                distanciaMinima = dist;
                indiceMasCercano = i;
            }
        }

        // El siguiente punto es el que sigue en orden
        const indiceNext = indiceMasCercano + 1;
        if (indiceNext >= this.puntos.length) return null;
        const siguiente = this.puntos[indiceNext];
        return siguiente !== undefined ? siguiente : null;
    }

    // ── Getters ─────────────────────────────────────────────────
    getId(): string { return this.id; }
    getNombre(): string { return this.nombre; }
    getPuntos(): PuntoGeo[] { return this.puntos; }
    getDistanciaTotal(): number { return this.distanciaTotal; }
    getDuracionEstimada(): Duracion { return this.duracionEstimada; }
}
