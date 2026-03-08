# Manual de Transformación: Sistema de Correspondencia Remoto y Multi-sucursal

Este documento detalla la evolución del sistema desde una arquitectura local hacia una solución empresarial en la nube, multiplataforma y segura.

## 1. Arquitectura de la Nube
El sistema ha sido migrado de una base de datos local a una infraestructura distribuida:
*   **Backend (Cerebro):** Alojado en **Render** (`https://siscorrespondencia.onrender.com`). Gestiona la lógica de negocio y seguridad.
*   **Base de Datos (Memoria):** Motor **PostgreSQL en Supabase**. Almacena tablas de usuarios, correspondencia y seguimiento.
*   **Almacenamiento (Storage):** Buckets en Supabase para persistencia de archivos PDF (`documentos`) y firmas digitales (`firmas`).

## 2. Seguridad y Autenticación
Se implementó un esquema de seguridad basado en estándares industriales:
*   **JWT (JSON Web Tokens):** El servidor genera un token al hacer login. Este token debe enviarse en cada consulta (`Authorization: Bearer <token>`).
*   **Middleware de Verificación:** El backend valida la autenticidad y expiración del token antes de permitir cualquier operación SQL.
*   **Encriptación:** Soporte para contraseñas seguras mediante `bcrypt`.

## 3. Lógica Multi-sucursal (Multi-tenant)
El sistema ahora permite la operación nacional separando datos por sede:
*   **Filtrado por Rol:** 
    *   `USUARIO`: Solo ve lo que él envía o recibe.
    *   `JEFE_AGENCIA`: Visualiza toda la correspondencia de su sucursal.
    *   `ADMIN`: Acceso total a todas las sucursales.
*   **Integridad de Datos:** Todas las consultas SQL incluyen filtros automáticos por `sucursal_id` basados en la identidad del usuario logueado.

## 4. Firma Digital y Gestión de Archivos
Funcionalidades avanzadas para la validez de los documentos:
*   **Lienzo de Firma:** Captura de trazos manuales en la pantalla del dispositivo.
*   **Cloud Upload:** Los archivos y firmas se suben directamente a la nube y se guardan mediante URLs públicas en la base de datos.
*   **Reportes PDF Oficiales:** Generación dinámica de documentos institucionales que incluyen:
    *   Encabezado oficial.
    *   Número de CITE generado automáticamente por sucursal.
    *   Código QR de seguimiento.
    *   Imagen de la Firma Digital integrada en el pie de página.

## 5. Configuración de Android (V1938T)
Se realizaron ajustes críticos para garantizar la compatibilidad y movilidad:
*   **Nueva Identidad:** El ID de aplicación se cambió a `com.sistema.correspondencia.remoto` para evitar conflictos de instalación.
*   **Estructura de Carpetas:** Se movió el archivo `MainActivity.kt` a la ruta de paquetes correcta para solucionar errores de ejecución.
*   **Min SDK 21:** Se elevó la versión mínima para soportar las librerías modernas de Supabase.
*   **Independencia de Firebase:** Se desactivó el SDK de Firebase en Windows y Android para eliminar conflictos de compilación de C++, confiando la lógica totalmente a Render y Supabase.

## 6. Instrucciones de Despliegue
Para aplicar cambios nuevos:
1.  Realizar cambios en el código local.
2.  Ejecutar `git add .` -> `git commit` -> `git push`.
3.  Render detectará automáticamente el push y actualizará la API pública.

---
*Documentación generada automáticamente el 6 de marzo de 2026.*
