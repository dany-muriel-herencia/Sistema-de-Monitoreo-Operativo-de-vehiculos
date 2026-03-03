import { createPool } from 'mysql2/promise';
import * as fs from 'fs';

async function test() {
    const pool = createPool({
        host: '127.0.0.1',
        user: 'root',
        password: '',
        database: 'app_unidades_mobiles',
    });
    const [a] = await pool.query('SELECT * FROM tipo_alerta');
    const [e] = await pool.query('SELECT * FROM tipo_evento');
    fs.writeFileSync('out2.json', JSON.stringify({ ALERTAS: a, EVENTOS: e }, null, 2), 'utf-8');
    process.exit(0);
}
test();
