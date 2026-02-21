import { usuario } from "./usuario.js";
import { Vehiculo } from "./Vehiculo.js";
import { Estado_Vehiculo } from "../emuns/Estado_Vehiculo.js";
import { Conductor } from "./Conductor.js";
import { Ruta } from "./Ruta.js";
import { Duracion } from "./Duracion.js";
import { PuntoGeo } from "./PuntoGeo.js";
import { AsignacionConductor } from "./AsignacionConductor.js";

export class administrador extends usuario {

    constructor(id: string, nombre: string, email: string, contraseña: string) {
        super(id, nombre, email, contraseña);
    }

    /**
     * Crea y devuelve un nuevo Vehiculo.
     * → El Repositorio se encarga de guardarlo en la BD.
     */
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

    /**
     * Crea y devuelve un nuevo Conductor.
     * → El Repositorio se encarga de guardarlo en la BD.
     */
    registrarconductor(
        id: string,
        nombre: string,
        email: string,
        contraseña: string,
        licencia: string,
        telefono: number,
        sueldo: number
    ): Conductor {
        return new Conductor(id, nombre, email, contraseña, licencia, telefono, sueldo);
    }

    /**
     * Crea y devuelve una nueva Ruta con sus puntos.
     * → El Repositorio la persiste con sus puntos_ruta en la BD.
     */
    definirRuta(
        id: number,
        nombre: string,
        distanciaKm: number,
        duracionEstimada: Duracion,
        puntos: PuntoGeo[]
    ): Ruta {
        return new Ruta(id, nombre, distanciaKm, duracionEstimada, puntos);
    }

    /**
     * Asigna un conductor a un vehículo.
     * → Devuelve la AsignacionConductor para que el Repositorio la persista.
     */
    asignarConductorAVehiculo(
        conductor: Conductor,
        vehiculo: Vehiculo,
        fechaInicio: Date
    ): AsignacionConductor {
        const idAsignacion = `${vehiculo.getid()}-${conductor.getId()}`;
        return new AsignacionConductor(
            idAsignacion,
            conductor.getId(),
            vehiculo.getid(),
            fechaInicio
        );
    }
}