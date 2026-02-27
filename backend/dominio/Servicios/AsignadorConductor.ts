import { Conductor } from "../Entidades/Conductor";
import { Vehiculo } from "../Entidades/Vehiculo";
import { AsignacionConductor } from "../Entidades/AsignacionConductor";

export class AsignadorConductor {
    /**
     * Coordina la asignación de un conductor a un vehículo.
     * Verifica disponibilidad y crea el objeto de asignación.
     */
    asignar(conductor: Conductor, vehiculo: Vehiculo): AsignacionConductor {
        // 1. Verificar disponibilidad del conductor
        if (!conductor.EstadoDisponible()) {
            throw new Error(`El conductor ${conductor.getNombre()} no está disponible.`);
        }

        // 2. Verificar disponibilidad del vehículo
        if (!vehiculo.estaDisponible()) {
            throw new Error(`El vehículo con placa ${vehiculo.getplaca()} no está disponible.`);
        }

        // 3. Crear el objeto de asignación
        const idAsignacion = Math.random().toString(36).substr(2, 9);
        const nuevaAsignacion = new AsignacionConductor(
            idAsignacion,
            conductor.getId(),
            vehiculo.getId(),
            new Date()
        );

        // 4. Actualizar estados internos (Lógica de dominio)
        // Nota: El guardado en repositorios se hace en la capa de Aplicación (Caso de Uso)
        // para mantener este servicio como "Puro de Dominio".

        return nuevaAsignacion;
    }
}
