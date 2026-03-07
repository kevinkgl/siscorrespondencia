-- 1. Función de notificación para nueva correspondencia
CREATE OR REPLACE FUNCTION notify_new_correspondence()
RETURNS TRIGGER AS $$
DECLARE
    payload JSON;
BEGIN
    -- Construir un JSON con la info básica del documento
    payload := json_build_object(
        'id', NEW.id,
        'cite', NEW.cite_numero,
        'asunto', NEW.asunto,
        'destinatario_id', NEW.destinatario_id,
        'prioridad', NEW.prioridad
    );
    
    -- Emitir la notificación a través de un canal llamado 'nueva_correspondencia'
    PERFORM pg_notify('nueva_correspondencia', payload::text);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Trigger para la tabla correspondencia
DROP TRIGGER IF EXISTS trg_notify_correspondence ON correspondencia;
CREATE TRIGGER trg_notify_correspondence
AFTER INSERT ON correspondencia
FOR EACH ROW EXECUTE FUNCTION notify_new_correspondence();
