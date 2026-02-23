import 'dotenv/config';
import { createPool, Pool } from 'mysql2/promise';

export const pool: Pool = createPool({
  host: process.env.DB_HOST || '127.0.0.1',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASS || '',
  database: process.env.DB_NAME || 'app_unidades_mobiles',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});
