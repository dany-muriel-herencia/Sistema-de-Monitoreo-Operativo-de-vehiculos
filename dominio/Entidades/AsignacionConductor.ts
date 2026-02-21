export class AsignacionConductor {
    private idAsignacion: string;
    private idConductor: string;
    private idVehiculo: string;
    private fechaInicioAsignacion: Date;
    private fechafinAsignacion: Date | null;  // null = asignación activa aún
    private activa: boolean;

    constructor(
        idAsignacion: string,
        idConductor: string,
        idVehiculo: string,
        fechaInicioAsignacion: Date,
        fechafinAsignacion: Date | null = null
    ) {
        this.idAsignacion = idAsignacion;
        this.idConductor = idConductor;
        this.idVehiculo = idVehiculo;
        this.fechaInicioAsignacion = fechaInicioAsignacion;
        this.fechafinAsignacion = fechafinAsignacion;
        this.activa = fechafinAsignacion === null;
    }

    /**
     * Activa la asignación conductor-vehículo.
     * Regla: solo si no está ya activa.
     * → El Repositorio persiste el registro en asignaciones_conductor.
     */
    AsignarConductor(): void {
        if (this.activa) {
            throw new Error(`Asignación ${this.idAsignacion} ya está activa`);
        }
        this.activa = true;
        this.fechafinAsignacion = null;
    }

    /**
     * Finaliza la asignación (el conductor deja el vehículo).
     * → El Repositorio actualiza fecha_fin en la BD.
     */
    finalizarAsignacion(): void {
        if (!this.activa) {
            throw new Error(`Asignación ${this.idAsignacion} ya estaba finalizada`);
        }
        this.activa = false;
        this.fechafinAsignacion = new Date();
    }

    /** Calcula cuántos días lleva activa la asignación */
    diasActiva(): number {
        const fin = this.fechafinAsignacion ?? new Date();
        const diffMs = fin.getTime() - this.fechaInicioAsignacion.getTime();
        return Math.floor(diffMs / 1000 / 60 / 60 / 24);
    }

    // ── Getters ─────────────────────────────────────────────────
    getIdAsignacion(): string { return this.idAsignacion; }
    getIdConductor(): string { return this.idConductor; }
    getIdVehiculo(): string { return this.idVehiculo; }
    getFechaInicio(): Date { return this.fechaInicioAsignacion; }
    getFechaFin(): Date | null { return this.fechafinAsignacion; }
    estaActiva(): boolean { return this.activa; }
}