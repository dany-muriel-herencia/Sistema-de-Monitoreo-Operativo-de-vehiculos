// rutas/api.ts
import { Router } from "express";

// ── Repositorios ───────────────────────────────────────────────────────────────
import { ConductorRepositorio } from "../infraestructura/repositorios/ConductorRepositorio";
import { VehiculoRepositorio } from "../infraestructura/repositorios/VehiculoRepositorio";
import { ViajeRepositorio } from "../infraestructura/repositorios/ViajeRepositorio";
import { UbicacionRepositorio } from "../infraestructura/repositorios/UbicacionRepositorio";
import { UsuarioRepositorio } from "../infraestructura/repositorios/UsuarioRepositorio";
import { RutaRepositorio } from "../infraestructura/repositorios/RutaRepositorio";
import { AlertaRutaRepositorio } from "../infraestructura/repositorios/AlertaRutaRepositorio";
import { EventoOperacionRepositorio } from "../infraestructura/repositorios/EventoOperacionRepositorio";
import { AsignacionConductorRepositorio } from "../infraestructura/repositorios/AsignacionConductorRepositorio";

// ── Casos de Uso ───────────────────────────────────────────────────────────────
import { CrearConductor } from "../aplicacion/casosUso/crearConductor";
import { ObtenerConductores } from "../aplicacion/casosUso/obtenerConductores";
import { Gestion_Conductores } from "../aplicacion/casosUso/Gestion_Conductores";
import { GestionVehiculos } from "../aplicacion/casosUso/GestionVehiculos";
import { Gestion_Viajes } from "../aplicacion/casosUso/Gestion_Viajes";
import { CrearUbicacion } from "../aplicacion/casosUso/crearUbicacion";
import { Login } from "../aplicacion/casosUso/Login";

// ── Controladores ──────────────────────────────────────────────────────────────
import { ConductorController } from "../controladores/conductorController";
import { VehiculoController } from "../controladores/vehiculoController";
import { ViajeController } from "../controladores/viajeController";
import { UbicacionController } from "../controladores/ubicacionController";
import { RutaController } from "../controladores/rutaController";
import { AlertaController } from "../controladores/alertaController";
import { EventoController } from "../controladores/eventoController";
import { AsignacionController } from "../controladores/asignacionController";

const router = Router();

// ──────────────────────────────────────────────────────────────────────────────
// Inyección de dependencias
// ──────────────────────────────────────────────────────────────────────────────
const conductorRepo = new ConductorRepositorio();
const vehiculoRepo = new VehiculoRepositorio();
const viajeRepo = new ViajeRepositorio();
const ubicacionRepo = new UbicacionRepositorio();
const usuarioRepo = new UsuarioRepositorio();
const rutaRepo = new RutaRepositorio();
const alertaRepo = new AlertaRutaRepositorio();
const eventoRepo = new EventoOperacionRepositorio();
const asignacionRepo = new AsignacionConductorRepositorio();

const crearConductorUC = new CrearConductor(conductorRepo);
const obtenerConductoresUC = new ObtenerConductores(conductorRepo);
const gestionConductoresUC = new Gestion_Conductores(conductorRepo);
const gestionVehiculosUC = new GestionVehiculos(vehiculoRepo);
const gestionViajesUC = new Gestion_Viajes(viajeRepo);
const crearUbicacionUC = new CrearUbicacion(ubicacionRepo);
const loginUC = new Login(usuarioRepo);

const conductorCtrl = new ConductorController(crearConductorUC, gestionConductoresUC, obtenerConductoresUC);
const vehiculoCtrl = new VehiculoController(gestionVehiculosUC);
const viajeCtrl = new ViajeController(gestionViajesUC, gestionConductoresUC, gestionVehiculosUC);
const ubicacionCtrl = new UbicacionController(crearUbicacionUC, ubicacionRepo);
const rutaCtrl = new RutaController(rutaRepo);
const alertaCtrl = new AlertaController(alertaRepo);
const eventoCtrl = new EventoController(eventoRepo);
const asignacionCtrl = new AsignacionController(asignacionRepo);

// ──────────────────────────────────────────────────────────────────────────────
// RUTAS — AUTENTICACIÓN
// ──────────────────────────────────────────────────────────────────────────────
router.post("/login", async (req, res) => {
    const { email, password } = req.body;
    try {
        const usuario = await loginUC.ejecutar(email, password);
        res.json({ mensaje: "Login exitoso", usuario });
    } catch (error: any) {
        res.status(401).json({ error: error.message });
    }
});

// ──────────────────────────────────────────────────────────────────────────────
// RUTAS — CONDUCTORES
// ──────────────────────────────────────────────────────────────────────────────
router.post("/conductores", (req, res) => conductorCtrl.crear(req, res));
router.get("/conductores", (req, res) => conductorCtrl.listar(req, res));
router.get("/conductores/disponibles", (req, res) => conductorCtrl.listarDisponibles(req, res));
router.get("/conductores/:id", (req, res) => conductorCtrl.obtenerPorId(req, res));
router.delete("/conductores/:id", (req, res) => conductorCtrl.eliminar(req, res));

// ──────────────────────────────────────────────────────────────────────────────
// RUTAS — VEHÍCULOS
// ──────────────────────────────────────────────────────────────────────────────
router.post("/vehiculos", (req, res) => vehiculoCtrl.crear(req, res));
router.get("/vehiculos", (req, res) => vehiculoCtrl.listar(req, res));
router.get("/vehiculos/:placa", (req, res) => vehiculoCtrl.obtenerPorPlaca(req, res));
router.delete("/vehiculos/:placa", (req, res) => vehiculoCtrl.eliminar(req, res));

// ──────────────────────────────────────────────────────────────────────────────
// RUTAS — VIAJES
// ──────────────────────────────────────────────────────────────────────────────
router.post("/viajes", (req, res) => viajeCtrl.planificar(req, res));
router.get("/viajes", (req, res) => viajeCtrl.listarTodos(req, res));        // ← NUEVO
router.get("/viajes/en-curso", (req, res) => viajeCtrl.listarEnCurso(req, res));
router.get("/viajes/historial/:idConductor", (req, res) => viajeCtrl.historialConductor(req, res));
router.patch("/viajes/:id/iniciar", (req, res) => viajeCtrl.iniciar(req, res));
router.patch("/viajes/:id/finalizar", (req, res) => viajeCtrl.finalizar(req, res));

// ──────────────────────────────────────────────────────────────────────────────
// RUTAS — RUTAS DE TRANSPORTE
// ──────────────────────────────────────────────────────────────────────────────
router.get("/rutas", (req, res) => rutaCtrl.listar(req, res));
router.get("/rutas/:id", (req, res) => rutaCtrl.obtenerPorId(req, res));
router.delete("/rutas/:id", (req, res) => rutaCtrl.eliminar(req, res));

// ──────────────────────────────────────────────────────────────────────────────
// RUTAS — UBICACIONES GPS
// ──────────────────────────────────────────────────────────────────────────────
router.post("/ubicaciones", (req, res) => ubicacionCtrl.registrar(req, res));
router.get("/ubicaciones/viaje/:idViaje", (req, res) => ubicacionCtrl.obtenerPorViaje(req, res));
router.get("/ubicaciones/viaje/:idViaje/ultima", (req, res) => ubicacionCtrl.obtenerUltima(req, res));

// ──────────────────────────────────────────────────────────────────────────────
// RUTAS — ALERTAS
// ──────────────────────────────────────────────────────────────────────────────
router.get("/alertas/viaje/:idViaje", (req, res) => alertaCtrl.obtenerPorViaje(req, res));
router.get("/alertas/viaje/:idViaje/pendientes", (req, res) => alertaCtrl.obtenerPendientes(req, res));
router.patch("/alertas/:id/resolver", (req, res) => alertaCtrl.resolver(req, res));

// ──────────────────────────────────────────────────────────────────────────────
// RUTAS — EVENTOS DE OPERACIÓN
// ──────────────────────────────────────────────────────────────────────────────
router.get("/eventos/viaje/:idViaje", (req, res) => eventoCtrl.obtenerPorViaje(req, res));

// ──────────────────────────────────────────────────────────────────────────────
// RUTAS — ASIGNACIONES CONDUCTOR-VEHÍCULO
// ──────────────────────────────────────────────────────────────────────────────
router.get("/asignaciones/conductor/:id", (req, res) => asignacionCtrl.historialConductor(req, res));
router.get("/asignaciones/conductor/:id/activa", (req, res) => asignacionCtrl.activaConductor(req, res));
router.get("/asignaciones/vehiculo/:placa/activa", (req, res) => asignacionCtrl.activaVehiculo(req, res));

export default router;
