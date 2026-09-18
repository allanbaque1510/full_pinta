---
name: flutter-convenciones
description: Convenciones de arquitectura y estilo para el frontend Flutter de FullPinta. Úsala siempre que se agregue o modifique una pantalla, modelo, repositorio o widget en lib/ — antes de escribir código nuevo, para no reinventar un patrón que ya existe en el proyecto.
---

# Convenciones Flutter — FullPinta

Este proyecto consume la API documentada en `docs/api-referencia.md` (fuente de verdad del contrato HTTP) y el dominio descrito en `context/fullpinta-especificacion.md`. Antes de agendar, buscar precios, roles o reglas de negocio, confirma ahí — nunca inventes un endpoint o un campo que esos documentos no mencionen.

## Capas y dónde va cada cosa

```
lib/
  core/       infraestructura sin conocimiento de dominio (red, storage, theme, utils, widgets genéricos)
  data/
    models/   clases de datos, agrupadas por módulo del backend (identity, directory, catalog, staffing, scheduling, reviews)
    repositories/  un repositorio por módulo, un método por endpoint
  state/      providers Riverpod que se comparten entre varias pantallas (sesión, repos)
  features/   una carpeta por feature, un archivo por pantalla/paso
```

**Regla de oro:** si algo ya existe en `core/widgets/` o `core/utils/`, se reusa — no se copia ni se reescribe una variante local.

## Modelos (`data/models/`)

- Clases inmutables (`final` fields), constructor `const` cuando se pueda.
- `factory Modelo.fromJson(Map<String, dynamic> json)` a mano, sin `build_runner`/codegen — este proyecto no lo usa, para no depender de herramientas de compilación extra en cada cambio de modelo.
- Los nombres de campo en Dart son `camelCase`; el `fromJson` traduce desde el `snake_case` de la API (`json['negocio_id']` → `negocioId`). Nunca se expone `snake_case` fuera de `fromJson`.
- `precio`, `comision_pct` y cualquier `numeric` de Postgres viajan como **String** (`json['precio']?.toString() ?? '0'`) — nunca `double.parse` en el modelo. La conversión a número para mostrar pasa por `AppFormatters.dinero(...)`, nunca a mano en un widget.
- Un modelo se agrupa en el archivo del módulo al que pertenece en el backend (`staffing_models.dart`, `scheduling_models.dart`...), no un archivo por clase — son muchas entidades pequeñas y un archivo por clase multiplica el boilerplate de imports sin ganar nada.
- Listas/mapas que vienen `null` de la API se normalizan a `[]`/`{}` en el `fromJson` (`(json['items'] as List<dynamic>? ?? [])`), así el resto de la app nunca chequea null en una colección.

## Repositorios (`data/repositories/`)

- Un repositorio por módulo del backend, inyectado por Riverpod (`state/repository_providers.dart`).
- Un método por endpoint de `docs/api-referencia.md`, con el mismo nombre en español que la acción documentada (`crearCita`, `cancelar`, `activarLocal`).
- Todo método hace `try { ... } catch (e) { throw DioClient.mapearError(e); }` — nunca se deja escapar un `DioException` crudo hacia una pantalla.
- El header `Idempotency-Key` (vía `Idempotency.nuevaClave()`) se agrega **solo** en los tres verbos que `api-referencia.md` marca explícitamente: crear cita, walk-in, cancelar. No se agrega "por si acaso" a otros POST.

## Estado (Riverpod)

- `Provider` simple para instanciar repositorios (sin estado propio).
- `StateNotifierProvider` **solo** para estado que cruza varias pantallas: la sesión (`SessionController`) es el caso central — token, contexto de acceso, contexto activo (§3.2).
- Para el data-fetching de una sola pantalla (una lista, un detalle), **no** se crea un provider nuevo: se usa `ConsumerStatefulWidget` con el patrón local `_cargando` / `_error` / `_data` + un método `_cargar()` llamado desde `initState`. Es más código por pantalla, pero es explícito y no obliga a inventar un family provider por cada id que se navega. Ver `lib/features/discovery/search_home_screen.dart` como referencia del patrón.
- Un wizard multi-paso (como el agendamiento) usa una sola clase de estado mutable (`BookingDraft`) que un widget controlador (`BookingFlowScreen`) pasa hacia abajo por constructor — no Riverpod global, porque ese estado no debe sobrevivir fuera del flujo de navegación.

## Widgets reutilizables — revisar antes de crear uno nuevo

| Widget | Para qué |
|---|---|
| `AsyncValueView<T>` | Pintar un `AsyncValue` (loading/error/vacío/datos) sin repetir el switch |
| `ListScaffold<T>` + `CrudTile` | Pantallas "listar → crear con FAB → editar/eliminar por fila" (horarios, recursos, turnos...) |
| `showAppFormSheet` | Modal bottom sheet consistente para formularios de creación/edición |
| `MultiSelectChips<T>` | Selección múltiple tipo "reemplazar el conjunto completo" (amenidades) |
| `PrimaryButton` | Botón de acción con su propio spinner — evita doble-tap en acciones de red |
| `EmptyState` / `ErrorState` | Estados vacío/error con el mismo look en toda la app |
| `confirmarDialogo` / `mostrarError` / `mostrarMensaje` | Confirmaciones y feedback consistentes (`core/widgets/confirm_dialog.dart`) |
| `StarRatingView` / `StarRatingInput` | Mostrar o capturar un puntaje de 1-5 |
| `PhotoCarousel` / `NetworkAvatar` | Fotos de local/profesional con placeholder y error consistentes |

## Nomenclatura

- Todo identificador de dominio (clases, campos, nombres de pantalla, mensajes al usuario) va **en español** y usa el mismo término que `fullpinta-especificacion.md`/`api-referencia.md` — `Cita`, `local`, `profesional`, `hold`, `walk-in`, nunca traducciones propias como `Appointment` o `Booking`.
- Nombres de archivo: `snake_case.dart`. Nombres de clase: `PascalCase`. Nombres de provider: `camelCase` terminado en `Provider` (`sessionControllerProvider`).
- Comentarios solo cuando explican un **porqué** no obvio (una regla de negocio, una limitación real de la API) — nunca un comentario que repite lo que el código ya dice. Cuando el comentario cita una regla del dominio, referencia la sección (`§5.4`, `§4.7`) igual que hace `context/fullpinta-especificacion.md`.

## Manejo de errores

- Nunca `catch (e) { print(e) }` ni silenciar un error de red sin mostrarlo — la única excepción son acciones de "mejor esfuerzo" ya marcadas como tales en el código (ej. `cerrarSesion()` revocando el token).
- Todo error de una acción disparada por el usuario (botón, formulario) se muestra con `mostrarError(context, DioClient.mapearError(e).mensaje)`, o con el campo específico vía `error.errorDe('campo')` cuando aplica.

## DRY — antes de escribir algo nuevo

1. ¿Ya hay un widget en `core/widgets/` que resuelve esto? Úsalo.
2. ¿Ya hay un modelo o `etiqueta*()`/`texto*()` helper (`textoEstadoCita`, `etiquetaVertical`, `etiquetaRolStaffing`...) para este enum del backend? Reusarlo evita que dos pantallas traduzcan el mismo código a español de forma distinta.
3. ¿El patrón de pantalla ya existe en otro módulo (CRUD simple, perfil público, wizard)? Copia la forma, no la lógica — cada pantalla nueva de un patrón conocido debería ser mayormente "cambiar los campos", no reinventar el flujo.
