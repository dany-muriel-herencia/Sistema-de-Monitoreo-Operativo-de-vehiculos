"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PuntoGeo = void 0;
var PuntoGeo = /** @class */ (function () {
    function PuntoGeo(id, latitud, longitud, orden, descripcion) {
        this.id = id;
        this.latitud = latitud;
        this.longitud = longitud;
        this.orden = orden;
        this.descripcion = descripcion;
    }
    PuntoGeo.prototype.calcularDistancia = function (otroPunto) {
        var R = 6371000;
        var lat1 = this.latitud * Math.PI / 180;
        var lat2 = otroPunto.latitud * Math.PI / 180;
        var dLat = (otroPunto.latitud - this.latitud) * Math.PI / 180;
        var dLon = (otroPunto.longitud - this.longitud) * Math.PI / 180;
        var a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
            + Math.cos(lat1) * Math.cos(lat2)
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    };
    PuntoGeo.prototype.getId = function () { return this.id; };
    PuntoGeo.prototype.getLatitud = function () { return this.latitud; };
    PuntoGeo.prototype.getLongitud = function () { return this.longitud; };
    PuntoGeo.prototype.getOrden = function () { return this.orden; };
    PuntoGeo.prototype.getDescripcion = function () { return this.descripcion; };
    return PuntoGeo;
}());
exports.PuntoGeo = PuntoGeo;
