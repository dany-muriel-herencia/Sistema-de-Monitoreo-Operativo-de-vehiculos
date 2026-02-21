import { TipoEvento } from "../emuns/TipoEvento.js";


export class EventoOperacion {
    private id: number;
    private timestamp: Date;
    private tipo: TipoEvento;
    private descripcion: string;
    constructor(id: number, timestamp: Date, tipo: TipoEvento, descripcion: string) {
        this.id = id;
        this.timestamp = timestamp;
        this.tipo = tipo;
        this.descripcion = descripcion;
    }
    getTimestamp(): Date { return this.timestamp; }
    getTipo(): TipoEvento { return this.tipo; }
    getDescripcion(): string { return this.descripcion; }
    getId(): number { return this.id; }
}