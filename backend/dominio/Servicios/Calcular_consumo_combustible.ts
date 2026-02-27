export class CalculadorConsumo {

    obtenerRendimiento(kmRecorridos: number, litrosUsados: number): number {
        if (litrosUsados <= 0) return 0;
        return kmRecorridos / litrosUsados;
    }


    calcularGastoTotal(kmRecorridos: number, consumoPromedioPorKm: number): number {
        return kmRecorridos * consumoPromedioPorKm;
    }
}