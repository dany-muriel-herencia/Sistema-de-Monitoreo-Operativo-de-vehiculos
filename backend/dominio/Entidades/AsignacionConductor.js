"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AsignacionConductor = void 0;
var AsignacionConductor = /** @class */ (function () {
    function AsignacionConductor(idAsignacion, idConductor, idVehiculo, fechaInicioAsignacion, fechafinAsignacion) {
        if (fechafinAsignacion === void 0) { fechafinAsignacion = null; }
        this.idAsignacion = idAsignacion;
        this.idConductor = idConductor;
        this.idVehiculo = idVehiculo;
        this.fechaInicioAsignacion = fechaInicioAsignacion;
        this.fechafinAsignacion = fechafinAsignacion;
        this.activa = fechafinAsignacion === null;
    }
    AsignacionConductor.prototype.AsignarConductor = function () {
        if (this.activa) {
            throw new Error("El conductor se encuentra asignado a un vehiculo ");
        }
        this.activa = true;
        this.fechaInicioAsignacion = new Date();
        this.fechafinAsignacion = null;
    };
    AsignacionConductor.prototype.finalizarAsignacion = function () {
        if (!this.activa) {
            throw new Error(" El conductor ya tiene finalizado su asignacion : ");
        }
        this.activa = false;
        this.fechafinAsignacion = new Date();
    };
    AsignacionConductor.prototype.diasActiva = function () {
        var _a;
        var fin = (_a = this.fechafinAsignacion) !== null && _a !== void 0 ? _a : new Date();
        var diffMs = fin.getTime() - this.fechaInicioAsignacion.getTime();
        return Math.floor(diffMs / 1000 / 60 / 60 / 24);
    };
    AsignacionConductor.prototype.getIdAsignacion = function () { return this.idAsignacion; };
    AsignacionConductor.prototype.getIdConductor = function () { return this.idConductor; };
    AsignacionConductor.prototype.getIdVehiculo = function () { return this.idVehiculo; };
    AsignacionConductor.prototype.getFechaInicio = function () { return this.fechaInicioAsignacion; };
    AsignacionConductor.prototype.getFechaFin = function () { return this.fechafinAsignacion; };
    AsignacionConductor.prototype.estaActiva = function () { return this.activa; };
    return AsignacionConductor;
}());
exports.AsignacionConductor = AsignacionConductor;
