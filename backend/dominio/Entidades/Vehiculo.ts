// dominio/Entidades/Vehiculo.ts
import { EstadoVehiculo } from "../emuns/EstadoVehiculo";

export class Vehiculo {
    constructor(
        private id: number | null, // INT AUTO_INCREMENT en BD
        private marca: string,
        private placa: string,
        private modelo: string,
        private capacidad: number,
        private kilometraje: number,
        private estado: EstadoVehiculo,
        private año: number
    ) {}

    // --- MÉTODOS DE ACCESO (Getters) ---
    public getId() { return this.id; }
    public getMarca() { return this.marca; }
    public getPlaca() { return this.placa; }
    public getModelo() { return this.modelo; }
    public getCapacidad() { return this.capacidad; }
    public getKilometraje() { return this.kilometraje; }
    public getEstado() { return this.estado; }
    public getAño() { return this.año; }

    // --- MÉTODOS DE LÓGICA DE NEGOCIO (Comportamiento) ---
    
    // Verifica si el vehículo puede iniciar un nuevo viaje
    public estaDisponibleParaViaje(): boolean {
        return this.estado === EstadoVehiculo.DISPONIBLE;
    }

    // Actualiza el kilometraje después de un recorrido
    public registrarUso(km: number): void {
        if (km < 0) throw new Error("El kilometraje no puede ser negativo");
        this.kilometraje += km;
    }

    // Cambia el estado del vehículo (ej: de DISPONIBLE a EN_RUTA)
    public actualizarEstado(nuevoEstado: EstadoVehiculo): void {
        this.estado = nuevoEstado;
    }
}