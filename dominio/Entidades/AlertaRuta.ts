
import { TipoAlerta } from "../emuns/TipoAlerta.js";

export class AlertaRuta {
    private id: string;
    private tipo: TipoAlerta;
    private descripcion: string;
    private timestamp: Date;
    private resuelto: boolean;
    constructor(id: string, tipo: TipoAlerta, descripcion: string, timestamp: Date, resuelto: boolean) {
        this.id = id;
        this.tipo = tipo;
        this.descripcion = descripcion;
        this.timestamp = timestamp;
        this.resuelto = resuelto;
    }
    /** Marca la alerta como resuelta — el Repositorio persiste este cambio en la BD */
    resolverAlerta(): void {
        if (this.resuelto) {
            throw new Error("La alerta ya estaba resuelta");
        }
        this.resuelto = true;
    }

    /** Consulta usada por Viaje.obtenerAlertasPendientes() */
    estaResuelta(): boolean {
        return this.resuelto;
    }

    // ── Getters para el Repositorio ─────────────────────────
    getId(): string { return this.id; }
    getTipo(): TipoAlerta { return this.tipo; }
    getDescripcion(): string { return this.descripcion; }
    getTimestamp(): Date { return this.timestamp; }
}