import { administrador } from "./Administracion.js";

 class AsignacionConductor{
    private idAsignacion : string;
    private fechaInicioAsignacion : Date;
    private fechafinAsignacion : Date;
    constructor(idAsignacion : string, fechaInicioAsignacion : Date, fechafinAsignacion : Date){
        this.idAsignacion = idAsignacion;
        this.fechaInicioAsignacion = fechaInicioAsignacion;
        this.fechafinAsignacion = fechafinAsignacion;
    }   
    AsignarConductor() : void {
    //flata
    }
    finalizarAsignacion() : void {
        //falta completar
    }

}