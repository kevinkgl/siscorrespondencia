-- 1. Añadir Soft Delete a las tablas principales
ALTER TABLE correspondencia ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP;
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP;
ALTER TABLE sucursales ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP;

-- 2. Función para generar CITE único (Thread-safe en DB)
CREATE OR REPLACE FUNCTION generar_proximo_cite(
    p_tipo_id INTEGER,
    p_sucursal_id INTEGER
) RETURNS TEXT AS $$
DECLARE
    v_prefijo_doc VARCHAR(10);
    v_codigo_suc VARCHAR(10);
    v_anio TEXT;
    v_secuencia INTEGER;
    v_cite_final TEXT;
BEGIN
    -- Obtener prefijo del documento
    SELECT prefijo INTO v_prefijo_doc FROM tipos_documento WHERE id = p_tipo_id;
    
    -- Obtener código de sucursal
    SELECT codigo_sucursal INTO v_codigo_suc FROM sucursales WHERE id = p_sucursal_id;
    
    -- Año actual
    v_anio := TO_CHAR(CURRENT_DATE, 'YYYY');
    
    -- Bloquear y obtener la secuencia para este tipo, sucursal y año
    -- Usamos correspondencia para contar, pero podrías tener una tabla de secuencias si prefieres
    SELECT COUNT(*) + 1 INTO v_secuencia 
    FROM correspondencia 
    WHERE tipo_id = p_tipo_id 
      AND sucursal_origen_id = p_sucursal_id 
      AND TO_CHAR(fecha_emision, 'YYYY') = v_anio;
    
    -- Formatear CITE: TIPO-SUC-AÑO-SEC (ej: INF-LPZ-2026-0001)
    v_cite_final := v_prefijo_doc || '-' || v_codigo_suc || '-' || v_anio || '-' || LPAD(v_secuencia::TEXT, 4, '0');
    
    RETURN v_cite_final;
END;
$$ LANGUAGE plpgsql;
