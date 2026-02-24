"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.HistorialRecorridos = void 0;
var HistorialRecorridos = /** @class */ (function () {
    function HistorialRecorridos(idViaje, ubicaciones, eventos, alertas) {
        if (ubicaciones === void 0) { ubicaciones = []; }
        if (eventos === void 0) { eventos = []; }
        if (alertas === void 0) { alertas = []; }
        this.idViaje = idViaje;
        this.ubicaciones = ubicaciones;
        this.eventos = eventos;
        this.alertas = alertas;
    }
    HistorialRecorridos.prototype.calcularMetricas = function () {
        var alertasSinResolver = this.alertas.filter(function (a) { return !a.estaResuelta(); }).length;
        var velocidades = this.ubicaciones.map(function (u) { return u.getVelocidad(); }).filter(function (v) { return v > 0; });
        var velocidadPromedio = velocidades.length > 0 ? velocidades.reduce(function (sum, v) { return sum + v; }, 0) / velocidades.length : 0;
        return {
            totalPuntosGPS: this.ubicaciones.length,
            totalEventos: this.eventos.length,
            totalAlertas: this.alertas.length,
            alertasSinResolver: alertasSinResolver,
            velocidadPromedio: Math.round(velocidadPromedio * 10) / 10
        };
    };
    HistorialRecorridos.prototype.exportar = function () {
        var metricas = this.calcularMetricas();
        return {
            idViaje: this.idViaje,
            metricas: metricas,
            eventos: this.eventos.map(function (e) { return ({
                timestamp: e.getTimestamp(),
                tipo: e.getTipo(),
                descripcion: e.getDescripcion()
            }); }),
            alertas: this.alertas.map(function (a) { return ({
                tipo: a.getTipo(),
                descripcion: a.getDescripcion(),
                timestamp: a.getTimestamp(),
                resuelta: a.estaResuelta()
            }); })
        };
    };
    HistorialRecorridos.prototype.getIdViaje = function () { return this.idViaje; };
    HistorialRecorridos.prototype.getUbicaciones = function () { return this.ubicaciones; };
    HistorialRecorridos.prototype.getEventos = function () { return this.eventos; };
    HistorialRecorridos.prototype.getAlertas = function () { return this.alertas; };
    return HistorialRecorridos;
}());
exports.HistorialRecorridos = HistorialRecorridos;
