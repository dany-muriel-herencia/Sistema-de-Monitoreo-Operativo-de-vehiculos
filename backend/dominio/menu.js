"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g = Object.create((typeof Iterator === "function" ? Iterator : Object).prototype);
    return g.next = verb(0), g["throw"] = verb(1), g["return"] = verb(2), typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (g && (g = 0, op[0] && (_ = 0)), _) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
Object.defineProperty(exports, "__esModule", { value: true });
var readline = require("readline");
var Administracion_1 = require("./Entidades/Administracion");
var Estado_Vehiculo_1 = require("./emuns/Estado_Vehiculo");
var Duracion_1 = require("./Entidades/Duracion");
var PuntoGeo_1 = require("./Entidades/PuntoGeo");
var Viaje_1 = require("./Entidades/Viaje");
var HistorialRecorridos_1 = require("./Entidades/HistorialRecorridos");
var UbicacionGPS_1 = require("./Entidades/UbicacionGPS");
var TipoEvento_1 = require("./emuns/TipoEvento");
var TipoAlerta_1 = require("./emuns/TipoAlerta");
// Configuración de Readline para interface en consola
var rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});
var menu = function () {
    console.log("\n=============================================\n==== SISTEMA DE MONITOREO DE VEH\u00CDCULOS ====\n=============================================\n1. Inicializar Sistema (Crear Admin, Veh\u00EDculo, Conductor, Ruta)\n2. Asignar Conductor a Veh\u00EDculo\n3. Iniciar Viaje\n4. Simular Movimiento (Avanzar GPS y Registrar Incidencia)\n5. Finalizar Viaje y Ver M\u00E9tricas del Historial\n0. Salir\n=============================================\nElija una opci\u00F3n: ");
};
// Variables globales para mantener el estado
var admin;
var vehiculoG;
var conductorG;
var rutaG;
var viajeActivo = null;
var historial = null;
var ubicacionesSimuladas = [];
var presionarEnter = function () {
    return new Promise(function (resolve) {
        rl.question('\nPresione "Enter" para continuar...', function () {
            resolve();
        });
    });
};
var loopMenu = function () { return __awaiter(void 0, void 0, void 0, function () {
    return __generator(this, function (_a) {
        menu();
        rl.question('> ', function (opcion) { return __awaiter(void 0, void 0, void 0, function () {
            var _a, puntos, asignacion, loc1, loc2, exportado;
            return __generator(this, function (_b) {
                switch (_b.label) {
                    case 0:
                        _a = opcion.trim();
                        switch (_a) {
                            case '1': return [3 /*break*/, 1];
                            case '2': return [3 /*break*/, 3];
                            case '3': return [3 /*break*/, 5];
                            case '4': return [3 /*break*/, 7];
                            case '5': return [3 /*break*/, 9];
                            case '0': return [3 /*break*/, 11];
                        }
                        return [3 /*break*/, 12];
                    case 1:
                        console.log("\n[!] Paso 1: Inicializando sistema...");
                        admin = new Administracion_1.administrador("admin-1", "Dany Muriel", "dany@flota.com", "1234");
                        console.log("   -> Administrador creado:", admin.getNombre());
                        vehiculoG = admin.registrarvehiculo("V-001", "Toyota", "ABC-123", "Corolla", 5, 12000, Estado_Vehiculo_1.Estado_Vehiculo.DISPONIBLE, 2022);
                        console.log("   -> Vehículo registrado:", vehiculoG.getplaca(), "-", vehiculoG.getMarca());
                        conductorG = admin.registrarconductor("C-001", "Juan Perez", "juan@flota.com", "pass", "LIC-999", 987654321, 1500, 35);
                        console.log("   -> Conductor registrado:", conductorG.getnombre(), "- Licencia:", conductorG.getLicencia());
                        puntos = [
                            new PuntoGeo_1.PuntoGeo("P-1", -12.04318, -77.02824, 1, "Punto Inicial Lima"),
                            new PuntoGeo_1.PuntoGeo("P-2", -12.04500, -77.03000, 2, "Intersección A"),
                            new PuntoGeo_1.PuntoGeo("P-3", -12.05000, -77.03500, 3, "Punto Final Lima")
                        ];
                        rutaG = admin.definirRuta("R-001", "Ruta Centro", 15.5, new Duracion_1.Duracion(1, 45), puntos);
                        console.log("   -> Ruta creada:", rutaG.getNombre(), "con", rutaG.getPuntos().length, "puntos de control.");
                        return [4 /*yield*/, presionarEnter()];
                    case 2:
                        _b.sent();
                        return [3 /*break*/, 14];
                    case 3:
                        if (!admin || !vehiculoG || !conductorG) {
                            console.log("\n[X] Error: Primero debe inicializar el sistema (Opción 1).");
                        }
                        else {
                            console.log("\n[!] Paso 2: Asignando conductor a vehículo...");
                            try {
                                asignacion = admin.asignarConductorAVehiculo(conductorG, vehiculoG, new Date());
                                asignacion.AsignarConductor();
                                vehiculoG.setEstado(Estado_Vehiculo_1.Estado_Vehiculo.EN_SERVICIO);
                                console.log("   -> Éxito: El conductor", conductorG.getnombre(), "ahora conduce el vehículo", vehiculoG.getplaca());
                                console.log("   -> Estado del Vehículo:", vehiculoG.getestado());
                            }
                            catch (error) {
                                console.log("   -> Error:", error.message);
                            }
                        }
                        return [4 /*yield*/, presionarEnter()];
                    case 4:
                        _b.sent();
                        return [3 /*break*/, 14];
                    case 5:
                        if (!rutaG || !conductorG || vehiculoG.getestado() !== Estado_Vehiculo_1.Estado_Vehiculo.EN_SERVICIO) {
                            console.log("\n[X] Error: Asegúrese de haber asignado el conductor (Opción 2).");
                        }
                        else {
                            console.log("\n[!] Paso 3: Iniciando Viaje...");
                            viajeActivo = new Viaje_1.Viaje("VIAJE-001", conductorG.getId(), vehiculoG.getId(), rutaG.getId());
                            try {
                                conductorG.aceptarviaje(viajeActivo);
                                console.log("   -> ¡Viaje Iniciado con Éxito!");
                                console.log("   -> Estado del viaje:", viajeActivo.getEstado());
                            }
                            catch (error) {
                                console.log("   -> Error:", error.message);
                            }
                        }
                        return [4 /*yield*/, presionarEnter()];
                    case 6:
                        _b.sent();
                        return [3 /*break*/, 14];
                    case 7:
                        if (!viajeActivo || !viajeActivo.estaEnCurso()) {
                            console.log("\n[X] Error: Debe iniciar un viaje primero (Opción 3).");
                        }
                        else {
                            console.log("\n[!] Paso 4: Simulando Movimiento y Reporte de Eventos...");
                            loc1 = new UbicacionGPS_1.UbicacionGPS(viajeActivo.getId(), -12.044, -77.029, new Date(), 60);
                            loc2 = new UbicacionGPS_1.UbicacionGPS(viajeActivo.getId(), -12.048, -77.033, new Date(), 80);
                            ubicacionesSimuladas.push(loc1, loc2);
                            console.log("   -> Puntos GPS registrados. Velocidades:", loc1.getVelocidad(), "km/h y", loc2.getVelocidad(), "km/h.");
                            // Simular que el conductor reporta algo
                            console.log("   -> El conductor reporta una incidencia de tráfico ligero...");
                            viajeActivo.registrarIncidencia(TipoEvento_1.TipoEvento.DESVIACION_RUTA, TipoAlerta_1.TipoAlerta.PERDIDA_GPS, "Tráfico inesperado, pequeña desviación");
                            console.log("   -> Incidencia guardada en el viaje. Alertas pendientes:", viajeActivo.obtenerAlertasPendientes().length);
                        }
                        return [4 /*yield*/, presionarEnter()];
                    case 8:
                        _b.sent();
                        return [3 /*break*/, 14];
                    case 9:
                        if (!viajeActivo || !viajeActivo.estaEnCurso()) {
                            console.log("\n[X] Error: Debe iniciar y avanzar un viaje primero.");
                        }
                        else {
                            console.log("\n[!] Paso 5: Finalizando viaje y obteniendo métricas...");
                            conductorG.finalizarviaje(viajeActivo);
                            vehiculoG.setEstado(Estado_Vehiculo_1.Estado_Vehiculo.DISPONIBLE);
                            console.log("   -> Estado del viaje:", viajeActivo.getEstado());
                            console.log("   -> Vehículo liberado, estado:", vehiculoG.getestado());
                            // Guardar historial
                            historial = new HistorialRecorridos_1.HistorialRecorridos(viajeActivo.getId(), ubicacionesSimuladas, viajeActivo.getEventos(), viajeActivo.getAlertas());
                            console.log("\n=== REPORTE FINAL DE HISTORIAL ===");
                            exportado = historial.exportar();
                            console.log(JSON.stringify(exportado, null, 2));
                            // Resetear para nueva prueba
                            viajeActivo = null;
                            ubicacionesSimuladas = [];
                        }
                        return [4 /*yield*/, presionarEnter()];
                    case 10:
                        _b.sent();
                        return [3 /*break*/, 14];
                    case 11:
                        console.log("\nSaliendo del sistema... ¡Adiós!");
                        rl.close();
                        process.exit(0);
                        _b.label = 12;
                    case 12:
                        console.log("\n[X] Opción no válida. Intente de nuevo.");
                        return [4 /*yield*/, presionarEnter()];
                    case 13:
                        _b.sent();
                        return [3 /*break*/, 14];
                    case 14:
                        loopMenu();
                        return [2 /*return*/];
                }
            });
        }); });
        return [2 /*return*/];
    });
}); };
// Iniciar aplicación
loopMenu();
