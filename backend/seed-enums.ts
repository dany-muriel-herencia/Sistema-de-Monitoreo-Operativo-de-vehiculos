import { createPool } from 'mysql2/promise';

const pool = createPool({
    host: '127.0.0.1',
    user: 'root',
    password: '',
    database: 'app_unidades_mobiles',
});

async function sincronizarEnums() {
    const alertas = [
        'EMERGENCIA',
        'EXCESO_VELOCIDAD',
        'FALLA_MECANICA',
        'COMBUSTIBLE_BAJO',
        'PERDIDA_GPS'
    ];

    const eventos = [
        'Desviacion de Ruta',
        'Detención Prolongada',
        'Exceso de Velocidad',
        'Parada No Programada',
        'Incidente Mecánico',
        'Condiciones Climáticas Adversas',
        'Comportamiento del Conductor',
        'Emergencia Médica',
        'INICIO_RUTA',
        'FIN_RUTA',
        'EMERGENCIA',
        'FALLA_MECANICA',
        'Otro'
    ];

    try {
        console.log('Sincronizando tipos de alerta...');
        for (const a of alertas) {
            await pool.query('INSERT IGNORE INTO tipo_alerta (nombre) VALUES (?)', [a]);
        }

        console.log('Sincronizando tipos de evento...');
        for (const e of eventos) {
            await pool.query('INSERT IGNORE INTO tipo_evento (nombre) VALUES (?)', [e]);
        }

        console.log('¡Sincronización en la BD completada con éxito!');
    } catch (err) {
        console.error('Error insertando enums:', err);
    } finally {
        process.exit(0);
    }
}

sincronizarEnums();
