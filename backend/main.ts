import 'dotenv/config';
import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import apiRoutes from './rutas/api';

const app = express();
// 2. Usar el puerto 3000 (el 3306 es de MySQL y dará error)
const PORT = process.env.PORT || 3000;

// Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use((req: Request, res: Response, next: NextFunction) => {
    console.log(`${req.method} ${req.url} - Body:`, req.body);
    next();
});

// Rutas
app.use("/api", apiRoutes);

app.get("/", (req, res) => {
    res.send("🚀 Servidor de Monitoreo de Flotas corriendo correctamente.");
});

// Inicio del servidor
app.listen(Number(PORT), '0.0.0.0', () => {
    console.log(`
    ==========================================
    ✅ SERVIDOR INICIADO CORRECTAMENTE
    📍 Puerto: ${PORT}
    🌐 URL local: http://localhost:${PORT}/api
    🌐 URL LAN: http://192.168.18.28:${PORT}/api
    ==========================================
    `);
});
