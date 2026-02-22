import { usuario } from "./usuario";
import { Viaje } from "./Viaje";
import { HistorialRecorridos } from "./HistorialRecorridos";
import { TipoEvento } from "../emuns/TipoEvento";
import { TipoAlerta } from "../emuns/TipoAlerta";
import { EventoOperacion } from "./EventoOperacion";
import { AlertaRuta } from "./AlertaRuta";

// ─────────────────────────────────────────────────────────────
//  CLASE CONDUCTOR  –  Entidad del DOMINIO  (hereda de usuario)
//
//  CONEXIONES:
//   • Viaje     → Conductor acepta/finaliza viajes
//   • Repositorio → ConductorRepositorio construye objetos de esta clase
//   • App Móvil → el conductor se autentica y gestiona su viaje activo
// ─────────────────────────────────────────────────────────────

export class Conductor extends usuario {
    private licencia: string;
    private telefono: number;
    private sueldo: number;
    private disponible: boolean;   // renombrado de 'estado' para mayor claridad

    constructor(
        id: string,
        nombre: string,
        email: string,
        contraseña: string,
        licencia: string,
        telefono: number,
        sueldo: number,
        disponible: boolean = true
    ) {
        super(id, nombre, email, contraseña);
        this.licencia = licencia;
        this.telefono = telefono;
        this.sueldo = sueldo;
        this.disponible = disponible;
    }

    // ── Métodos de negocio ──────────────────────────────────────

    /**
     * El conductor acepta un viaje asignado.
     * Regla: solo puede aceptar si está disponible.
     * → Cambia su estado a NO disponible
     * → Inicia el viaje (cambia estado del viaje a EN_CURSO)
     * → El Repositorio persiste ambos cambios
     */
    aceptarviaje(viaje: Viaje): void {
        if (!this.disponible) {
            throw new Error(`Conductor ${this.getId()} no está disponible`);
        }
        this.disponible = false;   // el conductor queda ocupado
        viaje.iniciar();           // delega la lógica al Viaje
    }

    /**
     * El conductor finaliza el viaje en curso.
     * → El viaje se marca como FINALIZADO
     * → El conductor vuelve a estar disponible
     */
    finalizarviaje(viaje: Viaje): void {
        viaje.finalizar();         // delega la lógica al Viaje
        this.disponible = true;    // el conductor queda libre
    }

    /**
     * El conductor reporta una incidencia desde la app móvil.
     * → Crea un EventoOperacion + AlertaRuta dentro del Viaje
     * → El Caso de Uso persiste ambos objetos en la BD
     */
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

    /**
     * Historial de viajes — lo carga el Repositorio (no en memoria).
     * Devuelve vacío por defecto; el Caso de Uso lo hidrata.
     */
    verHistorialViajes(): HistorialRecorridos[] {
        return [];
    }

    // ── Getters (usados por Viaje, Repositorios y App Móvil) ────

    getLicencia(): string { return this.licencia; }
    getTelefono(): number { return this.telefono; }
    getSueldo(): number { return this.sueldo; }
    isDisponible(): boolean { return this.disponible; }
    getId(): string { return super.getId(); }

    // ── Setters ─────────────────────────────────────────────────
    setSueldo(nuevoSueldo: number): void { this.sueldo = nuevoSueldo; }
    setTelefono(nuevoTel: number): void { this.telefono = nuevoTel; }
    setLicencia(nuevaLic: string): void { this.licencia = nuevaLic; }

    /** Cambia disponibilidad — usado por el Repositorio al hidratar */
    setDisponible(valor: boolean): void { this.disponible = valor; }
}
