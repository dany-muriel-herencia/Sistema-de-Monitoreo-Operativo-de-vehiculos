import { usuario } from "./usuario";

export class administrador extends usuario{
    constructor(id : number, nombre : string, email : string, contraseña : string){
        super(id, nombre, email, contraseña);
    }
    registrarvehiculo (id : number, marca : string, modelo : string, año : number): void{
        //falta completar ,se realixzara cunado se complete la base de datos en sql
    }


    registrarconductor (id : number, nombre : string, licencia : string): void{
        //falta completar ,se realixzara cunado se complete la base de datos en sql
    }
    definirRuta(origen : string, destino : string): void{
        
    }
}