import { Viaje } from "../Entidades/Viaje";
import { Vehiculo } from "../Entidades/Vehiculo";

export class Reportes {

    /**
     * Genera un resumen del kilometraje total de la flota.
     */
    resumenKilometrajeFlota(vehiculos: Vehiculo[]): number {
        const total = vehiculos.reduce((acc, v) => acc + v.getkilometraje(), 0);
        return total;
    }

    /**
     * Calcula la eficiencia de un vehículo basándose en sus viajes (Placeholder).
     */
    calcularEficienciaVehiculo(placa: string, viajes: Viaje[]): void {
        const viajesVehiculo = viajes.filter(v => v.getIdVehiculo() === placa);
        const totalViajes = viajesVehiculo.length;
        // Aquí se podrían añadir cálculos más complejos como km/combustible si estuviera en el modelo.
    }


    estadisticasAlertas(viajes: Viaje[]): void {
        let totalAlertas = 0;
        viajes.forEach(v => {
            totalAlertas += v.getAlertas().length;
        });
    }


    promedioDuracionViajes(viajes: Viaje[]): number {
        const viajesFinalizados = viajes.filter(v => v.getFechaFin() !== null);
        if (viajesFinalizados.length === 0) return 0;

        const sumaMinutos = viajesFinalizados.reduce((acc, v) => acc + v.calcularDuracionMinutos(), 0);
        const promedio = sumaMinutos / viajesFinalizados.length;

        return promedio;
    }
}
