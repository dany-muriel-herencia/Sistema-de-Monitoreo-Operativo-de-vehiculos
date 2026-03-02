// dominio/Entidades/Vehiculo.ts
import { EstadoVehiculo } from "../emuns/EstadoVehiculo";

export class Vehiculo {
    public id: number | null;
    public marca: string;
    public placa: string;
    public modelo: string;
    public capacidad: number;
    public kilometraje: number;
    public estado: EstadoVehiculo;
    public anio: number;

    constructor(
        id: number | null,
        marca: string,
        placa: string,
        modelo: string,
        capacidad: number,
        kilometraje: number,
        estado: EstadoVehiculo,
        anio: number
    ) {
        this.id = id;
        this.marca = marca;
        this.placa = placa;
        this.modelo = modelo;
        this.capacidad = capacidad;
        this.kilometraje = kilometraje;
        this.estado = estado;
        this.anio = anio;
    }

    // --- MÉTODOS DE ACCESO (Getters) ---
    public getId() { return this.id; }
    public getMarca() { return this.marca; }
    public getPlaca() { return this.placa; }
    public getModelo() { return this.modelo; }
    public getCapacidad() { return this.capacidad; }
    public getKilometraje() { return this.kilometraje; }
    public getEstado() { return this.estado; }
    public getAnio() { return this.anio; }

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