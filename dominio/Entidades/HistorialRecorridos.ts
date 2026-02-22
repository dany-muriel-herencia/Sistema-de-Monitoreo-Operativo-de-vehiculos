import { Viaje } from "./Viaje.js";
import { UbicacionGPS } from "./UbicacionGPS.js";
import { EventoOperacion } from "./EventoOperacion.js";
import { AlertaRuta } from "./AlertaRuta.js";
import { TipoAlerta } from "../emuns/TipoAlerta.js";

export class HistorialRecorridos {
    private idViaje: string;
    private ubicaciones: UbicacionGPS[];
    private eventos: EventoOperacion[];
    private alertas: AlertaRuta[];

    constructor(
        idViaje: string,
        ubicaciones: UbicacionGPS[] = [],
        eventos: EventoOperacion[] = [],
        alertas: AlertaRuta[] = []
    ) {
        this.idViaje = idViaje;
        this.ubicaciones = ubicaciones;
        this.eventos = eventos;
        this.alertas = alertas;
    }

    /**
     * Calcula y devuelve métricas resumen del viaje:
     * - Total de puntos GPS registrados
     * - Total de eventos
     * - Alertas generadas y cuántas quedaron sin resolver
     * - Velocidad promedio (si hay datos de velocidad)
     */
    calcularMetricas(): {
        totalPuntosGPS: number;
        totalEventos: number;
        totalAlertas: number;
        alertasSinResolver: number;
        velocidadPromedio: number;
    } {
        const alertasSinResolver = this.alertas.filter(a => !a.estaResuelta()).length;

        const velocidades = this.ubicaciones
            .map(u => u.getVelocidad())
            .filter(v => v > 0);
        const velocidadPromedio = velocidades.length > 0
            ? velocidades.reduce((sum, v) => sum + v, 0) / velocidades.length
            : 0;

        return {
            totalPuntosGPS: this.ubicaciones.length,
            totalEventos: this.eventos.length,
            totalAlertas: this.alertas.length,
            alertasSinResolver,
            velocidadPromedio: Math.round(velocidadPromedio * 10) / 10
        };
    }

    /**
     * Exporta el historial como un objeto JSON plano.
     * Útil para reportes o envío a la app móvil.
     */
    exportar(): object {
        const metricas = this.calcularMetricas();
        return {
            idViaje: this.idViaje,
            metricas,
            eventos: this.eventos.map(e => ({
                timestamp: e.getTimestamp(),
                tipo: e.getTipo(),
                descripcion: e.getDescripcion()
            })),
            alertas: this.alertas.map(a => ({
                tipo: a.getTipo(),
                descripcion: a.getDescripcion(),
                timestamp: a.getTimestamp(),
                resuelta: a.estaResuelta()
            }))
        };
    }

    // ── Getters ─────────────────────────────────────────────────
    getIdViaje(): string { return this.idViaje; }
    getUbicaciones(): UbicacionGPS[] { return this.ubicaciones; }
    getEventos(): EventoOperacion[] { return this.eventos; }
    getAlertas(): AlertaRuta[] { return this.alertas; }
}