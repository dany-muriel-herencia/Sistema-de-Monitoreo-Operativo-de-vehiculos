"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Viaje = void 0;
var EventoOperacion_1 = require("./EventoOperacion");
var AlertaRuta_1 = require("./AlertaRuta");
var TipoEvento_1 = require("../emuns/TipoEvento");
var EstadoViaje_1 = require("../emuns/EstadoViaje");
var Viaje = /** @class */ (function () {
    function Viaje(id, idConductor, idVehiculo, idRuta, estado, fechaInicio, fechaFin, eventos, alertas) {
        if (estado === void 0) { estado = EstadoViaje_1.EstadoViaje.PLANIFICADO; }
        if (fechaInicio === void 0) { fechaInicio = null; }
        if (fechaFin === void 0) { fechaFin = null; }
        if (eventos === void 0) { eventos = []; }
        if (alertas === void 0) { alertas = []; }
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
    Viaje.prototype.iniciar = function () {
        if (this.estado !== EstadoViaje_1.EstadoViaje.PLANIFICADO) {
            throw new Error("No se puede iniciar un viaje en estado: ".concat(this.estado));
        }
        this.estado = EstadoViaje_1.EstadoViaje.EN_CURSO;
        this.fechaInicio = new Date();
        var evento = new EventoOperacion_1.EventoOperacion("0", this.fechaInicio, TipoEvento_1.TipoEvento.INICIO_RUTA, "Viaje ".concat(this.id, " iniciado por el conductor con ID: ").concat(this.idConductor));
        this.eventos.push(evento);
    };
    Viaje.prototype.finalizar = function () {
        if (this.estado !== EstadoViaje_1.EstadoViaje.EN_CURSO) {
            throw new Error("No se puede finalizar un viaje en estado: ".concat(this.estado));
        }
        this.estado = EstadoViaje_1.EstadoViaje.FINALIZADO;
        this.fechaFin = new Date();
        var evento = new EventoOperacion_1.EventoOperacion("0", this.fechaFin, TipoEvento_1.TipoEvento.FIN_RUTA, "Viaje ".concat(this.id, " finalizado. Duraci\u00F3n: ").concat(this.calcularDuracionMinutos(), " min"));
        this.eventos.push(evento);
    };
    Viaje.prototype.registrarIncidencia = function (tipoEvento, tipoAlerta, descripcion) {
        if (this.estado !== EstadoViaje_1.EstadoViaje.EN_CURSO) {
            throw new Error("Solo se pueden registrar incidencias en viajes EN_CURSO");
        }
        var ahora = new Date();
        var evento = new EventoOperacion_1.EventoOperacion("0", ahora, tipoEvento, descripcion);
        this.eventos.push(evento);
        var alerta = new AlertaRuta_1.AlertaRuta("0", tipoAlerta, descripcion, ahora, false);
        this.alertas.push(alerta);
        return { evento: evento, alerta: alerta };
    };
    Viaje.prototype.cancelar = function (motivo) {
        if (this.estado !== EstadoViaje_1.EstadoViaje.PLANIFICADO) {
            throw new Error("Solo se puede cancelar un viaje PLANIFICADO");
        }
        this.estado = EstadoViaje_1.EstadoViaje.CANCELADO;
        var evento = new EventoOperacion_1.EventoOperacion("0", new Date(), TipoEvento_1.TipoEvento.OTRO, "Viaje cancelado: ".concat(motivo));
        this.eventos.push(evento);
    };
    Viaje.prototype.calcularDuracionMinutos = function () {
        var _a;
        if (!this.fechaInicio)
            return 0;
        var fin = (_a = this.fechaFin) !== null && _a !== void 0 ? _a : new Date();
        var diffMs = fin.getTime() - this.fechaInicio.getTime();
        return Math.floor(diffMs / 1000 / 60);
    };
    Viaje.prototype.estaEnCurso = function () {
        return this.estado === EstadoViaje_1.EstadoViaje.EN_CURSO;
    };
    Viaje.prototype.obtenerAlertasPendientes = function () {
        return this.alertas.filter(function (a) { return !a.estaResuelta(); });
    };
    Viaje.prototype.getId = function () { return this.id; };
    Viaje.prototype.getIdConductor = function () { return this.idConductor; };
    Viaje.prototype.getIdVehiculo = function () { return this.idVehiculo; };
    Viaje.prototype.getIdRuta = function () { return this.idRuta; };
    Viaje.prototype.getEstado = function () { return this.estado; };
    Viaje.prototype.getFechaInicio = function () { return this.fechaInicio; };
    Viaje.prototype.getFechaFin = function () { return this.fechaFin; };
    Viaje.prototype.getEventos = function () { return this.eventos; };
    Viaje.prototype.getAlertas = function () { return this.alertas; };
    return Viaje;
}());
exports.Viaje = Viaje;
