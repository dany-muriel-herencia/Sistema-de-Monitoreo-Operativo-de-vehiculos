

import * as readline from "readline";
import { usuario } from "../Entidades/usuario";


const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

// Simulación de "base de datos" en memoria
const usuarios: usuario[] = [
  new usuario("1", "Admin", "admin@example.com", "1234"),
  new usuario("2", "Conductor", "conductor@example.com", "abcd")
];

function menu() {
  console.log("\n--- LOGIN USUARIO ---");
  console.log("1. Iniciar sesión");
  console.log("2. Salir");
  rl.question("Seleccione una opción: ", opcion => {
    switch (opcion) {
      case "1":
        rl.question("Email: ", email => {
          rl.question("Contraseña: ", contraseña => {
            const u = usuarios.find(user => user.login(email, contraseña));
            if (u) {
              console.log(`Login exitoso: ${email}`);
            } else {
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

