"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.usuario = void 0;
var usuario = /** @class */ (function () {
    function usuario(id, nombre, email, contraseña) {
        this.id = id;
        this.nombre = nombre;
        this.email = email;
        this.contraseña = contraseña;
    }
    usuario.prototype.login = function (email, contrasena) {
        return this.email === email && this.contraseña === contrasena;
    };
    usuario.prototype.recuperarContraseña = function (email, nuevaContrasena) {
        if (this.email !== email) {
            throw new Error("Email no coincide con el usuario");
        }
        this.contraseña = nuevaContrasena;
    };
    // ── Getters (usados por Conductor, Administracion y Repositorios) ─
    usuario.prototype.getId = function () { return this.id; };
    usuario.prototype.getNombre = function () { return this.nombre; };
    usuario.prototype.getEmail = function () { return this.email; };
    return usuario;
}());
exports.usuario = usuario;
