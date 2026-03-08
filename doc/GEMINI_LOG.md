# Bitácora de Desarrollo - Gemini CLI

Este archivo contiene el historial de cambios, propuestas de código y decisiones técnicas realizadas durante la colaboración con Gemini CLI.

---

## [2026-03-07] - Inicialización de Bitácora
**Objetivo:** Establecer un registro persistente de cambios y opciones de código en el proyecto.

**Estado del Proyecto:**
- **Proyecto:** `sistema_correspondenciaf` (Flutter/Dart).
- **Estructura:** Aplicación con backend en Node.js y base de datos SQL.
- **Configuración:** Usuario autenticado con plan Gemini Code Assist for Individuals.

**Acciones Realizadas:**
1. Creación de este archivo de registro en `doc/GEMINI_LOG.md`.
2. Configuración de la estrategia de documentación sistemática.

---

## [2026-03-07] - Plan de Acción: Despliegue Web Institucional
**Objetivo:** Definir la estrategia para publicar la aplicación en la web y permitir acceso remoto a usuarios institucionales.

**Estrategia Propuesta:**
1. **Infraestructura:** Migración de Base de Datos y Backend a servicios Cloud (Render/Railway/Google Cloud).
2. **Conectividad:** Configuración de URLs de producción en `api_client.dart` y manejo de variables de entorno en el Backend.
3. **Frontend:** Compilación de Flutter Web y despliegue en Firebase Hosting.
4. **Seguridad:** Implementación de HTTPS y configuración de políticas CORS.

**Próximos Pasos:**
- Analizar `backend/index.js` para adaptarlo a variables de entorno.
- Revisar `lib/core/api/api_client.dart` para gestión dinámica de URLs (Dev vs Prod).
- Preparar el comando de build de Flutter Web.

---

## [2026-03-07] - Análisis de Infraestructura Actual
**Estado Técnico:**
- **Backend:** Node.js con Express, PostgreSQL (pg), JWT y CORS habilitado. Preparado para variables de entorno (`PORT`, `DATABASE_URL`).
- **Frontend:** `ApiClient` implementado con `Dio`. Ya apunta a `https://siscorrespondencia.onrender.com/api` para entorno Web.
- **Autenticación:** Sistema híbrido; usa API Rest en Web y conexión directa en plataformas nativas.

**Observaciones:**
- Se detectó que la URL de producción ya está configurada en el código.
- Es necesario validar que el servidor en Render tenga las variables de entorno correctas.

---

## [2026-03-07] - Configuración de Despliegue Web
**Infraestructura de Hosting:**
- **Proveedor:** Firebase Hosting.
- **Project ID:** `sistemacorrespondencia-3fbba`.
- **Ruta de Publicación:** `build/web`.

**Comandos de Operación:**
1. `flutter build web --release` (Generación de bundle).
2. `firebase deploy --only hosting` (Publicación en vivo).

**Mejoras de Seguridad Sugeridas:**
- Configurar CORS en el backend para restringir orígenes a `sistemacorrespondencia-3fbba.web.app`.

---

## [2026-03-07] - Refuerzo de Seguridad y Guía de Firebase
**Cambios Realizados:**
- **Backend:** Actualización de `backend/index.js` para implementar una política de CORS blanca (Whitelist). Solo se permiten dominios de Firebase (`.web.app`, `.firebaseapp.com`) y entornos locales de desarrollo.
- **Configuración:** Definición de pasos críticos en la consola de Firebase para el despliegue exitoso.

**Checklist de Configuración:**
1. Habilitar Hosting en Firebase Console.
2. Configurar `DATABASE_URL` y `JWT_SECRET` en el panel de Render.
3. Ejecutar el ciclo de despliegue: `build` -> `deploy`.

---

## [2026-03-07] - Corrección de Errores en Flutter Web
**Problemas Identificados:**
1. Error de serialización: `DateTime` no era encodable para JSON en Web.
2. Error de tipos: `TypeError: String is not a subtype of int` al recibir IDs de la base de datos.
3. Incompatibilidad de `dart:io`: El uso de la clase `File` causaba crashes en el navegador.

**Soluciones Aplicadas:**
- **Repositorio:** Conversión explícita de `DateTime` a `toIso8601String()` y parseo robusto de IDs con `int.parse()`.
- **UI:** Migración de `File` a `dynamic` (Uint8List en Web / File en Nativo) para el manejo de adjuntos.
- **API:** Mejora en el método `uploadFileToCloud` para soportar carga de bytes directos a Supabase.

**Estado:** Pendiente de nuevo despliegue y verificación en producción.

---
