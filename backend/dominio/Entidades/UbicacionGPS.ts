import { Ruta } from "./Ruta";

export class UbicacionGPS {
    private idviaje: string;
    private latitud: number;
    private longitud: number;
    private velocidad: number;   
    private fechaHora: Date;

    constructor(idviaje: string, latitud: number, longitud: number, fechaHora: Date, velocidad: number = 0) {
        this.idviaje = idviaje;
        this.latitud = latitud;
        this.longitud = longitud;
        this.fechaHora = fechaHora;
        this.velocidad = velocidad;
    }


    estaEnRuta(ruta: Ruta, tolerancia: number): boolean {
        const desviacion = ruta.calcularDesviacion(this);
        return desviacion <= tolerancia;
    }


    getIdViaje(): string { return this.idviaje; }
    getLatitud(): number { return this.latitud; }
    getLongitud(): number { return this.longitud; }
    getVelocidad(): number { return this.velocidad; }
    getFechaHora(): Date { return this.fechaHora; }
}