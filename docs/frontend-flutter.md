# FullPinta — Frontend Flutter (primera versión)

Documento de trabajo del lado Flutter, hermano de [`api-referencia.md`](api-referencia.md) (contrato HTTP, mantenido por el backend) y de [`../context/plan-implementacion.md`](../context/plan-implementacion.md) (bitácora del backend). Este archivo cumple la misma función que esos dos, pero para el frontend: qué se construyó, qué se dejó fuera y por qué, y qué necesita saber el equipo de backend sobre huecos del contrato que aparecieron al construir la UI real contra él.

Fecha de esta primera versión: 2026-09-18.

---

## 1. Alcance de esta primera versión

Se construyeron **ambos lados** de la app en el mismo proyecto, con selector de contexto (§3.2 de la especificación) — no dos apps.

### Lado cliente
- Autenticación: teléfono + OTP, registro/login por correo (Google **diferido**, ver §3).
- Selector de contexto (cuando el usuario tiene más de un "sombrero").
- Búsqueda de locales por cercanía con filtros (vertical, precio, amenidades, disponibilidad, abierto ahora).
- Perfil público de local y de profesional.
- Flujo de agendamiento completo: selección de servicios → fecha → slots reales (agrupados por profesional) → confirmación → hold con cuenta regresiva de 10 min → confirmar.
- Mis citas (historial, detalle, cancelar, reagendar).
- Reseña post-cita.
- Lista de espera (anotarse cuando no hay cupo).
- Favoritos, consentimientos (otorgar/revocar por finalidad), preferencias de notificación, eliminar cuenta.

### Lado negocio/staff
- Crear negocio y locales; activar/pausar un local.
- Horarios, amenidades, fotos, servicios (desde el catálogo maestro), productos, solicitudes al catálogo maestro.
- Personal: alta de profesionales con su asignación inicial, asignarlos a locales adicionales, turnos recurrentes, cambios de turno por fecha, habilidades (qué servicio atiende cada quien), recursos físicos (sillas, mesas...), excepciones/cierres (de local, de profesional o de recurso).
- Agenda del local por día, con las seis transiciones de estado de la cita (confirmar, iniciar, completar con propina, no-show, cancelar) y registro de walk-ins.
- Reseñas del local: ver todas (no solo publicadas) y responder.

### Explícitamente fuera de esta versión, y por qué

| Área | Motivo |
|---|---|
| Push real (FCM/APNs) | No existe proyecto Firebase todavía (bloqueador externo, ver plan de implementación). Se construyó la pantalla de **preferencias** de notificación porque esa parte de la API no depende de Firebase; no se agregó `firebase_messaging` ni el registro de `device_token`. |
| Login con Google | Requiere un OAuth client id que no existe. El endpoint `POST /auth/google` está implementado en el repositorio (`AuthRepository`, sin usar todavía) para conectar el botón el día que haya credenciales — no se agregó a la UI de login para no ofrecer algo que falla en runtime. |
| Mapa embebido (Google Maps SDK) | Sin API key. La búsqueda es por lista con distancia; "Ver en mapa" abre la app de mapas del sistema con la coordenada via `url_launcher`, sin necesitar key. |
| Suscripción / cobros / liquidación (Billing) | El propio producto decidió "todo gratis los primeros ~6 meses" (§9.7) — no hay paywall que mostrar. El backend lo tiene listo para cuando se encienda. |
| Subida de archivos (fotos) | La API todavía solo registra una URL ya subida a algún storage externo (documentado en `api-referencia.md`). Los formularios de foto piden URL, no abren la galería del teléfono. |
| Vertical mascotas activa | Modelada en el backend pero no activada (§15.2) — el flujo de reserva no ofrece tamaño de mascota ni ese selector. |
| Dispositivos (`device_token`) | Depende de tener un token FCM real; sin Firebase no hay nada que registrar. La pantalla de preferencias de notificación sí se construyó porque no depende de esto. |

---

## 2. Arquitectura

Ver el detalle completo y el "por qué" de cada decisión en [`.claude/skills/flutter-convenciones/SKILL.md`](../.claude/skills/flutter-convenciones/SKILL.md) — ese archivo es la referencia viva que cualquier sesión de Claude Code carga automáticamente antes de tocar este código. Resumen:

- **Estado**: Riverpod 2.x. `Provider` para repositorios, `StateNotifierProvider` solo para la sesión (único estado realmente compartido entre pantallas). El resto es estado local por pantalla (`ConsumerStatefulWidget` + `_cargando`/`_error`/`_data`).
- **Ruteo**: `go_router`, con `redirect` centralizado que lee `SessionController` (token → contexto → contexto activo) y un `ChangeNotifier` puente para que el router reaccione a cambios de sesión sin necesitar una navegación explícita.
- **Red**: `dio` con interceptor de `Authorization: Bearer` automático y mapeo de todo error a `ApiException` (nunca se deja escapar un `DioException` crudo a una pantalla). `Idempotency-Key` solo en los tres verbos que `api-referencia.md` marca explícitamente (crear cita, walk-in, cancelar).
- **Modelos**: clases Dart escritas a mano (`fromJson`/`toJson`), sin `build_runner` — se prefirió evitar la fricción de codegen en este entorno. Agrupadas por módulo del backend, no una clase por archivo.
- **Sesión**: `flutter_secure_storage` para el token **y** una copia liviana del usuario logueado — la API no expone un endpoint "quién soy" fuera de los tres de login, así que esa copia es lo único que permite pintar la pantalla de cuenta sin re-pedir credenciales en cada arranque (ver §3, punto 1).

---

## 3. Notas para el equipo de backend

Cosas que aparecieron al construir la UI real contra `api-referencia.md` y que vale la pena que el backend conozca — ninguna bloqueó esta versión (se resolvió con un rodeo razonable en cada caso), pero cerrarlas simplificaría el frontend:

1. **No hay endpoint "quién soy" fuera del login.** `POST /auth/otp/verificar` / `POST /auth/google` / `POST /auth/login` devuelven `usuario`, pero no existe un `GET /usuario` o `GET /me` para refrescarlo después (ej. si el usuario edita su nombre — tampoco existe un `PATCH /usuario` todavía). El frontend cachea el `usuario` del último login en `flutter_secure_storage` (`SecureStorage.guardarUsuario`) y lo muestra tal cual en la pantalla de cuenta. Si el nombre/foto cambian por otro medio, la app no se entera hasta el próximo login.
2. **`GET /auth/contexto` no expone el `profesional_id`** de un contexto `tipo: "profesional"` — solo `local_id` y `rol` (ver el shape en `api-referencia.md`, sección Identity). Sin ese id, la app no puede filtrar "mi propia agenda" cuando el contexto activo es profesional: hoy `AgendaDiaScreen` en ese caso muestra la agenda completa del local, igual que al staff (ver comentario en `lib/features/agenda/agenda_dia_screen.dart`). Agregar `profesional_id` a esa fila resolvería esto de raíz.
3. **No hay `GET /negocios` que liste "los míos".** Se resolvió leyendo los contextos `tipo: "negocio"` de `GET /auth/contexto`, que ya trae `negocio_id`/`negocio_nombre` — funciona, pero es un uso lateral de ese endpoint más que una lista pensada para eso.
4. **El shape de `local`/`profesional` dentro de `GET /mis-favoritos`** se documenta como "el mismo shape público de perfil-publico", pero el ejemplo del contrato lo abrevia (`{ "id": "uuid", "nombre": "...", "...": "..." }`). El frontend lo parsea de forma tolerante con un modelo propio y liviano (`FavoritoLocal`/`FavoritoProfesional`, en `lib/data/models/favorito_model.dart`) que solo pide `id`/`nombre` y algunos campos opcionales, en vez de acoplarse a la forma completa de `LocalPerfilPublico`.
5. **No hay un endpoint público que liste los profesionales de un local.** `GET /locales/{local}/profesionales` es 🔒 solo-staff. La búsqueda de disponibilidad (`GET /locales/{local}/disponibilidad`) sí es pública y devuelve `profesional_id` por slot — el frontend usa eso más `GET /profesionales/{id}/perfil-publico` (también público) para resolver el nombre a mostrar, profesional por profesional. Funciona pero implica N llamadas extra en la pantalla de slots.
6. **Sin endpoint para que el cliente vea sus propias filas de `espera`.** `GET /locales/{local}/esperas` es "cualquier miembro del local" (staff), no el cliente que se anotó. El frontend deja al cliente anotarse (`POST`) pero no le muestra una lista de "en qué esperas estoy anotado".

Ninguno de estos puntos es una inconsistencia del backend respecto a lo documentado — todo se comporta tal como dice `api-referencia.md`. Son huecos de cobertura (cosas que ese contrato no necesitaba resolver hasta que hubo una pantalla real pidiéndolas).

---

## 4. Notas para quien siga con esta app

- **`flutter analyze` está en 0 issues** y `flutter build web` compila de punta a punta al momento de este commit — es la forma más rápida de verificar que un cambio no rompió nada, pero no reemplaza probar el flujo contra el backend real.
- **El smoke test** (`test/widget_test.dart`) solo confirma que la app arranca y llega al splash; no hay todavía tests de integración de los flujos de negocio (agendar, cancelar, etc.). Sería el siguiente paso natural antes de sumar más features.
- **Sin pruebas manuales de UI en dispositivo/emulador todavía en esta sesión** — se validó compilación (`analyze`, `build web`, `test`) pero no se ejecutó `flutter run` contra el backend real. Antes de dar por cerrado un flujo (ej. "agendar funciona"), correrlo de punta a punta con el backend levantado.
- **Build de Windows desktop**: la primera vez que se corrió `flutter pub get` en este entorno, Windows avisó que "building with plugins requires symlink support" y pidió activar el Modo de desarrollador (`start ms-settings:developers`). No bloqueó `flutter build web`, pero si se va a correr `-d windows`, hay que activarlo primero.
- **Sigue el patrón de `.claude/skills/flutter-convenciones/SKILL.md`** al agregar pantallas nuevas — la mayoría de los CRUD de negocio/staff son variaciones del mismo patrón (`ListScaffold` + `showAppFormSheet`), copiar la forma existente es más rápido y más consistente que escribir una desde cero.
