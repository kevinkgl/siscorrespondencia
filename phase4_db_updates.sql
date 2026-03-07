-- Añadir columna para la firma digital (imagen en base64 o ruta)
ALTER TABLE correspondencia ADD COLUMN IF NOT EXISTS firma_digital TEXT;

-- Añadir una tabla para guardar documentos locales pendientes de sincronizar (opcional si usamos SQLite local, pero útil para log)
CREATE TABLE IF NOT EXISTS sync_log (
    id SERIAL PRIMARY KEY,
    correspondencia_local_id TEXT, -- ID temporal generado localmente
    accion VARCHAR(50), -- 'CREATE', 'UPDATE'
    status VARCHAR(20) DEFAULT 'PENDING', -- 'PENDING', 'SYNCED', 'ERROR'
    payload JSONB, -- Datos completos del documento
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    synced_at TIMESTAMP
);
