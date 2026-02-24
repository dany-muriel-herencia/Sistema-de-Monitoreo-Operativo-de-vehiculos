import { EventoOperacion } from "./EventoOperacion";
import { AlertaRuta } from "./AlertaRuta";
import { TipoEvento } from "../emuns/TipoEvento";
import { TipoAlerta } from "../emuns/TipoAlerta";
import { EstadoViaje } from "../emuns/EstadoViaje";

export class Viaje {

    private id: string;
    private idConductor: string;
    private idVehiculo: string;
    private idRuta: string;
    private estado: EstadoViaje;
    private fechaInicio: Date | null;
    private fechaFin: Date | null;

    private eventos: EventoOperacion[];
    private alertas: AlertaRuta[];

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

    iniciar(): void {
        if (this.estado !== EstadoViaje.PLANIFICADO) {
            throw new Error(`No se puede iniciar un viaje en estado: ${this.estado}`);
        }
        this.estado = EstadoViaje.EN_CURSO;
        this.fechaInicio = new Date();

        const evento = new EventoOperacion(
            "0",
            this.fechaInicio,
            TipoEvento.INICIO_RUTA,
            `Viaje ${this.id} iniciado por el conductor con ID: ${this.idConductor}`);
        this.eventos.push(evento);
    }

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

        return { evento, alerta };
    }

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

    calcularDuracionMinutos(): number {
        if (!this.fechaInicio) return 0;
        const fin = this.fechaFin ?? new Date();
        const diffMs = fin.getTime() - this.fechaInicio.getTime();
        return Math.floor(diffMs / 1000 / 60);
    }

    estaEnCurso(): boolean {
        return this.estado === EstadoViaje.EN_CURSO;
    }

    obtenerAlertasPendientes(): AlertaRuta[] {
        return this.alertas.filter(a => !a.estaResuelta());
    }

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