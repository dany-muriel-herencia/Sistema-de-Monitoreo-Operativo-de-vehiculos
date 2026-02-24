"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Vehiculo = void 0;
var Estado_Vehiculo_1 = require("../emuns/Estado_Vehiculo");
var AsignacionConductor_1 = require("./AsignacionConductor");
var Vehiculo = /** @class */ (function () {
    function Vehiculo(id, marca, placa, modelo, capacidad, kilometraje, estado, año) {
        this.id = id;
        this.marca = marca;
        this.placa = placa;
        this.modelo = modelo;
        this.capacidad = capacidad;
        this.kilometraje = kilometraje;
        this.estado = estado;
        this.año = año;
    }
    Vehiculo.prototype.asignarConductor = function (idConductor, fechaInicio, fechaFin) {
        if (this.estado !== Estado_Vehiculo_1.Estado_Vehiculo.DISPONIBLE) {
            throw new Error("Veh\u00EDculo ".concat(this.placa, " no est\u00E1 disponible (estado: ").concat(this.estado, ")"));
        }
        var idAsignacion = "".concat(this.id).concat(idConductor);
        this.estado = Estado_Vehiculo_1.Estado_Vehiculo.EN_SERVICIO;
        return new AsignacionConductor_1.AsignacionConductor(idAsignacion, idConductor, this.id, fechaInicio, fechaFin);
    };
    Vehiculo.prototype.actualizarKilometraje = function (kmRecorridos) {
        if (kmRecorridos < 0)
            throw new Error("Los km recorridos no pueden ser negativos");
        this.kilometraje += kmRecorridos;
    };
    Vehiculo.prototype.estaDisponible = function () {
        return this.estado === Estado_Vehiculo_1.Estado_Vehiculo.DISPONIBLE;
    };
    Vehiculo.prototype.getid = function () { return this.id; };
    Vehiculo.prototype.getMarca = function () { return this.marca; };
    Vehiculo.prototype.getplaca = function () { return this.placa; };
    Vehiculo.prototype.getmodelo = function () { return this.modelo; };
    Vehiculo.prototype.getcapacidad = function () { return this.capacidad; };
    Vehiculo.prototype.getkilometraje = function () { return this.kilometraje; };
    Vehiculo.prototype.getestado = function () { return this.estado; };
    Vehiculo.prototype.getAño = function () { return this.año; };
    Vehiculo.prototype.isDisponible = function () { return this.estado === Estado_Vehiculo_1.Estado_Vehiculo.DISPONIBLE; };
    Vehiculo.prototype.getId = function () { return this.id; };
    Vehiculo.prototype.setEstado = function (nuevoEstado) { this.estado = nuevoEstado; };
    Vehiculo.prototype.setModelo = function (nuevoModelo) { this.modelo = nuevoModelo; };
    Vehiculo.prototype.setCapacidad = function (nuevaCapacidad) { this.capacidad = nuevaCapacidad; };
    Vehiculo.prototype.setPlaca = function (nuevaPlaca) { this.placa = nuevaPlaca; };
    return Vehiculo;
}());
exports.Vehiculo = Vehiculo;
