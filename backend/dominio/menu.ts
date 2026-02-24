import * as readline from "readline";
import { administrador } from "./Entidades/Administracion";
import { Estado_Vehiculo } from "./emuns/Estado_Vehiculo";
import { Duracion } from "./Entidades/Duracion";
import { PuntoGeo } from "./Entidades/PuntoGeo";
import { Viaje } from "./Entidades/Viaje";
import { HistorialRecorridos } from "./Entidades/HistorialRecorridos";
import { UbicacionGPS } from "./Entidades/UbicacionGPS";
import { TipoEvento } from "./emuns/TipoEvento";
import { TipoAlerta } from "./emuns/TipoAlerta";

// Configuración de Readline para interface en consola
const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

const menu = () => {
    console.log(`
=============================================
==== SISTEMA DE MONITOREO DE VEHÍCULOS ====
=============================================
1. Inicializar Sistema (Crear Admin, Vehículo, Conductor, Ruta)
2. Asignar Conductor a Vehículo
3. Iniciar Viaje
4. Simular Movimiento (Avanzar GPS y Registrar Incidencia)
5. Finalizar Viaje y Ver Métricas del Historial
0. Salir
=============================================
Elija una opción: `);
};

// Variables globales para mantener el estado
let admin: administrador;
let vehiculoG: any;
let conductorG: any;
let rutaG: any;
let viajeActivo: Viaje | null = null;
let historial: HistorialRecorridos | null = null;
let ubicacionesSimuladas: UbicacionGPS[] = [];

const presionarEnter = () => {
    return new Promise<void>(resolve => {
        rl.question('\nPresione "Enter" para continuar...', () => {
            resolve();
        });
    });
};

const loopMenu = async () => {
    menu();
    rl.question('> ', async (opcion) => {
        switch (opcion.trim()) {
            case '1':
                console.log("\n[!] Paso 1: Inicializando sistema...");
                admin = new administrador("admin-1", "Dany Muriel", "dany@flota.com", "1234");
                console.log("   -> Administrador creado:", admin.getNombre());

                vehiculoG = admin.registrarvehiculo("V-001", "Toyota", "ABC-123", "Corolla", 5, 12000, Estado_Vehiculo.DISPONIBLE, 2022);
                console.log("   -> Vehículo registrado:", vehiculoG.getplaca(), "-", vehiculoG.getMarca());

                conductorG = admin.registrarconductor("C-001", "Juan Perez", "juan@flota.com", "pass", "LIC-999", 987654321, 1500, 35);
                console.log("   -> Conductor registrado:", conductorG.getnombre(), "- Licencia:", conductorG.getLicencia());

                const puntos = [
                    new PuntoGeo("P-1", -12.04318, -77.02824, 1, "Punto Inicial Lima"),
                    new PuntoGeo("P-2", -12.04500, -77.03000, 2, "Intersección A"),
                    new PuntoGeo("P-3", -12.05000, -77.03500, 3, "Punto Final Lima")
                ];
                rutaG = admin.definirRuta("R-001", "Ruta Centro", 15.5, new Duracion(1, 45), puntos);
                console.log("   -> Ruta creada:", rutaG.getNombre(), "con", rutaG.getPuntos().length, "puntos de control.");
                await presionarEnter();
                break;

            case '2':
                if (!admin || !vehiculoG || !conductorG) {
                    console.log("\n[X] Error: Primero debe inicializar el sistema (Opción 1).");
                } else {
                    console.log("\n[!] Paso 2: Asignando conductor a vehículo...");
                    try {
                        const asignacion = admin.asignarConductorAVehiculo(conductorG, vehiculoG, new Date());
                        // No necesitamos llamar a asignacion.AsignarConductor() porque el 
                        // constructor de AsignacionConductor ya lo crea con 'activa = true'
                        vehiculoG.setEstado(Estado_Vehiculo.EN_SERVICIO);
                        console.log("   -> Éxito: El conductor", conductorG.getnombre(), "ahora conduce el vehículo", vehiculoG.getplaca());
                        console.log("   -> Estado del Vehículo:", vehiculoG.getestado());
                    } catch (error: any) {
                        console.log("   -> Error:", error.message);
                    }
                }
                await presionarEnter();
                break;

            case '3':
                if (!rutaG || !conductorG || vehiculoG.getestado() !== Estado_Vehiculo.EN_SERVICIO) {
                    console.log("\n[X] Error: Asegúrese de haber asignado el conductor (Opción 2).");
                } else {
                    console.log("\n[!] Paso 3: Iniciando Viaje...");
                    viajeActivo = new Viaje("VIAJE-001", conductorG.getId(), vehiculoG.getId(), rutaG.getId());
                    try {
                        conductorG.aceptarviaje(viajeActivo);
                        console.log("   -> ¡Viaje Iniciado con Éxito!");
                        console.log("   -> Estado del viaje:", viajeActivo.getEstado());
                    } catch (error: any) {
                        console.log("   -> Error:", error.message);
                    }
                }
                await presionarEnter();
                break;

            case '4':
                if (!viajeActivo || !viajeActivo.estaEnCurso()) {
                    console.log("\n[X] Error: Debe iniciar un viaje primero (Opción 3).");
                } else {
                    console.log("\n[!] Paso 4: Simulando Movimiento y Reporte de Eventos...");
                    // Generar puntos GPS inventados
                    const loc1 = new UbicacionGPS(viajeActivo.getId(), -12.044, -77.029, new Date(), 60);
                    const loc2 = new UbicacionGPS(viajeActivo.getId(), -12.048, -77.033, new Date(), 80); // Excesiva velocidad simulada
                    ubicacionesSimuladas.push(loc1, loc2);
                    console.log("   -> Puntos GPS registrados. Velocidades:", loc1.getVelocidad(), "km/h y", loc2.getVelocidad(), "km/h.");

                    // Simular que el conductor reporta algo
                    console.log("   -> El conductor reporta una incidencia de tráfico ligero...");
                    viajeActivo.registrarIncidencia(TipoEvento.DESVIACION_RUTA, TipoAlerta.PERDIDA_GPS, "Tráfico inesperado, pequeña desviación");
                    console.log("   -> Incidencia guardada en el viaje. Alertas pendientes:", viajeActivo.obtenerAlertasPendientes().length);
                }
                await presionarEnter();
                break;

            case '5':
                if (!viajeActivo || !viajeActivo.estaEnCurso()) {
                    console.log("\n[X] Error: Debe iniciar y avanzar un viaje primero.");
                } else {
                    console.log("\n[!] Paso 5: Finalizando viaje y obteniendo métricas...");
                    conductorG.finalizarviaje(viajeActivo);
                    vehiculoG.setEstado(Estado_Vehiculo.DISPONIBLE);
                    console.log("   -> Estado del viaje:", viajeActivo.getEstado());
                    console.log("   -> Vehículo liberado, estado:", vehiculoG.getestado());

                    // Guardar historial
                    historial = new HistorialRecorridos(
                        viajeActivo.getId(),
                        ubicacionesSimuladas,
                        viajeActivo.getEventos(),
                        viajeActivo.getAlertas()
                    );

                    console.log("\n=== REPORTE FINAL DE HISTORIAL ===");
                    const exportado = historial.exportar();
                    console.log(JSON.stringify(exportado, null, 2));

                    // Resetear para nueva prueba
                    viajeActivo = null;
                    ubicacionesSimuladas = [];
                }
                await presionarEnter();
                break;

            case '0':
                console.log("\nSaliendo del sistema... ¡Adiós!");
                rl.close();
                process.exit(0);

            default:
                console.log("\n[X] Opción no válida. Intente de nuevo.");
                await presionarEnter();
                break;
        }

        loopMenu();
    });
};

// Iniciar aplicación
loopMenu();
