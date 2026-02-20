
import { TipoAlerta } from "./emuns/TipoAlerta.js";

export class AlertaRuta {
    private id : number ;
    private tipo : TipoAlerta;
    private descripcion : string ;
    private timesatmp : Date ;
    private resuelto : boolean;
    constructor(id : number, tipo : TipoAlerta, descripcion : string, timesatmp : Date, resuelto : boolean){
        this.id = id;
        this.tipo = tipo;
        this.descripcion = descripcion;
        this.timesatmp = timesatmp;
        this.resuelto = resuelto;
    }
    resolverAlerta(): void {
        //falta completar
    }     

}