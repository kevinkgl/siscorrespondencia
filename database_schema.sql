-- Borrar tablas si existen para evitar conflictos
DROP TABLE IF EXISTS seguimiento CASCADE;
DROP TABLE IF EXISTS adjuntos CASCADE;
DROP TABLE IF EXISTS correspondencia CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;
DROP TABLE IF EXISTS tipos_documento CASCADE;
DROP TABLE IF EXISTS roles CASCADE;
DROP TABLE IF EXISTS sucursales CASCADE;

-- 1. Sucursales y Agencias
CREATE TABLE sucursales (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    codigo_sucursal VARCHAR(10) UNIQUE NOT NULL, -- Ej: 'LPZ', 'SCZ', 'CBBA'
    direccion TEXT,
    es_oficina_central BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Roles de Usuario
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL -- 'ADMIN', 'VENTANILLA', 'JEFE_AGENCIA', 'USUARIO'
);

-- 3. Usuarios
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    nombre_completo VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    role_id INTEGER REFERENCES roles(id),
    sucursal_id INTEGER REFERENCES sucursales(id),
    activo BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Tipos de Documento (CITEs)
CREATE TABLE tipos_documento (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL, -- 'CARTA', 'MEMORANDUM', 'INFORME', etc.
    prefijo VARCHAR(10) NOT NULL, -- 'C', 'M', 'I'
    descripcion TEXT
);

-- 5. Correspondencia (El Corazón del Sistema)
CREATE TABLE correspondencia (
    id SERIAL PRIMARY KEY,
    cite_numero VARCHAR(50) UNIQUE NOT NULL, -- Generado: TIPO-SUC-2026-0001
    tipo_id INTEGER REFERENCES tipos_documento(id),
    remitente_id INTEGER REFERENCES usuarios(id), -- Si es interno
    remitente_externo VARCHAR(200), -- Si viene de afuera
    destinatario_id INTEGER REFERENCES usuarios(id), -- Si es interno
    destinatario_externo VARCHAR(200), -- Si va hacia afuera
    sucursal_origen_id INTEGER REFERENCES sucursales(id),
    sucursal_destino_id INTEGER REFERENCES sucursales(id),
    asunto VARCHAR(255) NOT NULL,
    contenido TEXT,
    clasificacion VARCHAR(20) CHECK (clasificacion IN ('PUBLICA', 'PRIVADA', 'CONFIDENCIAL')),
    estado VARCHAR(20) DEFAULT 'REGISTRADO', -- 'REGISTRADO', 'EN_TRANSITO', 'RECIBIDO', 'ARCHIVADO'
    prioridad VARCHAR(20) DEFAULT 'NORMAL', -- 'BAJA', 'NORMAL', 'ALTA', 'URGENTE'
    fecha_emision TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_limite TIMESTAMP, -- Para las alertas (24h, 3 días, etc.)
    qr_data TEXT, -- Datos para el código QR
    file_path TEXT, -- Ruta al archivo digitalizado
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Seguimiento (Log de movimientos)
CREATE TABLE seguimiento (
    id SERIAL PRIMARY KEY,
    correspondencia_id INTEGER REFERENCES correspondencia(id) ON DELETE CASCADE,
    usuario_origen_id INTEGER REFERENCES usuarios(id),
    usuario_destino_id INTEGER REFERENCES usuarios(id),
    accion VARCHAR(100), -- 'CREACION', 'DERIVACION', 'RECEPCION', 'ARCHIVADO'
    observaciones TEXT,
    fecha_movimiento TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. Adjuntos Adicionales
CREATE TABLE adjuntos (
    id SERIAL PRIMARY KEY,
    correspondencia_id INTEGER REFERENCES correspondencia(id) ON DELETE CASCADE,
    nombre_archivo VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    tipo_mime VARCHAR(100),
    subido_por INTEGER REFERENCES usuarios(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Datos Iniciales de Prueba
INSERT INTO roles (nombre) VALUES ('ADMIN'), ('VENTANILLA'), ('JEFE_AGENCIA'), ('USUARIO');

INSERT INTO sucursales (nombre, codigo_sucursal, es_oficina_central) 
VALUES ('Oficina Central La Paz', 'LPZ-OC', TRUE), ('Agencia Santa Cruz', 'SCZ-A1', FALSE);

INSERT INTO tipos_documento (nombre, prefijo) 
VALUES ('CARTA EXTERNA', 'EXT'), ('MEMORANDUM', 'MEM'), ('INFORME', 'INF'), ('COMUNICACION INTERNA', 'CI');

-- Usuario Admin inicial (Password: admin123)
-- Nota: En producción usaremos hashes, por ahora es ilustrativo
INSERT INTO usuarios (username, password_hash, nombre_completo, role_id, sucursal_id)
VALUES ('admin', 'admin123', 'Administrador del Sistema', 1, 1);
