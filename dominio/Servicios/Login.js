"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var readline = require("readline");
var usuario_js_1 = require("../Entidades/usuario.js");
var rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});
// Simulación de "base de datos" en memoria
var usuarios = [
    new usuario_js_1.usuario(1, "Admin", "admin@example.com", "1234"),
    new usuario_js_1.usuario(2, "Conductor", "conductor@example.com", "abcd")
];
function menu() {
    console.log("\n--- LOGIN USUARIO ---");
    console.log("1. Iniciar sesión");
    console.log("2. Salir");
    rl.question("Seleccione una opción: ", function (opcion) {
        switch (opcion) {
            case "1":
                rl.question("Email: ", function (email) {
                    rl.question("Contraseña: ", function (contraseña) {
                        var u = usuarios.find(function (user) { return user.login(email, contraseña); });
                        if (u) {
                            console.log("Login exitoso: ".concat(email));
                        }
                        else {
                            console.log("Email o contraseña incorrectos");
                        }
                        menu();
                    });
                });
                break;
            case "2":
                console.log("Saliendo...");
                rl.close();
                break;
            default:
                console.log("Opción inválida");
                menu();
                break;
        }
    });
}
menu();
