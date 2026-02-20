import { Viaje } from "./Viaje.js";
import { UbicacionGPS } from "./UbicacionGPS.js";
import { EventoOperacion } from "./EventoOperacion.js";
import { TipoAlerta } from "./emuns/TipoAlerta.js";


export class HistorialRecorridos{
    private idViaje : number ;
    private ubicaciones : UbicacionGPS[] = [];
    private eventos : EventoOperacion[] = [];
    private alertas : TipoAlerta[] = []; 
    constructor(idViaje : number, ubicaciones : UbicacionGPS[], eventos : EventoOperacion[], alertas : TipoAlerta[]){
        this.idViaje = idViaje;
        this.ubicaciones = ubicaciones;
        this.eventos = eventos;
        this.alertas = alertas;
    }
    calcularMetricas (): void {
        //falta completar
    }
    exportar() : void {
        //falta completar
    }



}