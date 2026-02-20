import { EventoOperacion } from "./EventoOperacion.js";
import { usuario } from "./usuario.js";
import { Viaje } from "./Viaje.js";
import { HistorialRecorridos } from "./HistorialRecorridos.js";


export class Conductor extends usuario {
        private licencia :string ;
        private telefono : number ;
        private sueldo : number ;
        private estado : boolean ;
        constructor(id : number, nombre : string, email : string, contraseña : string, licencia : string, telefono : number, sueldo : number, estado : boolean){
            super(id, nombre, email, contraseña);
            this.licencia = licencia;
            this.telefono = telefono;
            this.sueldo = sueldo;
            this.estado = estado;
        }

        aceptarviaje (viaje : Viaje): void{
            //flata completar
        }
        finalizarviaje (viaje : Viaje): void{
            //flata completar
        }
        Incidencia(descripcion : string ): void{
            //falta completar 
        }
        verHistorialViajes() : HistorialRecorridos[] {
            //falta completar
            return [];
        }

}