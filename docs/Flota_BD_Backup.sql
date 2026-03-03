-- -----------------------------------------------------
-- Base de datos: flotas_db
-- -----------------------------------------------------
CREATE DATABASE IF NOT EXISTS app_unidades_mobiles;
USE app_unidades_mobiles;

-- -----------------------------------------------------
-- Tabla: usuarios (herencia: administradores y conductores)
-- -----------------------------------------------------
CREATE TABLE usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    contraseña VARCHAR(255) NOT NULL,
    rol ENUM('admin', 'conductor') NOT NULL,  -- discrimina el tipo de usuario
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------
-- Tabla: conductores (datos específicos de conductores)
-- -----------------------------------------------------
CREATE TABLE conductores (
    usuario_id INT PRIMARY KEY,
    licencia VARCHAR(20) NOT NULL,
    telefono VARCHAR(15),
    sueldo DECIMAL(10,2),
    edad INT, -- Agregado para sincronizar con la entidad Conductor.ts
    disponible BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

-- Nota: Los administradores no tienen atributos extra, por lo que no se crea tabla separada.
-- El rol 'admin' en la tabla usuarios es suficiente.

-- -----------------------------------------------------
-- Tabla: estado_vehiculo (catálogo)
-- -----------------------------------------------------
CREATE TABLE estado_vehiculo (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL
);

INSERT INTO estado_vehiculo (nombre) VALUES ('DISPONIBLE'), ('EN_RUTA'), ('EN_MANTENIMIENTO');

-- -----------------------------------------------------
-- Tabla: vehiculos
-- -----------------------------------------------------
CREATE TABLE vehiculos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    marca VARCHAR(50) NOT NULL, -- Agregado para sincronizar con Vehiculo.ts
    placa VARCHAR(10) UNIQUE NOT NULL,
    modelo VARCHAR(50) NOT NULL,
    año INT, -- Agregado para sincronizar con Vehiculo.ts
    capacidad INT NOT NULL,
    kilometraje DECIMAL(10,2) DEFAULT 0,
    estado_id INT NOT NULL,
    FOREIGN KEY (estado_id) REFERENCES estado_vehiculo(id)
);

-- -----------------------------------------------------
-- Tabla: rutas
-- -----------------------------------------------------
CREATE TABLE rutas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    distancia_total DECIMAL(10,2),  -- en kilómetros
    duracion_estimada INT            -- en minutos
);

-- -----------------------------------------------------
-- Tabla: puntos_ruta (detalle de los puntos geográficos de una ruta)
-- -----------------------------------------------------
CREATE TABLE puntos_ruta (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ruta_id INT NOT NULL,
    orden INT NOT NULL,               -- secuencia del punto en la ruta
    latitud DECIMAL(10,8) NOT NULL,
    longitud DECIMAL(11,8) NOT NULL,
    FOREIGN KEY (ruta_id) REFERENCES rutas(id) ON DELETE CASCADE,
    UNIQUE KEY (ruta_id, orden)
);

-- -----------------------------------------------------
-- Tabla: estado_viaje (catálogo)
-- -----------------------------------------------------
CREATE TABLE estado_viaje (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL
);

INSERT INTO estado_viaje (nombre) VALUES ('PLANIFICADO'), ('EN_CURSO'), ('FINALIZADO');

-- -----------------------------------------------------
-- Tabla: viajes
-- -----------------------------------------------------
CREATE TABLE viajes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vehiculo_id INT NOT NULL,
    conductor_id INT NOT NULL,         -- referencia a conductores(usuario_id)
    ruta_id INT NOT NULL,
    fecha_hora_inicio DATETIME,
    fecha_hora_fin DATETIME,
    estado_id INT NOT NULL,
    FOREIGN KEY (vehiculo_id) REFERENCES vehiculos(id),
    FOREIGN KEY (conductor_id) REFERENCES conductores(usuario_id),
    FOREIGN KEY (ruta_id) REFERENCES rutas(id),
    FOREIGN KEY (estado_id) REFERENCES estado_viaje(id),
    INDEX idx_viaje_fechas (fecha_hora_inicio, fecha_hora_fin)
);

-- -----------------------------------------------------
-- Tabla: tipo_alerta (catálogo)
-- -----------------------------------------------------
CREATE TABLE tipo_alerta (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL
);

INSERT INTO tipo_alerta (nombre) VALUES ('DESVIACION_RUTA'), ('RETRASO'), ('PARADA_PROLOGADA');

-- -----------------------------------------------------
-- Tabla: alertas_ruta
-- -----------------------------------------------------
CREATE TABLE alertas_ruta (
    id INT AUTO_INCREMENT PRIMARY KEY,
    viaje_id INT NOT NULL,
    tipo_alerta_id INT NOT NULL,
    timestamp DATETIME NOT NULL,
    mensaje TEXT,
    resuelta BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (viaje_id) REFERENCES viajes(id) ON DELETE CASCADE,
    FOREIGN KEY (tipo_alerta_id) REFERENCES tipo_alerta(id),
    INDEX idx_alerta_tiempo (timestamp)
);

-- -----------------------------------------------------
-- Tabla: tipo_evento (catálogo)
-- -----------------------------------------------------
CREATE TABLE tipo_evento (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL
);

INSERT INTO tipo_evento (nombre) VALUES ('INICIO_VIAJE'), ('FIN_VIAJE'), ('INICIO_PAUSA'), ('FIN_PAUSA'), ('INCIDENCIA');

-- -----------------------------------------------------
-- Tabla: eventos_operacion
-- -----------------------------------------------------
CREATE TABLE eventos_operacion (
    id INT AUTO_INCREMENT PRIMARY KEY,
    viaje_id INT NOT NULL,
    timestamp DATETIME NOT NULL,
    tipo_evento_id INT NOT NULL,
    descripcion TEXT,
    FOREIGN KEY (viaje_id) REFERENCES viajes(id) ON DELETE CASCADE,
    FOREIGN KEY (tipo_evento_id) REFERENCES tipo_evento(id),
    INDEX idx_evento_tiempo (timestamp)
);

-- -----------------------------------------------------
-- Tabla: ubicaciones_gps
-- -----------------------------------------------------
CREATE TABLE ubicaciones_gps (
    id INT AUTO_INCREMENT PRIMARY KEY,
    viaje_id INT NOT NULL,
    timestamp DATETIME NOT NULL,
    latitud DECIMAL(10,8) NOT NULL,
    longitud DECIMAL(11,8) NOT NULL,
    velocidad DECIMAL(5,2),            -- km/h opcional
    FOREIGN KEY (viaje_id) REFERENCES viajes(id) ON DELETE CASCADE,
    INDEX idx_ubicacion_viaje (viaje_id, timestamp)
);

-- -----------------------------------------------------
-- Tabla: asignaciones_conductor (periodos de asignación vehículo-conductor)
-- -----------------------------------------------------
CREATE TABLE asignaciones_conductor (
    id INT AUTO_INCREMENT PRIMARY KEY,
    conductor_id INT NOT NULL,
    vehiculo_id INT NOT NULL,
    fecha_inicio DATETIME NOT NULL,
    fecha_fin DATETIME,                -- NULL si aún está activa
    FOREIGN KEY (conductor_id) REFERENCES conductores(usuario_id),
    FOREIGN KEY (vehiculo_id) REFERENCES vehiculos(id),
    INDEX idx_asignacion_fechas (fecha_inicio, fecha_fin)
);

-- -----------------------------------------------------
-- Nota: La entidad HistorialRecorrido no se materializa como tabla,
-- pues se puede consultar mediante viajes, ubicaciones y eventos.
-- La entidad Reporte tampoco se persiste, se genera bajo demanda.
-- -----------------------------------------------------