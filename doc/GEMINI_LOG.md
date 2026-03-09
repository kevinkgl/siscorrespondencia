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

**Estado:** Despliegue completado con éxito.

---

## [2026-03-07] - Despliegue Web Finalizado
**Acciones:**
- Corrección de sintaxis SQL (escape de `$`) en el repositorio.
- Adición de importación `foundation.dart` para soporte de `kIsWeb`.
- Ejecución exitosa de `flutter build web --release`.
- Despliegue final a Firebase Hosting.

**URL de Producción:** https://sistemacorrespondencia-3fbba.web.app

---

## [2026-03-07] - Corrección en Gestión de Usuarios (Web)
**Problema:** Error `TypeError: "1": type 'String' is not a subtype of type 'int'` al listar y crear usuarios.

**Soluciones Aplicadas:**
- **Modelo:** Actualización de `UserModel.fromMap` con parseo robusto (`int.parse`) para los campos `id` y `sucursalId`.
- **Repositorio:** Actualización de `UserRepository` (`getUsers`, `getRoles`, `getSucursales`) para asegurar que todos los IDs sean tratados como integers antes de llegar a la UI.

**Estado:** Pendiente de redespliegue.

---

## [2026-03-08] - Análisis de Conectividad Híbrida (PostgreSQL vs Supabase)
**Objetivo:** Clarificar el funcionamiento de la aplicación con bases de datos locales y remotas.

**Hallazgos Técnicos:**
1. **PostgreSQL Local:** Utilizado por las versiones **nativas (Windows/Android)** a través de `DatabaseService`. Se conecta directamente a `localhost` o una IP local configurada.
2. **Supabase (Vía Backend):** Utilizado por la versión **Web**. Las consultas viajan al backend en Render (`https://siscorrespondencia.onrender.com/api`), el cual se conecta a una base de datos de Supabase mediante la variable `DATABASE_URL`.
3. **Supabase SDK (Storage):** Utilizado en **todas las plataformas** exclusivamente para el almacenamiento de archivos (adjuntos y firmas). Se inicializa en `main.dart`.

**Configuraciones Identificadas:**
- **Host Local:** `192.168.0.26` (Android) / `localhost` (Windows).
- **URL Supabase (Storage):** `https://yemhcbdyxcuflvhvhsmo.supabase.co`.
- **Backend URL:** `https://siscorrespondencia.onrender.com/api`.

**Conclusión:** La app es compatible con ambos entornos, funcionando de forma local para nativo y remota para web por defecto.

---

## [2026-03-08] - Plan de Migración de Base de Datos a Supabase
**Objetivo:** Centralizar la base de datos en la nube (Supabase) para que todas las plataformas compartan la misma información.

**Acciones:**
1. Análisis del backup local `doc/sistema_correspondencia`.
2. Generación de script SQL de migración compatible con Supabase (Schema, Constraints y Datos iniciales).
3. Definición de estrategia para actualizar `DatabaseService` en Flutter.

**Impacto:**
- Eliminación de la dependencia de base de datos local.
- Sincronización en tiempo real entre Windows, Android y Web.
- Escalabilidad del sistema.

---

## [2026-03-08] - Migración a Base de Datos en la Nube (Supabase)
**Acción:** Cambio de conexión de base de datos local a Supabase Cloud.

**Cambios Técnicos:**
1. **`lib/core/database/database_service.dart`:** Se actualizó el método `_connect()` para conectarse directamente a `db.yemhcbdyxcuflvhvhsmo.supabase.co`.
2. **Seguridad:** Se habilitó `SslMode.require` para cumplir con los estándares de Supabase.
3. **Optimización:** Se eliminó la detección de host local (`localhost`, IP) para forzar el uso de la base de datos centralizada.

**Impacto:**
- **Plataformas Nativas (Windows/Android):** Ahora se conectan directamente a la nube.
- **Plataforma Web:** Continúa usando el backend en Render, que a su vez se conecta a Supabase.
- Sincronización: Los datos registrados en la app de Windows ahora se verán instantáneamente en la versión Web y Android.

---

## [2026-03-08] - Despliegue de Producción y Sincronización Git
**Objetivo:** Publicar la versión con base de datos en la nube y asegurar el código en el repositorio.

**Acciones:**
1. Generación de build web (`flutter build web --release`).
2. Despliegue exitoso a Firebase Hosting.
3. Commit y Push a GitHub sincronizando todos los cambios de configuración.

**Estado:** Sistema centralizado y en producción.

---

## [2026-03-08] - Corrección de Esquema en Supabase (Soft Delete)
**Problema:** Error `column "deleted_at" does not exist` detectado durante la ejecución en Windows al intentar cargar sucursales.

**Causa:** El código de la aplicación (Repository) espera soporte para borrado lógico (`deleted_at`), pero el esquema inicial migrado no contenía esta columna.

**Solución:**
1. Se identificaron las tablas afectadas: `sucursales`, `usuarios`, `roles`, `tipos_documento`, `correspondencia`.
2. Se generó un script `ALTER TABLE` para añadir la columna `deleted_at` con soporte de zona horaria.

**Resultado:** Compatibilidad restaurada entre el código Dart y la base de datos Supabase.

---

## [2026-03-08] - Sincronización de Columnas (CITE y Correspondencia)
**Problema:** Errores `column "tipo_id" does not exist` y fallo al generar CITE preliminar.

**Causa:**
1. Discrepancia de nombres: El código esperaba `tipo_id` pero la base de datos tenía `tipo_documento_id`.
2. Faltaban columnas de control secuencial (`gestion`, `numero_secuencial`) necesarias para la lógica de generación de CITEs institucionales.

**Solución:**
1. Renombramiento de la columna `tipo_documento_id` a `tipo_id`.
2. Creación de columnas `gestion` y `numero_secuencial` en la tabla `correspondencia`.
3. Adición de `correlativo_actual` en `tipos_documento` para mantener el conteo de documentos por tipo.

**Estado:** Corregido en Supabase.

