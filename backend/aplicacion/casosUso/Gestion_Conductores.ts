import { Conductor } from "../../dominio/Entidades/Conductores";
import { IConductorRepositorio } from "../../dominio/Repositorios/IConductorRepositorio";

export class Gestion_Conductores {
    constructor(private repository: IConductorRepositorio) { }

    async registrarConductor(conductor: Conductor): Promise<void> {

        await this.repository.guardar(conductor);
        console.log(`Conductor ${conductor.getNombre()} registrado con éxito.`);
    }


    async obtenerConductor(id: string): Promise<Conductor> {
        const conductor = await this.repository.obtenerPorId(id);
        if (!conductor) {
            throw new Error(`Conductor con ID ${id} no encontrado.`);
        }
        return conductor;
    }

    async listarDisponibles(): Promise<Conductor[]> {
        const todos = await this.repository.obtenerTodos();
        return todos.filter(c => c.EstadoDisponible());
    }

    async darDeBajaConductor(id: string): Promise<void> {
        await this.repository.eliminar(id);
        console.log(`Conductor con ID ${id} dado de baja.`);
    }

    async actualizarConductor(id: string, data: any): Promise<void> {
        const conductor = await this.repository.obtenerPorId(id);
        if (!conductor) throw new Error("Conductor no encontrado");

        if (data.nombre) conductor['nombre'] = data.nombre;
        if (data.email) conductor['email'] = data.email;
        if (data.licencia) conductor.setLicencia(data.licencia);
        if (data.telefono) conductor.setTelefono(Number(data.telefono));
        if (data.sueldo) conductor.setSueldo(Number(data.sueldo));
        if (data.edad) conductor['edad'] = Number(data.edad);
        if (data.disponible !== undefined) conductor.setDisponible(Boolean(data.disponible));

        await this.repository.actualizar(conductor);
    }
}