import { createPool } from 'mysql2/promise';

async function test() {
    const pool = createPool({
        host: '127.0.0.1',
        user: 'root',
        password: '',
        database: 'app_unidades_mobiles',
    });
    const [a] = await pool.query('SELECT * FROM tipo_alerta');
    console.log('ALERTAS:', a);
    const [e] = await pool.query('SELECT * FROM tipo_evento');
    console.log('EVENTOS:', e);
    process.exit(0);
}
test();
