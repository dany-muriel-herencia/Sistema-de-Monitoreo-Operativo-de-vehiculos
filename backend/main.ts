// 1. Cargar variables de entorno PRIMERO que nada
require('dotenv').config();

const express = require('express');
const cors = require('cors');
// Importamos las rutas. Nota: como usas 'export default', necesitamos el '.default'
const apiRoutes = require('./rutas/api').default;

const app = express();
// 2. Usar el puerto 3000 (el 3306 es de MySQL y dará error)
const PORT = process.env.PORT || 3000;

// Middlewares
app.use(cors());
app.use(express.json());

// Rutas
app.use("/api", apiRoutes);

app.get("/", (req, res) => {
    res.send("🚀 Servidor de Monitoreo de Flotas corriendo correctamente.");
});

// Inicio del servidor
app.listen(PORT, () => {
    console.log(`
    ==========================================
    ✅ SERVIDOR INICIADO CORRECTAMENTE
    📍 Puerto: ${PORT}
    🌐 URL: http://localhost:${PORT}/api
    ==========================================
    `);
});
