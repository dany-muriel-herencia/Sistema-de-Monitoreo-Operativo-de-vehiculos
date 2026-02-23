import {IUbicacionRepositorio} from "../../dominio/Repositorios/IUbicacionRepositorio"
import {UbicacionGPS} from "../../dominio/Entidades/UbicacionGPS"
import {pool} from "../../db"

export class UbicacionRepositorio implements IUbicacionRepositorio{
   async guardar(ubicacion:UbicacionGPS): Promise<void>{

   } 
}