import { IConductorRepositorio } from "../../dominio/Repositorios/IConductorRepositorio";
import {Conductor} from "../../dominio/Entidades/Conductor";
import {pool} from "../../db";


export class Gestion_Conductores {
    constructor(private repository: IConductorRepositorio) {}

    async registrar_Conductor(conductor:Conductor): Promise<void>{
        if(this.repository.obtenerPorId(conductor.getId())){
            throw new Error("El conductor ya existe");
        }
        await this.repository.guardar(conductor);

    }

    async obtenerConductor(id :string ):Promise<Conductor>{
        const conductor =await this.repository.obtenerPorId(id);
        if(!conductor){
            throw Error("NO hay registros en la base de datos de la oficina de conductores");
        }
        return conductor;
    }

    async listaDisponibles():Promise<Conductor[]>{
        const conductores=await this.repository.obtenerTodos();
        if(!conductores){
            throw new Error(" no se encuantra ningun Conductor en el sistema : ");

        }
        return conductores.filter(c=>c.EstadoDisponible());
    }

    async darDeBajaConductor(id:string ) :Promise<void>{
        await this.repository.eliminar(id);
        console.log(`Conductor con ID ${id} dado de baja.`);

    }

}

