import express from 'express';
import http from 'http';
import { Server as IOServer } from 'socket.io';
import cors from 'cors';
import dotenv from 'dotenv';
import { pool } from './db';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);
const io = new IOServer(server, { cors: { origin: '*' } });

io.on('connection', (socket) => {
  console.log('WS connected:', socket.id);
  socket.on('disconnect', () => console.log('WS disconnected:', socket.id));
});

app.get('/health', (_req, res) => res.json({ status: 'ok' }));

app.get('/api/vehiculos', async (_req, res) => {
  try {
    const [rows] = await pool.query('SELECT id, placa, modelo, capacidad, kilometraje, estado_id FROM vehiculos LIMIT 100');
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'db error' });
  }
});

app.post('/api/ubicaciones', async (req, res) => {
  const { viaje_id, latitud, longitud, timestamp } = req.body;
  if (!viaje_id || latitud == null || longitud == null) {
    return res.status(400).json({ error: 'viaje_id, latitud, longitud required' });
  }

  try {
    await pool.execute(
      'INSERT INTO ubicaciones_gps (viaje_id, timestamp, latitud, longitud) VALUES (?, ?, ?, ?)',
      [viaje_id, timestamp ?? new Date(), latitud, longitud]
    );

    const location = { viaje_id, latitud, longitud, timestamp: timestamp ?? new Date() };
    io.emit('ubicacion:update', location);
    res.status(201).json({ ok: true, location });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'db error' });
  }
});

const PORT = process.env.PORT ? Number(process.env.PORT) : 3000;
server.listen(PORT, () => console.log(`Server listening on http://localhost:${PORT}`));
