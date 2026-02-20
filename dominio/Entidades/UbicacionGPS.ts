import { Ruta } from "./Ruta.js";

export class UbicacionGPS {
    private idviaje :string ;
    //private date : timestate;
    private latitud : number;
    private longitud : number;
    private fechaHora : Date;

    constructor(idviaje : string, latitud : number, longitud : number, fechaHora : Date) {
        this.idviaje = idviaje;
        this.latitud = latitud;
        this.longitud = longitud;
        this.fechaHora = fechaHora;
    }
    estaEnRuta(ruta : Ruta , tolerancia : number ) : boolean {
        // Logic to determine if this UbicacionGPS is part of a given ruta
        return false; // Placeholder return value
    }
}