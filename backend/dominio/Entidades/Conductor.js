"use strict";
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.Conductor = void 0;
var usuario_1 = require("./usuario");
var TipoEvento_1 = require("../emuns/TipoEvento");
var TipoAlerta_1 = require("../emuns/TipoAlerta");
var Conductor = /** @class */ (function (_super) {
    __extends(Conductor, _super);
    function Conductor(id, nombre, email, contraseña, licencia, telefono, sueldo, edad, disponible) {
        if (disponible === void 0) { disponible = true; }
        var _this = _super.call(this, id, nombre, email, contraseña) || this;
        _this.licencia = licencia;
        _this.telefono = telefono;
        _this.sueldo = sueldo;
        _this.edad = edad;
        _this.disponible = disponible;
        return _this;
    }
    Conductor.prototype.aceptarviaje = function (viaje) {
        if (!this.disponible) {
            throw new Error("Conductor ".concat(this.getId(), " no est\u00E1 disponible"));
        }
        this.disponible = false;
        viaje.iniciar();
    };
    Conductor.prototype.finalizarviaje = function (viaje) {
        viaje.finalizar();
        this.disponible = true;
    };
    Conductor.prototype.reportarIncidencia = function (viaje, descripcion) {
        return viaje.registrarIncidencia(TipoEvento_1.TipoEvento.EMERGENCIA, TipoAlerta_1.TipoAlerta.EMERGENCIA, descripcion);
    };
    Conductor.prototype.verHistorialViajes = function () {
        return [];
    };
    Conductor.prototype.getLicencia = function () { return this.licencia; };
    Conductor.prototype.getTelefono = function () { return this.telefono; };
    Conductor.prototype.getSueldo = function () { return this.sueldo; };
    Conductor.prototype.EstadoDisponible = function () { return this.disponible; };
    Conductor.prototype.getId = function () { return _super.prototype.getId.call(this); };
    Conductor.prototype.getnombre = function () { return _super.prototype.getNombre.call(this); };
    Conductor.prototype.getEdad = function () { return this.edad; };
    Conductor.prototype.setSueldo = function (nuevoSueldo) { this.sueldo = nuevoSueldo; };
    Conductor.prototype.setTelefono = function (nuevoTel) { this.telefono = nuevoTel; };
    Conductor.prototype.setLicencia = function (nuevaLic) { this.licencia = nuevaLic; };
    Conductor.prototype.setDisponible = function (valor) { this.disponible = valor; };
    return Conductor;
}(usuario_1.usuario));
exports.Conductor = Conductor;
