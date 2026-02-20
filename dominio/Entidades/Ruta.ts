import { Duracion } from "./Duracion.js";

import { UbicacionGPS } from "./UbicacionGPS.js";


export class Ruta {
    private id : number;
    private nombre :string ;
    private PuntosLocalizacion : UbicacionGPS[] = [];
    private distanciaTotal : number;
    private  DuracionEstimada : Duracion  ;
    constructor(id : number, nombre : string, distanciaTotal : number, DuracionEstimada : Duracion, PuntosLocalizacion : UbicacionGPS[]){
        this.id = id;
        this.nombre = nombre;
        this.distanciaTotal = distanciaTotal;
        this.DuracionEstimada = DuracionEstimada;
        this.PuntosLocalizacion = PuntosLocalizacion;
    }
    calcularDesviacion(ubicaion : UbicacionGPS) : void  /*number */ {
        
    }
    obtenerSiguienteUbicacion(ubicacionActual : UbicacionGPS) /*: UbicacionGPS*/ {

    }
}

