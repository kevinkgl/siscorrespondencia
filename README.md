# sistema_correspondenciaf

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.



ANEXO 1
TÉRMINOS DE REFERENCIA
“ADQUISICIÓN E IMPLEMENTACIÓN DE UN SISTEMA DE CORRESPONDENCIA”
 
 
1. OBJETO DE LA CONTRATACIÓN
 
Adquirir e implementar un sistema integral de correspondencia que permita la organización, emisión, recepción, registro, seguimiento, control y archivo de:
 
•   Cartas externas
 
•   Comunicaciones internas
 
•   Informes
 
•   Circulares
 
•   Memorándums
 
•   Documentos oficiales de ASFI
 
•   Otros documentos internos
 
2. EL SISTEMA DEBERÁ CUBRIR:
 
Correspondencia de Oficina central, sucursales y agencias a nivel nacional de forma digital y su integracióncon sistemas de gestión documental para el archivo institucional.
 
3. REQUISITOS PARA EL FUNCIONAMIENTO
 
•   Ventanilla única: para el registro y control de ladocumentación (física) entrante ysaliente.
 
o Asignación de número de CITE automático (con código QR de ser posible).
 
o Acuse de recibo físico / digital.
 
•   Emisión  de  documentos:  plantillas  para cartas, circulares, memorándums, comunicaciones internas, informes con autenticación u otros documentos y la asignación de responsables (fechas, nombres,plazos de respuesta).
 
•   Alertas para plazos: que sean automáticas con vencimiento (ej. 24h, 3 días, 10 días, según el plazo que sedesigne); reportes de tiempos de respuesta.
 
•   Clasificación de documentos: Correspondencia confidencial, privada y pública, de acuerdo con la normativa
interna de Crecer IFD.
 
•   Archivo  y  conservación: conservación de  la  documentación  digital  mínima  de 10 años  (especificar
disponibilidad y costo de mantenimiento).
 
•   Plataforma accesible: uso del sistema tanto en oficina central, sucursales y agencias en zonas alejadas.
 
•   Compatibilidad con sistemas operativos: de preferencia estándar (o de acuerdo con lo establecido por el área de sistemas).
 
•   Integración con correo institucional: para ventanilla virtual de ASFI (o especificar alternativas).
 
•   Escalabilidad: para la
asignación de usuarios de al menos 1752 usuarioso más.
 
•   Respaldo automático: contra la pérdida de información, fallas técnicas o eliminación accidental.
 
•   Digitalización: escaneo seguro y almacenamiento en repositorios cifrados.


RESPUESTA ALA PREGUNTA PLAN DE PROGRAMACION ES 
¡Excelente propuesta! Tienes un proyecto robusto entre manos. Trabajar con una institución financiera (como Crecer IFD) exige niveles altos de **seguridad, trazabilidad y disponibilidad**.

Dado que necesitas escalar a más de **1,750 usuarios** y manejar sedes a nivel nacional, aquí tienes mi análisis técnico y el plan de acción para ejecutarlo con **Flutter**.

---

## 1. Análisis de Arquitectura y Base de Datos

Para este sistema, la elección de la base de datos es crítica debido al volumen de documentos y la necesidad de integridad referencial.

### Base de Datos Recomendada: **PostgreSQL**

* **Por qué:** Es una base de datos relacional (SQL) extremadamente sólida para manejar jerarquías de documentos y relaciones complejas entre sucursales y usuarios.
* **Almacenamiento de Documentos:** Los archivos físicos (PDFs, imágenes) **no** deben guardarse directamente en la base de datos. Utilizaremos un **Object Storage** (como AWS S3, Google Cloud Storage o un servidor MinIO local) y guardaremos solo la *ruta* en PostgreSQL.
* **Cifrado:** Permite cifrado nativo (AES-256) para cumplir con los requisitos de seguridad de ASFI.

### Backend: **Node.js (NestJS) o Go**

* Flutter necesita una API para comunicarse con la base de datos. Un backend robusto gestionará la generación de códigos QR, la lógica de los CITEs automáticos y las notificaciones.

---

## 2. Estrategia de Desarrollo en Flutter

Flutter es ideal aquí porque puedes desplegar la misma base de código para:

1. **Web:** Para el personal administrativo en oficinas.
2. **Mobile (Android/iOS):** Para jefes de agencia que necesitan aprobar documentos o recibir alertas de plazos en movimiento.
3. **Desktop (Windows):** Para ventanilla única, facilitando la integración con escáneres.

---

## 3. Plan de Acción (Roadmap)

He dividido el proyecto en 4 fases para asegurar una implementación ordenada:

### Fase 1: Cimiento y Seguridad (Semanas 1-3)

* **Modelado de Datos:** Estructurar tablas para Usuarios, Sucursales, Tipos de Documentos y Flujos de Aprobación.
* **Autenticación:** Implementar Login con **OAuth2 o Active Directory** (muy común en instituciones financieras).
* **Gestión de Roles (RBAC):** Definir quién puede ver correspondencia "Confidencial" vs "Pública".

### Fase 2: El Corazón del Sistema - Ventanilla Única (Semanas 4-7)

* **Módulo de Registro:** Formulario de entrada con generación de **CITE automático**.
* **Generador de QR:** Integrar librería `barcode_kit` en Flutter para imprimir etiquetas de recepción.
* **Digitalización:** Implementar el módulo de carga de archivos con previsualización de PDF.

### Fase 3: Flujos, Alertas y Plantillas (Semanas 8-11)

* **Motor de Plantillas:** Crear editor de texto enriquecido en Flutter para cartas y memorándums.
* **Sistema de Alertas:** Configurar un **Cron Job** en el servidor que revise plazos y envíe notificaciones push/correo (Firebase Cloud Messaging).
* **Integración ASFI:** Desarrollo de la API de conexión con la ventanilla virtual institucional.

### Fase 4: Archivo, Auditoría y Despliegue (Semanas 12-14)
* **Módulo de Auditoría:** Registro de cada clic (quién leyó, quién descargó, quién modificó).
* **Respaldo:** Configuración de backups automáticos cada 24h.
* **Pruebas de Carga:** Simular el acceso concurrente de los 1752 usuarios.

---

## 4. Consideraciones Técnicas Clave

| Requisito | Solución Propuesta |
| --- | --- |
| **Escalabilidad** | Uso de **Docker y Kubernetes** para que el sistema no se caiga si todos los usuarios entran a la vez. |
| **Conservación 10 años** | Implementar políticas de "Cold Storage" (almacenamiento de bajo costo para archivos antiguos). |
| **Zonas alejadas** | Optimizar Flutter con **Local Caching** (SQLite) para que el sistema funcione con internet lento y sincronice al recuperar conexión. |

---

## Próximo Paso Sugerido


---
## DETALLE DE IMPLEMENTACIÓN (DESARROLLO POR FASES)

A continuación se detallan las fases de programación ejecutadas para cumplir con los términos de referencia de Crecer IFD:

### Fase 1: Cimientos y Conectividad
* **Configuración Desktop:** Optimización para Windows con `window_manager` (ventana de 1280x800).
* **Arquitectura:** Implementación de Clean Architecture (Capa de datos, repositorios y UI).
* **Navegación:** Configuración de `GoRouter` para el flujo entre Login y Dashboard.

### Fase 2: Autenticación y Seguridad
* **PostgreSQL:** Conexión segura con el servicio de base de datos.
* **Roles (RBAC):** Sistema de permisos para Administradores, Ventanilla y Usuarios finales.
* **Seguridad:** Gestión de sesiones persistentes con Riverpod.

### Fase 3: Ventanilla Única y CITE Automático
* **Lógica de CITE:** Generación automática: `[TIPO]-[SUCURSAL]-[AÑO]-[CORRELATIVO]`.
* **Registro:** Formulario completo para correspondencia interna y externa.
* **QR:** Generación de código QR de seguimiento para cada documento registrado.

### Fase 4: Bandejas de Entrada y Salida
* **Gestión Documental:** Separación de documentos enviados y recibidos.
* **Personalización:** Cada usuario visualiza únicamente lo que le compete según su ID y sucursal.

### Fase 5: Trazabilidad y Línea de Tiempo
* **Seguimiento:** Pantalla de detalle con historial completo de movimientos.
* **Metadata:** Visualización de asunto, prioridad, clasificación y fechas.

### Fase 6: Flujo y Derivación
* **Acciones:** Botones para "Recibir" y "Derivar" documentos.
* **Interacción:** Diálogo de derivación con selección de usuario destino y observaciones.

### Fase 7: Digitalización y Adjuntos
* **Escaneo Digital:** Carga de PDFs e Imágenes mediante `file_picker`.
* **Repositorio Seguro:** Copia automática de archivos a una carpeta local protegida renombrada por CITE.

### Fase 8: Buscador Inteligente
* **Filtros Proactivos:** Búsqueda por texto (ILIKE) en tiempo real por CITE, Asunto o Remitente.
* **Estado:** Filtrado rápido por estado (Registrado, Recibido, En Tránsito).

### Fase 9: Alertas y Plazos (Semáforo)
* **Inteligencia de Plazos:** Alertas automáticas (24h, 3 días, 10 días).
* **Visualización:** Colores de urgencia (Rojo/Naranja) integrados en las listas de correspondencia.
* **Estadísticas:** Contadores reales en el inicio (Vencidos/Pendientes).

### Fase 10: Reportes y Auditoría Final
* **Gráficos:** Visualización de volumen por sucursal con `fl_chart`.
* **Audit Log:** Registro maestro de todos los clics y movimientos del sistema para fiscalización.
* **Panel Admin:** Dashboard gerencial restringido para el rol Administrador.

---
**Desarrollado para:** Crecer IFD - Sistema de Correspondencia Multiplataforma.
**Base de Datos:** PostgreSQL 16
**Framework:** Flutter (Windows Desktop focus)



resumen de la aplicacion de correspondencia 

Esta aplicación, denominada Sistema de Correspondencia, es una plataforma de escritorio (principalmente) 
  desarrollada con Flutter para la gestión, seguimiento y control de documentos y correspondencia dentro de
  una organización con múltiples sucursales.

  Aquí tienes un resumen detallado de sus capacidades y estructura:


  1. Funcionalidad Principal
   * Gestión de Correspondencia (CITEs): Permite registrar y administrar diferentes tipos de documentos como     cartas, memorándums, informes y comunicaciones internas. Genera automáticamente números de referencia  
     únicos (CITEs) siguiendo un formato institucional (ej. INF-LPZ-2026-0001).
   * Trazabilidad y Seguimiento: El sistema mantiene un historial detallado (seguimiento) de cada documento,     registrando quién lo envió, quién lo recibió, derivaciones entre usuarios o sucursales y cambios de    
     estado (Registrado, En Tránsito, Recibido, Archivado).
   * Gestión Multi-Sucursal: Soporta la operación en distintas oficinas o agencias, permitiendo el envío de 
     correspondencia tanto interna como externa entre ellas.
   * Integración de Archivos y QR: Permite adjuntar archivos digitales a los registros de correspondencia y 
     genera códigos QR para facilitar la identificación y el rastreo físico de los sobres o documentos.     
   * Control de Plazos y Prioridades: Clasifica la correspondencia por prioridad (Normal, Urgente, etc.) y  
     permite establecer fechas límite para alertas y seguimiento de trámites.


  2. Stack Tecnológico
   * Frontend: Flutter (Dart) con soporte para Windows/Escritorio.
   * Base de Datos: PostgreSQL (usando el paquete postgres), lo que indica un enfoque hacia una base de     
     datos centralizada y robusta.
   * Gestión de Estado: Riverpod (flutter_riverpod), una de las soluciones más modernas y potentes en       
     Flutter.
   * Navegación: GoRouter para un manejo eficiente de las rutas.
   * Visualización de Datos: Utiliza fl_chart, lo que sugiere paneles de estadísticas o dashboards para     
     monitorear el flujo de documentos.


  3. Seguridad y Roles
  El sistema cuenta con un esquema de seguridad basado en roles:
   * ADMIN: Gestión total del sistema, usuarios y sucursales.
   * VENTANILLA: Registro de entrada y salida de correspondencia.
   * JEFE_AGENCIA: Supervisión de la correspondencia en su sucursal.
   * USUARIO: Uso general para envío y recepción personal.


  4. Estructura del Código
  La aplicación sigue una arquitectura limpia organizada por características (features):
   * auth/: Manejo de sesiones y seguridad.
   * correspondence/: El núcleo del negocio (modelos, repositorios y pantallas de gestión).
   * home/: Panel principal o dashboard.
   * core/: Configuración global de base de datos, rutas y temas visuales.


  En resumen, es una herramienta empresarial diseñada para digitalizar el flujo de papel, asegurar que      
  ningún documento se pierda y optimizar la comunicación formal entre los departamentos de una institución




MEJORAS SUGERIDAS

Basado en el análisis de tu arquitectura y el objetivo del sistema, aquí tienes varias sugerencias de     
  mejora divididas por áreas, desde lo técnico hasta lo funcional:


  1. Seguridad y Robustez (Crítico)
   * Hasheo de Contraseñas: En tu archivo database_schema.sql mencionas que usarás hashes, pero en el insert     de prueba usas texto plano. Asegúrate de implementar BCrypt o Argon2 en el backend o en el servicio de 
     autenticación antes de que toque la base de datos.
   * Auditoría Completa (Soft Delete): En lugar de borrar registros (como adjuntos o correspondencia), añade     una columna deleted_at. En sistemas de correspondencia legal/institucional, nunca se debe eliminar     
     información, solo "anularla".
   * Manejo de Conexiones: Al ser una app de escritorio conectándose a Postgres, asegúrate de implementar un     "Connection Pool" o un manejador de reconexión automática, ya que las apps de escritorio sufren        
     micro-cortes de red que pueden romper la sesión de la DB.


  2. Mejoras de Funcionalidad (Workflow)
   * Firma Digital/Electrónica: Para que los documentos tengan validez legal sin imprimirlos, podrías       
     integrar firmas digitales (puedes usar el paquete syncfusion_flutter_signaturepad para capturar        
     rúbricas o integrar certificados X.509).
   * Sistema de Notificaciones en Tiempo Real: Actualmente parece que el usuario debe "refrescar" o entrar a     ver si tiene algo nuevo. Podrías usar WebSockets (PostgreSQL `LISTEN/NOTIFY`) o un servicio como       
     Supabase/Firebase para que aparezca una notificación de escritorio (local_notifier) en cuanto llegue un     CITE.
   * Motor de Búsqueda Avanzada: Añadir búsqueda por contenido (Full Text Search de Postgres) para encontrar     documentos no solo por CITE o asunto, sino por palabras clave dentro del cuerpo del mensaje.
   * OCR (Reconocimiento Óptico de Caracteres): Si el usuario sube un PDF escaneado (imagen), podrías       
     integrar un servicio (como Tesseract o Google Vision) para extraer el texto automáticamente y facilitar     la clasificación.


  3. Experiencia de Usuario (UI/UX)
   * Generación de PDFs Dinámica: No solo guardes el file_path. Usa el paquete pdf para generar
     automáticamente la carta o el informe con el logo de la institución, el CITE y el código QR ya
     insertados, listo para imprimir.
   * Dashboard Estadístico: Ya tienes fl_chart. Podrías incluir:
       * Tiempo promedio de respuesta por sucursal.
       * Documentos próximos a vencer (alertas rojas).
       * Carga de trabajo por usuario.
   * Modo Offline con Sincronización: Si una agencia se queda sin internet, la app debería permitir
     registrar correspondencia localmente (usando Isar o SQLite) y sincronizar con Postgres cuando vuelva la     conexión.


  4. Automatización y DevOps
   * Versionamiento de Base de Datos: En lugar de scripts manuales como db_update.dart, considera usar una  
     herramienta de migración para que todos los desarrolladores y el servidor de producción estén siempre  
     en la misma versión del esquema.
   * Generación Automática de CITEs: Asegúrate de que la lógica del CITE sea un Procedimiento Almacenado    
     (Stored Procedure) en Postgres para evitar duplicados si dos personas en la misma sucursal guardan un  
     documento al mismo milisegundo.


  5. Sugerencia de Paquetes para estas mejoras:
   * pdf & printing: Para generar los documentos físicos.
   * local_notifier: Para alertas de escritorio en Windows/Linux.
   * share_plus: Para enviar el CITE rápidamente por email o aplicaciones externas.
   * watcher: Para monitorear si se añaden archivos a una carpeta específica y subirlos automáticamente.
