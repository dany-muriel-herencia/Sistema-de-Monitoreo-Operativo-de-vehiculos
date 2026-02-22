import { Estado_Vehiculo } from "../emuns/Estado_Vehiculo";
import { AsignacionConductor } from "./AsignacionConductor";

export class Vehiculo {
    private id: string;
    private marca: string;
    private placa: string;
    private modelo: string;
    private capacidad: number;
    private kilometraje: number;
    private estado: Estado_Vehiculo;
    private año: number;

    constructor(
        id: string,
        marca: string,
        placa: string,
        modelo: string,
        capacidad: number,
        kilometraje: number,
        estado: Estado_Vehiculo,
        año: number
    ) {
        this.id = id;
        this.marca = marca;
        this.placa = placa;
        this.modelo = modelo;
        this.capacidad = capacidad;
        this.kilometraje = kilometraje;
        this.estado = estado;
        this.año = año;
    }

    /**
     * Asigna un conductor al vehículo.
     * Regla: el vehículo debe estar DISPONIBLE.
     * → Cambia estado a EN_SERVICIO y devuelve la AsignacionConductor.
     * → El Repositorio persiste la asignación en la BD.
     */
    asignarConductor(idConductor: string, fechaInicio: Date, fechaFin: Date): AsignacionConductor {
        if (this.estado !== Estado_Vehiculo.DISPONIBLE) {
            throw new Error(`Vehículo ${this.placa} no está disponible (estado: ${this.estado})`);
        }
        const idAsignacion = `${this.id}${idConductor}`;
        this.estado = Estado_Vehiculo.EN_SERVICIO;
        return new AsignacionConductor(idAsignacion, idConductor, this.id, fechaInicio, fechaFin);
    }

    /** Actualiza el kilometraje tras un viaje */
    actualizarKilometraje(kmRecorridos: number): void {
        if (kmRecorridos < 0) throw new Error("Los km recorridos no pueden ser negativos");
        this.kilometraje += kmRecorridos;
    }

    /** Indica si el vehículo puede asignarse a un nuevo viaje */
    estaDisponible(): boolean {
        return this.estado === Estado_Vehiculo.DISPONIBLE;
    }

    // ── Getters ─────────────────────────────────────────────────
    getid(): string { return this.id; }
    getMarca(): string { return this.marca; }
    getplaca(): string { return this.placa; }
    getmodelo(): string { return this.modelo; }
    getcapacidad(): number { return this.capacidad; }
    getkilometraje(): number { return this.kilometraje; }
    getestado(): Estado_Vehiculo { return this.estado; }
    getAño(): number { return this.año; }

    // ── Setters ─────────────────────────────────────────────────
    setEstado(nuevoEstado: Estado_Vehiculo): void { this.estado = nuevoEstado; }
    setkilometraje(nuevoKm: number): void { this.kilometraje = nuevoKm; }
    setModelo(nuevoModelo: string): void { this.modelo = nuevoModelo; }
    setCapacidad(nuevaCapacidad: number): void { this.capacidad = nuevaCapacidad; }
    setPlaca(nuevaPlaca: string): void { this.placa = nuevaPlaca; }
}