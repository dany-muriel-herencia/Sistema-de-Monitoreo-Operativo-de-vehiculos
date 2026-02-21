
import { TipoAlerta } from "../emuns/TipoAlerta.js";

export class AlertaRuta {
    private id: number;
    private tipo: TipoAlerta;
    private descripcion: string;
    private timesatmp: Date;
    private resuelto: boolean;
    constructor(id: number, tipo: TipoAlerta, descripcion: string, timesatmp: Date, resuelto: boolean) {
        this.id = id;
        this.tipo = tipo;
        this.descripcion = descripcion;
        this.timesatmp = timesatmp;
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
    getId(): number { return this.id; }
    getTipo(): TipoAlerta { return this.tipo; }
    getDescripcion(): string { return this.descripcion; }
    getTimestamp(): Date { return this.timesatmp; }
}