import { Viaje } from "../../dominio/Entidades/Viaje";
import { Vehiculo } from "../../dominio/Entidades/Vehiculo";

export class Reportes {

    /**
     * Genera un resumen del kilometraje total de la flota.
     */
    resumenKilometrajeFlota(vehiculos: Vehiculo[]): number {
        // Corregido: getKilometraje() con K mayúscula
        const total = vehiculos.reduce((acc, v) => acc + v.getKilometraje(), 0);
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


    /**
     * Calcula el promedio de duración de los viajes que ya finalizaron.
     */
    promedioDuracionViajes(viajes: Viaje[]): number {
        const viajesFinalizados = viajes.filter(v => v.getFechaFin() !== null);
        if (viajesFinalizados.length === 0) return 0;

        // Sumamos la diferencia en minutos entre fecha fin e inicio
        const sumaMinutos = viajesFinalizados.reduce((acc, v) => {
            const inicio = v.getFechaInicio()!.getTime();
            const fin = v.getFechaFin()!.getTime();
            return acc + ((fin - inicio) / (1000 * 60));
        }, 0);

        return sumaMinutos / viajesFinalizados.length;
    }
}
