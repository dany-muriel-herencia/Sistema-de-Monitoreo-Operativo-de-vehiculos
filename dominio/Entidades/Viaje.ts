import { EventoOperacion } from "./EventoOperacion";
import { AlertaRuta } from "./AlertaRuta";
import { TipoEvento } from "../emuns/TipoEvento";
import { TipoAlerta } from "../emuns/TipoAlerta";
import { EstadoViaje } from "../emuns/EstadoViaje";

// ─────────────────────────────────────────────────────────────
//  CLASE VIAJE  –  Entidad del DOMINIO
//  Representa un viaje en curso o finalizado.
//
//  CONEXIONES con otras capas:
//   • DOMINIO      → usa EventoOperacion, AlertaRuta (entidades del dominio)
//   • REPOSITORIO  → ViajeRepositorio construye/persiste objetos de esta clase
//   • CASO DE USO  → IniciarViaje / FinalizarViaje llaman a los métodos de aquí
//   • CONTROLADOR  → ViajeController recibe HTTP y delega al caso de uso
//   • APP MÓVIL    → el conductor llama POST /api/viajes/:id/iniciar → finalizar
// ─────────────────────────────────────────────────────────────

export class Viaje {

    // ── Atributos ──────────────────────────────────────────────
    private id: string;
    private idConductor: string;
    private idVehiculo: string;
    private idRuta: string;
    private estado: EstadoViaje;
    private fechaInicio: Date | null;
    private fechaFin: Date | null;

    // Colecciones internas — se cargan desde el Repositorio
    private eventos: EventoOperacion[];   // historial de eventos del viaje
    private alertas: AlertaRuta[];        // alertas generadas durante el viaje

    // ── Constructor ────────────────────────────────────────────
    constructor(
        id: string,
        idConductor: string,
        idVehiculo: string,
        idRuta: string,
        estado: EstadoViaje = EstadoViaje.PLANIFICADO,
        fechaInicio: Date | null = null,
        fechaFin: Date | null = null,
        eventos: EventoOperacion[] = [],
        alertas: AlertaRuta[] = []
    ) {
        this.id = id;
        this.idConductor = idConductor;
        this.idVehiculo = idVehiculo;
        this.idRuta = idRuta;
        this.estado = estado;
        this.fechaInicio = fechaInicio;
        this.fechaFin = fechaFin;
        this.eventos = eventos;
        this.alertas = alertas;
    }

    // ── Métodos de negocio ─────────────────────────────────────

    /**
     * INICIAR el viaje.
     * Regla: solo puede iniciarse si está PLANIFICADO.
     * Genera un EventoOperacion de tipo INICIO_RUTA.
     * → El Repositorio persiste el cambio de estado en la BD.
     * → El Conductor pasa a no disponible (llamado desde el Caso de Uso).
     */
    iniciar(): void {
        if (this.estado !== EstadoViaje.PLANIFICADO) {
            throw new Error(`No se puede iniciar un viaje en estado: ${this.estado}`);
        }
        this.estado = EstadoViaje.EN_CURSO;
        this.fechaInicio = new Date();

        // Registrar evento de inicio
        const evento = new EventoOperacion(
            "0",                          // el id real lo asigna la BD
            this.fechaInicio,
            TipoEvento.INICIO_RUTA,
            `Viaje ${this.id} iniciado por conductor ${this.idConductor}`
        );
        this.eventos.push(evento);
    }

    /**
     * FINALIZAR el viaje.
     * Regla: solo puede finalizarse si está EN_CURSO.
     * Genera un EventoOperacion de tipo FIN_RUTA.
     * → El Repositorio persiste el cambio de estado + fecha_hora_fin.
     * → El Conductor vuelve a disponible (llamado desde el Caso de Uso).
     */
    finalizar(): void {
        if (this.estado !== EstadoViaje.EN_CURSO) {
            throw new Error(`No se puede finalizar un viaje en estado: ${this.estado}`);
        }
        this.estado = EstadoViaje.FINALIZADO;
        this.fechaFin = new Date();

        const evento = new EventoOperacion(
            "0",
            this.fechaFin,
            TipoEvento.FIN_RUTA,
            `Viaje ${this.id} finalizado. Duración: ${this.calcularDuracionMinutos()} min`
        );
        this.eventos.push(evento);
    }

    /**
     * REGISTRAR INCIDENCIA durante el viaje.
     * Ej: falla mecánica, emergencia, exceso de velocidad.
     * → Se crea un EventoOperacion y una AlertaRuta.
     * → El Caso de Uso persiste ambos con sus Repositorios.
     */
    registrarIncidencia(tipoEvento: TipoEvento, tipoAlerta: TipoAlerta, descripcion: string): {
        evento: EventoOperacion;
        alerta: AlertaRuta;
    } {
        if (this.estado !== EstadoViaje.EN_CURSO) {
            throw new Error("Solo se pueden registrar incidencias en viajes EN_CURSO");
        }

        const ahora = new Date();

        const evento = new EventoOperacion("0", ahora, tipoEvento, descripcion);
        this.eventos.push(evento);

        const alerta = new AlertaRuta("0", tipoAlerta, descripcion, ahora, false);
        this.alertas.push(alerta);

        // Retorna ambos objetos para que el Caso de Uso los persista en la BD
        return { evento, alerta };
    }

    /**
     * CANCELAR el viaje.
     * Solo si está en estado PLANIFICADO.
     */
    cancelar(motivo: string): void {
        if (this.estado !== EstadoViaje.PLANIFICADO) {
            throw new Error("Solo se puede cancelar un viaje PLANIFICADO");
        }
        this.estado = EstadoViaje.CANCELADO;

        const evento = new EventoOperacion(
            "0",
            new Date(),
            TipoEvento.OTRO,
            `Viaje cancelado: ${motivo}`
        );
        this.eventos.push(evento);
    }

    /**
     * Calcula la duración del viaje en minutos.
     * Disponible para HistorialRecorridos.calcularMetricas()
     */
    calcularDuracionMinutos(): number {
        if (!this.fechaInicio) return 0;
        const fin = this.fechaFin ?? new Date();
        const diffMs = fin.getTime() - this.fechaInicio.getTime();
        return Math.floor(diffMs / 1000 / 60);
    }

    /**
     * Indica si el viaje está actualmente en progreso.
     * Usado por el panel de administración y la app móvil.
     */
    estaEnCurso(): boolean {
        return this.estado === EstadoViaje.EN_CURSO;
    }

    /**
     * Retorna las alertas NO resueltas para mostrar en la app.
     */
    obtenerAlertasPendientes(): AlertaRuta[] {
        return this.alertas.filter(a => !a.estaResuelta());
    }

    // ── Getters (usados por Repositorios y Casos de Uso) ──────

    getId(): string { return this.id; }
    getIdConductor(): string { return this.idConductor; }
    getIdVehiculo(): string { return this.idVehiculo; }
    getIdRuta(): string { return this.idRuta; }
    getEstado(): EstadoViaje { return this.estado; }
    getFechaInicio(): Date | null { return this.fechaInicio; }
    getFechaFin(): Date | null { return this.fechaFin; }
    getEventos(): EventoOperacion[] { return this.eventos; }
    getAlertas(): AlertaRuta[] { return this.alertas; }
}