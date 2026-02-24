"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AlertaRuta = void 0;
var AlertaRuta = /** @class */ (function () {
    function AlertaRuta(id, tipo, descripcion, timestamp, resuelto) {
        this.id = id;
        this.tipo = tipo;
        this.descripcion = descripcion;
        this.timestamp = timestamp;
        this.resuelto = resuelto;
    }
    AlertaRuta.prototype.resolverAlerta = function () {
        if (this.resuelto) {
            throw new Error("La alerta ya estaba resuelta");
        }
        this.resuelto = true;
    };
    AlertaRuta.prototype.estaResuelta = function () {
        return this.resuelto;
    };
    AlertaRuta.prototype.getId = function () { return this.id; };
    AlertaRuta.prototype.getTipo = function () { return this.tipo; };
    AlertaRuta.prototype.getDescripcion = function () { return this.descripcion; };
    AlertaRuta.prototype.getTimestamp = function () { return this.timestamp; };
    return AlertaRuta;
}());
exports.AlertaRuta = AlertaRuta;
