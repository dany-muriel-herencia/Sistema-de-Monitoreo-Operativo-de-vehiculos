import { Viaje } from "../Entidades/Viaje";
import { EstadoViaje } from "../emuns/EstadoViaje";

export class ValidadorViaje {
    /**
     * Verifica que un viaje cumpla reglas de negocio antes de iniciar o finalizar.
     */
    validar(viaje: Viaje): boolean {
        // 1. Validar que la ruta esté definida (ya viene en la entidad)
        if (!viaje.getIdRuta()) {
            throw new Error("El viaje no tiene una ruta asignada.");
        }

        // 2. Comprobar que no esté cancelado o finalizado si se quiere operar
        if (viaje.getEstado() === EstadoViaje.CANCELADO || viaje.getEstado() === EstadoViaje.FINALIZADO) {
            throw new Error(`Operación no permitida: El viaje está ${viaje.getEstado()}`);
        }

        return true;
    }

    /**
     * Verifica conflictos (ejemplo: si el viaje ya tiene alertas críticas sin resolver)
     */
    tieneConflictos(viaje: Viaje): boolean {
        return viaje.obtenerAlertasPendientes().length > 0;
    }
}
