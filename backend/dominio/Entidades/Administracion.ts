import { usuario } from "./usuario";
import { Vehiculo } from "./Vehiculo";
import { Estado_Vehiculo } from "../emuns/Estado_Vehiculo";
import { Conductor } from "./Conductor";
import { Ruta } from "./Ruta";
import { Duracion } from "./Duracion";
import { PuntoGeo } from "./PuntoGeo";
import { AsignacionConductor } from "./AsignacionConductor";

export class administrador extends usuario {

    constructor(id: string, nombre: string, email: string, contraseña: string) {
        super(id, nombre, email, contraseña);
    }


    registrarvehiculo(
        id: string,
        marca: string,
        placa: string,
        modelo: string,
        capacidad: number,
        kilometraje: number,
        estado: Estado_Vehiculo,
        año: number
    ): Vehiculo {
        return new Vehiculo(id, marca, placa, modelo, capacidad, kilometraje, estado, año);
    }


    registrarconductor(
        id: string,
        nombre: string,
        email: string,
        contraseña: string,
        licencia: string,
        telefono: number,
        sueldo: number,
        edad: number
    ): Conductor {
        return new Conductor(id, nombre, email, contraseña, licencia, telefono, sueldo, edad);
    }


    definirRuta(
        id: string,
        nombre: string,
        distanciaKm: number,
        duracionEstimada: Duracion,
        puntos: PuntoGeo[]
    ): Ruta {
        return new Ruta(id, nombre, distanciaKm, duracionEstimada, puntos);
    }


    asignarConductorAVehiculo(conductor: Conductor,vehiculo: Vehiculo,fechaInicio: Date): AsignacionConductor {
        
        const idAsignacion = `${vehiculo.getid()}-${conductor.getId()}`;
        
        return new AsignacionConductor(
            idAsignacion,
            conductor.getId(),
            vehiculo.getid(),
            fechaInicio
        );
    }
}