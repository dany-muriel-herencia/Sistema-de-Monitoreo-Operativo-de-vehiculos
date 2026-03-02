import { Usuario } from "./usuarios";
import { Vehiculo } from "./Vehiculo";
import { Conductor } from "./Conductor";
import { Ruta } from "./Ruta";
import { AsignacionConductor } from "./AsignacionConductor";
import { AlertaRuta } from "./AlertaRuta";

export class Administrador extends Usuario {
    constructor(
        id: number | null,
        nombre: string,
        email: string,
        contrasena: string
    ) {
        super(id, nombre, email, contrasena, 'admin');
    }

    // Estos métodos representan las capacidades del administrador según el diagrama.
    // La implementación concreta de la lógica persistente suele ir en los casos de uso.

    registrarVehiculo(vehiculo: Vehiculo): void {
        // Lógica de validación previa opcional
    }

    registrarConductor(conductor: Conductor): void {
        // Lógica de validación previa opcional
    }

    definirRuta(ruta: Ruta): void {
        // Lógica de validación previa opcional
    }

    asignarConductorAVehiculo(conductor: Conductor, vehiculo: Vehiculo, fechaInicio: Date, fechaFin: Date): AsignacionConductor {
        return new AsignacionConductor(
            "", // ID de asignación inicial vacío
            conductor.getId()!.toString(),
            vehiculo.getPlaca(),
            fechaInicio,
            fechaFin
        );
    }

    gestionarAlertas(alerta: AlertaRuta): void {
        alerta.resolverAlerta();
    }
}
