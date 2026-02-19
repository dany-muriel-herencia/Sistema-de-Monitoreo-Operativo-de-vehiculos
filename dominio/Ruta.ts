import { Duracion } from "./Duracion";
class ruta {
    private id : number;
    private nombre :string ;
    private distanciaTotal : number;
    private  DuracionEstimada : Duracion  ;
    constructor(id : number, nombre : string, distanciaTotal : number, DuracionEstimada : Duracion){
        this.id = id;
        this.nombre = nombre;
        this.distanciaTotal = distanciaTotal;
        this.DuracionEstimada = DuracionEstimada;
    }
}

