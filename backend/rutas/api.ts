import { Router } from "express";
import { ConductorRepositorio } from "../infraestructura/repositorios/ConductorRepositorio";
import { ObtenerConductores } from "../aplicacion/casosUso/obtenerConductores";
import { CrearConductor } from "../aplicacion/casosUso/crearConductor";
import { Login } from "../aplicacion/casosUso/Login";
import { UsuarioRepositorio } from "../infraestructura/repositorios/UsuarioRepositorio";

const router = Router();

// Inyección de dependencias (Manual)
const conductorRepo = new ConductorRepositorio();
const usuarioRepo = new UsuarioRepositorio();

// Casos de Uso
const obtenerConductoresUC = new ObtenerConductores(conductorRepo);
const crearConductorUC = new CrearConductor(conductorRepo);
const loginUC = new Login(usuarioRepo);

// --- RUTAS DE CONDUCTORES ---

router.get("/conductores", async (req, res) => {
    try {
        const conductores = await obtenerConductoresUC.ejecutar();
        res.json(conductores);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

router.post("/conductores", async (req, res) => {
    try {
        const nuevo = await crearConductorUC.ejecutar(req.body);
        res.status(201).json(nuevo);
    } catch (error: any) {
        res.status(400).json({ error: error.message });
    }
});

// --- RUTAS DE AUTENTICACIÓN ---

router.post("/login", async (req, res) => {
    const { email, password } = req.body;
    try {
        const usuario = await loginUC.ejecutar(email, password);
        res.json({ message: "Login exitoso", usuario });
    } catch (error: any) {
        res.status(401).json({ error: error.message });
    }
});

export default router;
