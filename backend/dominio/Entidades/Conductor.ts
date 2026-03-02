
import { Viaje } from "./Viaje";
import { HistorialRecorridos } from "./HistorialRecorridos";
import { TipoEvento } from "../emuns/TipoEvento";
import { TipoAlerta } from "../emuns/TipoAlerta";
import { EventoOperacion } from "./EventoOperacion";
import { AlertaRuta } from "./AlertaRuta";
import { Usuario } from "./usuarios";

export class Conductor extends Usuario {
    private licencia: string;
    private telefono: number;
    private edad: number;
    private sueldo: number;
    private disponible: boolean;

    constructor(
        id: number | null,
        nombre: string,
        email: string,
        contrasena: string,
        licencia: string,
        telefono: number,
        sueldo: number,
        edad: number,
        disponible: boolean = true
    ) {
        super(id, nombre, email, contrasena, 'conductor');
        this.licencia = licencia;
        this.telefono = telefono;
        this.sueldo = sueldo;
        this.edad = edad;
        this.disponible = disponible;
    }

    aceptarviaje(viaje: Viaje): void {
        if (!this.disponible) {
            throw new Error(`Conductor ${this.getId()} no está disponible`);
        }
        this.disponible = false;
        viaje.iniciar();
    }

    finalizarviaje(viaje: Viaje): void {
        viaje.finalizar();
        this.disponible = true;
    }

    reportarIncidencia(viaje: Viaje, descripcion: string): {
        evento: EventoOperacion;
        alerta: AlertaRuta;
    } {
        return viaje.registrarIncidencia(
            TipoEvento.EMERGENCIA,
            TipoAlerta.EMERGENCIA,
            descripcion
        );
    }

    verHistorialViajes(): HistorialRecorridos[] {
        return [];
    }

    getLicencia(): string { return this.licencia; }
    getTelefono(): number { return this.telefono; }
    getSueldo(): number { return this.sueldo; }
    EstadoDisponible(): boolean { return this.disponible; }
    getNombre(): string { return super.getNombre(); }
    getEdad(): number { return this.edad; }

    setSueldo(nuevoSueldo: number): void { this.sueldo = nuevoSueldo; }
    setTelefono(nuevoTel: number): void { this.telefono = nuevoTel; }
    setLicencia(nuevaLic: string): void { this.licencia = nuevaLic; }
    setDisponible(valor: boolean): void { this.disponible = valor; }
}
