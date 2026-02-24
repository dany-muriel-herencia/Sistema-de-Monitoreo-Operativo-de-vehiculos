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
exports.administrador = void 0;
var usuario_1 = require("./usuario");
var Vehiculo_1 = require("./Vehiculo");
var Conductor_1 = require("./Conductor");
var Ruta_1 = require("./Ruta");
var AsignacionConductor_1 = require("./AsignacionConductor");
var administrador = /** @class */ (function (_super) {
    __extends(administrador, _super);
    function administrador(id, nombre, email, contraseña) {
        return _super.call(this, id, nombre, email, contraseña) || this;
    }
    administrador.prototype.registrarvehiculo = function (id, marca, placa, modelo, capacidad, kilometraje, estado, año) {
        return new Vehiculo_1.Vehiculo(id, marca, placa, modelo, capacidad, kilometraje, estado, año);
    };
    administrador.prototype.registrarconductor = function (id, nombre, email, contraseña, licencia, telefono, sueldo, edad) {
        return new Conductor_1.Conductor(id, nombre, email, contraseña, licencia, telefono, sueldo, edad);
    };
    administrador.prototype.definirRuta = function (id, nombre, distanciaKm, duracionEstimada, puntos) {
        return new Ruta_1.Ruta(id, nombre, distanciaKm, duracionEstimada, puntos);
    };
    administrador.prototype.asignarConductorAVehiculo = function (conductor, vehiculo, fechaInicio) {
        var idAsignacion = "".concat(vehiculo.getid(), "-").concat(conductor.getId());
        return new AsignacionConductor_1.AsignacionConductor(idAsignacion, conductor.getId(), vehiculo.getid(), fechaInicio);
    };
    return administrador;
}(usuario_1.usuario));
exports.administrador = administrador;
