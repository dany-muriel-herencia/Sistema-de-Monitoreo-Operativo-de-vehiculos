import { IConductorRepositorio } from "../../dominio/Repositorios/IConductorRepositorio";
import { Conductor } from "../../dominio/Entidades/Conductores";
import { ConductorDTO } from "../dtos/ConductorDTO";

export class CrearConductor {
    constructor(private conductorRepo: IConductorRepositorio) { }

    async ejecutar(datos: ConductorDTO): Promise<Conductor> {

        if (!datos.email.includes("@")) {
            throw new Error("Email inválido");
        }

        const nuevoConductor = new Conductor(
            null, // El ID será asignado por la base de datos
            datos.nombre,
            datos.email,
            datos.contrasena || "password_segura", // Esto debería venir cifrado en una implementación real
            datos.licencia,
            datos.telefono,
            datos.sueldo,
            datos.edad,
            true // Disponible por defecto
        );

        await this.conductorRepo.guardar(nuevoConductor);
        return nuevoConductor;
    }
}
