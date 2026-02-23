import { usuario } from "./usuario";
import { Viaje } from "./Viaje";
import { HistorialRecorridos } from "./HistorialRecorridos";
import { TipoEvento } from "../emuns/TipoEvento";
import { TipoAlerta } from "../emuns/TipoAlerta";
import { EventoOperacion } from "./EventoOperacion";
import { AlertaRuta } from "./AlertaRuta";


export class Conductor extends usuario {
    private licencia: string;
    private telefono: number;
    private edad: number;
    private sueldo: number;
    private disponible: boolean;   

    constructor(
            id: string,
        nombre: string,
            email: string,
        contraseña: string,
            licencia: string,
        telefono: number,
            sueldo: number,
            edad: number,
        disponible: boolean = true
    ) {
        super(id, nombre, email, contraseña);
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
    getId(): string { return super.getId(); }
    getnombre(): string { return super.getNombre(); }


    setSueldo(nuevoSueldo: number): void { this.sueldo = nuevoSueldo; }
    setTelefono(nuevoTel: number): void { this.telefono = nuevoTel; }
    setLicencia(nuevaLic: string): void { this.licencia = nuevaLic; }


    setDisponible(valor: boolean): void { this.disponible = valor; }
}
