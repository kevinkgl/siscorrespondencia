-- 1. Crear índices para Búsqueda de Texto Completo (Full Text Search)
-- Esto permite buscar rápidamente en asunto y contenido

-- Añadimos una columna generada para el vector de búsqueda (opcional, pero más rápido)
-- O podemos usar índices funcionales. Usaremos índices funcionales para evitar alterar demasiado la tabla.

CREATE INDEX IF NOT EXISTS idx_correspondencia_fts ON correspondencia 
USING GIN (to_tsvector('spanish', coalesce(asunto, '') || ' ' || coalesce(contenido, '')));

-- 2. Mejorar la tabla de adjuntos para soportar metadatos de previsualización si fuera necesario
-- (Ya tiene tipo_mime, que es suficiente por ahora)
