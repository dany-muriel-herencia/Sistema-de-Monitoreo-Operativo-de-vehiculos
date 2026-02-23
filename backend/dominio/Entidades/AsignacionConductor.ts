export class AsignacionConductor {
    private idAsignacion: string;
    private idConductor: string;
    private idVehiculo: string;
    private fechaInicioAsignacion: Date;
    private fechafinAsignacion: Date | null;  
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
    AsignarConductor(): void {
        if (this.activa) {
            throw new Error("El conductor se encuentra asignado a un vehiculo ");

        }
        this.activa = true;
        this.fechaInicioAsignacion = new Date();
        this.fechafinAsignacion = null;
    }

    finalizarAsignacion(): void {
        if (!this.activa) {
            throw new Error(" El conductor ya tiene finalizado su asignacion : ");
        }
        this.activa = false;
        this.fechafinAsignacion = new Date();
    }
    diasActiva() {
        const fin = this.fechafinAsignacion ?? new Date();
        const diffMs = fin.getTime() - this.fechaInicioAsignacion.getTime();
        return Math.floor(diffMs / 1000 / 60 / 60 / 24);
    }




    getIdAsignacion(): string { return this.idAsignacion; }

    getIdConductor(): string { return this.idConductor; }

    getIdVehiculo(): string { return this.idVehiculo; }
    getFechaInicio(): Date { return this.fechaInicioAsignacion; }

    getFechaFin(): Date | null { return this.fechafinAsignacion; }
    estaActiva(): boolean { return this.activa; }
}