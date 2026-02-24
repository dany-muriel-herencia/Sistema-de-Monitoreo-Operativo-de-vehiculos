"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Duracion = void 0;
var Duracion = /** @class */ (function () {
    function Duracion(horas, minutos) {
        if (horas < 0 || minutos < 0 || minutos >= 60) {
            throw new Error("Duración inválida: horas >= 0 y 0 <= minutos < 60");
        }
        this.horas = horas;
        this.minutos = minutos;
    }
    Duracion.prototype.enMinutos = function () {
        return this.horas * 60 + this.minutos;
    };
    Duracion.prototype.toString = function () {
        if (this.horas === 0)
            return "".concat(this.minutos, " min");
        if (this.minutos === 0)
            return "".concat(this.horas, " h");
        return "".concat(this.horas, " h ").concat(this.minutos, " min");
    };
    Duracion.prototype.getHoras = function () { return this.horas; };
    Duracion.prototype.getMinutos = function () { return this.minutos; };
    return Duracion;
}());
exports.Duracion = Duracion;
