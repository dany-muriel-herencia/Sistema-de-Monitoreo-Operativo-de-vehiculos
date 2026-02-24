"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.UbicacionGPS = void 0;
var UbicacionGPS = /** @class */ (function () {
    function UbicacionGPS(idviaje, latitud, longitud, fechaHora, velocidad) {
        if (velocidad === void 0) { velocidad = 0; }
        this.idviaje = idviaje;
        this.latitud = latitud;
        this.longitud = longitud;
        this.fechaHora = fechaHora;
        this.velocidad = velocidad;
    }
    UbicacionGPS.prototype.estaEnRuta = function (ruta, tolerancia) {
        var desviacion = ruta.calcularDesviacion(this);
        return desviacion <= tolerancia;
    };
    UbicacionGPS.prototype.getIdViaje = function () { return this.idviaje; };
    UbicacionGPS.prototype.getLatitud = function () { return this.latitud; };
    UbicacionGPS.prototype.getLongitud = function () { return this.longitud; };
    UbicacionGPS.prototype.getVelocidad = function () { return this.velocidad; };
    UbicacionGPS.prototype.getFechaHora = function () { return this.fechaHora; };
    return UbicacionGPS;
}());
exports.UbicacionGPS = UbicacionGPS;
