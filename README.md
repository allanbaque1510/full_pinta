# FullPinta — App Flutter

Marketplace de descubrimiento y agendamiento para barberías, gabinetes de estética y uñas (mercado inicial: Guayaquil, Ecuador). Este repositorio es el **frontend**, un solo proyecto Flutter con selector de contexto — no hay una app para clientes y otra para negocios, es la misma app entrando con distintos "sombreros" (§3.2 de la especificación).

El **backend** (Laravel + PostgreSQL/PostGIS) vive en otro repositorio y ya tiene las Fases 0–10 terminadas. Este proyecto consume su API tal como la documenta [`docs/api-referencia.md`](docs/api-referencia.md).

## Documentos de referencia (léelos en este orden)

1. [`context/fullpinta-especificacion.md`](context/fullpinta-especificacion.md) — el **qué** y el **por qué** del producto: modelo de dominio, reglas de negocio, roles, monetización. Fuente de verdad de todo lo que no sea contrato HTTP.
2. [`docs/api-referencia.md`](docs/api-referencia.md) — el **contrato HTTP** exacto que este frontend consume: request/response de cada endpoint.
3. [`context/plan-implementacion.md`](context/plan-implementacion.md) — en qué orden se construyó el backend y qué decisiones se tomaron fase a fase (incluye los "bloqueadores externos": Firebase, Google Maps, plantillas de WhatsApp, etc.).
4. [`docs/frontend-flutter.md`](docs/frontend-flutter.md) — este documento explica el **cómo** del lado Flutter: arquitectura, qué se construyó en esta primera versión, qué quedó fuera y por qué, y las notas para el equipo de backend sobre huecos del contrato que aparecieron al construir la UI real.
5. [`.claude/skills/flutter-convenciones/SKILL.md`](.claude/skills/flutter-convenciones/SKILL.md) — convenciones de código a seguir al tocar este proyecto (arquitectura, nomenclatura, DRY, widgets reutilizables).

## Qué hay en esta primera versión

Cliente (búsqueda, agendamiento, cuenta) y panel de negocio/staff (locales, catálogo, personal, agenda) — el detalle completo de pantallas está en `docs/frontend-flutter.md`. En una frase: se puede registrar un negocio, configurar un local completo (horarios, servicios, personal, turnos), un cliente puede encontrarlo, ver su disponibilidad real y agendar, y el local puede gestionar esa cita (incluidos walk-ins) hasta completarla y recibir una reseña.

Lo que se dejó **explícitamente** fuera de este primer build — y por qué — está detallado en `docs/frontend-flutter.md`, sección "Qué queda fuera". En resumen: todo lo que depende de una credencial que todavía no existe (Firebase, OAuth de Google, API key de Google Maps) y todo lo que el propio producto decidió no cobrar en sus primeros ~6 meses (Billing/suscripción).

## Requisitos

- Flutter 3.29+ / Dart 3.7+ (`flutter --version` para confirmar)
- El backend de Laravel corriendo y accesible desde donde se ejecute la app

## Configuración de entorno

La URL del backend (y, a futuro, las API keys de servicios de Google) se configuran por `--dart-define`, nunca hardcodeadas en el código. Hay dos formas de pasarlas — usa la segunda, es la cómoda:

**Opción rápida, una sola variable:**
```bash
flutter run --dart-define=API_BASE_URL=http://localhost/full-pinta-api/public/api/v1
```

**Opción recomendada, archivo de entorno:**
1. Copia `dart_defines.example.json` a `dart_defines.json` (este último **no se commitea**, ya está en `.gitignore` — cada desarrollador tiene el suyo con sus propios valores locales).
2. Ajusta `API_BASE_URL` a donde tengas el backend corriendo.
3. Corre con:
   ```bash
   flutter run --dart-define-from-file=dart_defines.json
   ```

`dart_defines.json` es también el lugar reservado para cuando existan las credenciales de Google Maps / Google Sign-In (hoy están vacías porque el código de esta versión todavía no las usa — ver `docs/frontend-flutter.md`).

### Ojo con el host según dónde corras la app

| Dónde corre la app | Backend servido en Laragon/Apache (`.../public/api/v1`) |
|---|---|
| Windows desktop / Chrome (misma PC que el backend) | `http://localhost/full-pinta-api/public/api/v1` |
| Emulador de Android | `http://10.0.2.2/full-pinta-api/public/api/v1` (el emulador no resuelve `localhost` como la PC anfitriona) |
| Dispositivo físico en la misma red | `http://<IP-de-tu-PC-en-la-red>/full-pinta-api/public/api/v1` |

## Correr el proyecto

```bash
flutter pub get
flutter run --dart-define-from-file=dart_defines.json -d chrome   # o -d windows, o un emulador/dispositivo
```

## Verificación

```bash
flutter analyze   # 0 issues al momento de este commit
flutter test      # smoke test de arranque
flutter build web # valida que compila de punta a punta
```

`flutter analyze` es la validación rápida después de cualquier cambio. Antes de dar por buena una función completa, probarla contra el backend real con `flutter run` — `analyze`/`test` no verifican que un flujo de negocio funcione de punta a punta.

## Estructura del código

Ver `docs/frontend-flutter.md` para el detalle de arquitectura (capas, patrones, mapa de pantallas). Resumen de carpetas:

```
lib/
  core/       infraestructura (red, storage, theme, router, utils, widgets compartidos)
  data/       modelos y repositorios (uno por módulo del backend: identity, directory, catalog, staffing, scheduling, reviews)
  state/      providers Riverpod compartidos entre pantallas (sesión, repositorios)
  features/   una carpeta por feature, un archivo por pantalla
```
