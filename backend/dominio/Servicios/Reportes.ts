import { Viaje } from "../Entidades/Viaje";
import { Vehiculo } from "../Entidades/Vehiculo";

export class Reportes {

    /**
     * Genera un resumen del kilometraje total de la flota.
     */
    resumenKilometrajeFlota(vehiculos: Vehiculo[]): number {
        const total = vehiculos.reduce((acc, v) => acc + v.getkilometraje(), 0);
        console.log(`Kilometraje total de la flota: ${total} km.`);
        return total;
    }

    /**
     * Calcula la eficiencia de un vehículo basándose en sus viajes (Placeholder).
     */
    calcularEficienciaVehiculo(placa: string, viajes: Viaje[]): void {
        const viajesVehiculo = viajes.filter(v => v.getIdVehiculo() === placa);
        const totalViajes = viajesVehiculo.length;
        console.log(`El vehículo ${placa} ha realizado ${totalViajes} viajes.`);
        // Aquí se podrían añadir cálculos más complejos como km/combustible si estuviera en el modelo.
    }

    /**
     * Obtiene estadísticas de alertas generadas en un periodo (Placeholder).
     */
    estadisticasAlertas(viajes: Viaje[]): void {
        let totalAlertas = 0;
        viajes.forEach(v => {
            totalAlertas += v.getAlertas().length;
        });
        console.log(`Total de alertas registradas en el sistema: ${totalAlertas}.`);
    }

    /**
     * Genera un reporte de tiempo promedio de viaje.
     */
    promedioDuracionViajes(viajes: Viaje[]): number {
        const viajesFinalizados = viajes.filter(v => v.getFechaFin() !== null);
        if (viajesFinalizados.length === 0) return 0;

        const sumaMinutos = viajesFinalizados.reduce((acc, v) => acc + v.calcularDuracionMinutos(), 0);
        const promedio = sumaMinutos / viajesFinalizados.length;

        console.log(`Duración promedio de los viajes: ${promedio.toFixed(2)} minutos.`);
        return promedio;
    }
}
