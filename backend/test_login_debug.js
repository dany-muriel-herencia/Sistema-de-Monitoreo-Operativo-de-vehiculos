const { createPool } = require('mysql2/promise');
require('dotenv').config();

// Mimo del repositorio para probar el flujo de Login
async function testLoginFlow(email, password) {
    const pool = createPool({
        host: process.env.DB_HOST || '127.0.0.1',
        user: process.env.DB_USER || 'root',
        password: process.env.DB_PASS || '',
        database: process.env.DB_NAME || 'app_unidades_mobiles',
    });

    try {
        console.log(`Buscando usuario: ${email}`);
        const [rows] = await pool.query(
            'SELECT id, nombre, email, contraseña, rol FROM usuarios WHERE LOWER(email) = LOWER(?)',
            [email.trim()]
        );

        if (rows.length === 0) {
            console.log('RESULTADO: Usuario no encontrado');
            return;
        }

        const user = rows[0];
        console.log(`PASS EN BD: "${user.contraseña}" (Largo: ${user.contraseña.length})`);
        console.log(`PASS INGRESADO: "${password}" (Largo: ${password.length})`);

        const isMatch = (user.email.toLowerCase().trim() === email.toLowerCase().trim() &&
            user.contraseña.trim() === password.trim());

        console.log(`COMPARACIÓN: EmailMatch=${user.email.toLowerCase().trim() === email.toLowerCase().trim()}, PasswordMatch=${user.contraseña.trim() === password.trim()} (usando trim())`);
        console.log(`RESULTADO: ${isMatch ? 'ÉXITO' : 'FALLO'}`);

    } catch (e) {
        console.error('ERROR:', e.message);
    } finally {
        await pool.end();
    }
}

// Probamos con los datos que vimos en el dump
const testEmail = process.argv[2] || 'admin@test.com';
const testPass = process.argv[3] || 'admin123456';

testLoginFlow(testEmail, testPass);
