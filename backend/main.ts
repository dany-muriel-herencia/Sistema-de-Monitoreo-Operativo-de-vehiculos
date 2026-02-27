import express from "express";
import cors from "cors";
import apiRoutes from "./rutas/api";
import "dotenv/config";

const app = express();
const PORT = process.env.PORT || 3000;

// Middlewares
app.use(cors()); // Permite peticiones del frontend (React, etc)
app.use(express.json()); // Permite leer JSON en las peticiones POST

// Rutas
app.use("/api", apiRoutes);

// Ruta de prueba
app.get("/", (req, res) => {
    res.send("🚀 Servidor de Monitoreo de Flotas corriendo correctamente.");
});

// Inicio del servidor
app.listen(PORT, () => {
    console.log(`
    ==========================================
    ✅ SERVIDOR INICIADO
    📍 Puerto: ${PORT}
    🌐 URL: http://localhost:${PORT}/api
    ==========================================
    `);
});
