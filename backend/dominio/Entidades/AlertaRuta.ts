
import { TipoAlerta } from "../emuns/TipoAlerta";

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

    resolverAlerta(): void {
        if (this.resuelto) {
            throw new Error("La alerta ya estaba resuelta");
        }
        this.resuelto = true;
    }


    estaResuelta(): boolean {
        return this.resuelto;
    }


    getId(): string { return this.id; }

    getTipo(): TipoAlerta { return this.tipo; }

    getDescripcion(): string { return this.descripcion; }

    getTimestamp(): Date { return this.timestamp; }
}