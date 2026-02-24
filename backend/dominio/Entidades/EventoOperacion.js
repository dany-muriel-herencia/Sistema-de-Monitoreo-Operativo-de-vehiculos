"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.EventoOperacion = void 0;
var EventoOperacion = /** @class */ (function () {
    function EventoOperacion(id, timestamp, tipo, descripcion) {
        this.id = id;
        this.timestamp = timestamp;
        this.tipo = tipo;
        this.descripcion = descripcion;
    }
    EventoOperacion.prototype.getTimestamp = function () { return this.timestamp; };
    EventoOperacion.prototype.getTipo = function () { return this.tipo; };
    EventoOperacion.prototype.getDescripcion = function () { return this.descripcion; };
    EventoOperacion.prototype.getId = function () { return this.id; };
    return EventoOperacion;
}());
exports.EventoOperacion = EventoOperacion;
