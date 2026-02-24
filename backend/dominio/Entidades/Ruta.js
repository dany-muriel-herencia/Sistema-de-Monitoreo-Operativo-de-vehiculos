"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Ruta = void 0;
var PuntoGeo_1 = require("./PuntoGeo");
var Ruta = /** @class */ (function () {
    function Ruta(id, nombre, distanciaTotal, duracionEstimada, puntos) {
        if (puntos === void 0) { puntos = []; }
        this.id = id;
        this.nombre = nombre;
        this.distanciaTotal = distanciaTotal;
        this.duracionEstimada = duracionEstimada;
        this.puntos = puntos;
    }
    Ruta.prototype.calcularDesviacion = function (ubicacion) {
        if (this.puntos.length === 0)
            return 0;
        var puntoActual = new PuntoGeo_1.PuntoGeo("-1", ubicacion.getLatitud(), ubicacion.getLongitud(), -1, "posicion_actual");
        // Distancia mínima al punto más cercano de la ruta
        var distanciaMinima = Infinity;
        for (var _i = 0, _a = this.puntos; _i < _a.length; _i++) {
            var punto = _a[_i];
            var dist = puntoActual.calcularDistancia(punto);
            if (dist < distanciaMinima)
                distanciaMinima = dist;
        }
        return distanciaMinima; // en metros
    };
    /**
     * Dado donde está el vehículo ahora, devuelve el siguiente
     * punto de la ruta que debe alcanzar.
     */
    Ruta.prototype.obtenerSiguienteUbicacion = function (ubicacionActual) {
        if (this.puntos.length === 0)
            return null;
        var puntoActual = new PuntoGeo_1.PuntoGeo("-1", ubicacionActual.getLatitud(), ubicacionActual.getLongitud(), -1, "posicion_actual");
        // Encontrar el punto más cercano de la ruta
        var indiceMasCercano = 0;
        var distanciaMinima = Infinity;
        for (var i = 0; i < this.puntos.length; i++) {
            var dist = puntoActual.calcularDistancia(this.puntos[i]);
            if (dist < distanciaMinima) {
                distanciaMinima = dist;
                indiceMasCercano = i;
            }
        }
        // El siguiente punto es el que sigue en orden
        var indiceNext = indiceMasCercano + 1;
        if (indiceNext >= this.puntos.length)
            return null;
        var siguiente = this.puntos[indiceNext];
        return siguiente !== undefined ? siguiente : null;
    };
    // ── Getters ─────────────────────────────────────────────────
    Ruta.prototype.getId = function () { return this.id; };
    Ruta.prototype.getNombre = function () { return this.nombre; };
    Ruta.prototype.getPuntos = function () { return this.puntos; };
    Ruta.prototype.getDistanciaTotal = function () { return this.distanciaTotal; };
    Ruta.prototype.getDuracionEstimada = function () { return this.duracionEstimada; };
    return Ruta;
}());
exports.Ruta = Ruta;
