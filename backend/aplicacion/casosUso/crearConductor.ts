import { IConductorRepositorio } from "../../dominio/Repositorios/IConductorRepositorio";
import { Conductor } from "../../dominio/Entidades/Conductor";
import { ConductorDTO } from "../dtos/ConductorDTO";
import { randomUUID } from "crypto";

export class CrearConductor {
    constructor(private conductorRepo: IConductorRepositorio) { }

    async ejecutar(datos: ConductorDTO): Promise<Conductor> {

        if (!datos.email.includes("@")) {
            throw new Error("Email inválido");
        }

        const id = randomUUID();

        const nuevoConductor = new Conductor(
            id,
            datos.nombre,
            datos.email,
            datos.contraseña || "password_segura", // Esto debería venir cifrado en una implementación real
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
