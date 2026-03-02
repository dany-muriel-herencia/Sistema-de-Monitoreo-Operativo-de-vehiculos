const { createPool } = require('mysql2/promise');
require('dotenv').config();

async function debugCharByChar(email, password) {
    const pool = createPool({
        host: process.env.DB_HOST || '127.0.0.1',
        user: process.env.DB_USER || 'root',
        password: process.env.DB_PASS || '',
        database: process.env.DB_NAME || 'app_unidades_mobiles',
    });

    try {
        const [rows] = await pool.query(
            'SELECT email, contraseña FROM usuarios WHERE LOWER(email) = LOWER(?)',
            [email.trim()]
        );

        if (rows.length === 0) {
            console.log('No encontrado');
            return;
        }

        const dbPass = rows[0].contraseña;
        console.log(`PW DB: "${dbPass}" (len: ${dbPass.length})`);
        for (let i = 0; i < dbPass.length; i++) {
            console.log(`Char ${i}: ${dbPass[i]} (code: ${dbPass.charCodeAt(i)})`);
        }

        console.log(`PW INPUT: "${password}" (len: ${password.length})`);
        for (let i = 0; i < password.length; i++) {
            console.log(`Char ${i}: ${password[i]} (code: ${password.charCodeAt(i)})`);
        }

    } catch (e) {
        console.error(e.message);
    } finally {
        await pool.end();
    }
}

debugCharByChar(process.argv[2] || 'admin@test.com', process.argv[3] || 'admin123456');
