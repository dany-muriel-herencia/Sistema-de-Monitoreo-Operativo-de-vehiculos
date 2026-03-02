const { createPool } = require('mysql2/promise');
require('dotenv').config();

async function checkDB() {
    const pool = createPool({
        host: process.env.DB_HOST || '127.0.0.1',
        user: process.env.DB_USER || 'root',
        password: process.env.DB_PASS || '',
        database: process.env.DB_NAME || 'app_unidades_mobiles',
    });

    try {
        const [rows] = await pool.query('SELECT id, nombre, email, rol, contraseña FROM usuarios');
        const fs = require('fs');
        fs.writeFileSync('users_clean.json', JSON.stringify(rows, null, 2));
        console.log('USUARIOS GUARDADOS EN users_clean.json');
    } catch (e) {
        console.error(`ERROR AL CONECTAR: ${e.message}`);
    } finally {
        await pool.end();
    }
}

checkDB();
