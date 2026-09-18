// Prueba de humo end-to-end contra el backend REAL (sin mocks). Corre con:
//   flutter test integration_test/app_test.dart -d chrome --dart-define-from-file=dart_defines.json
//
// Recorre: registro por correo -> crear negocio -> crear local -> horario
// -> servicio -> activar -> profesional -> turno -> habilidad -> volver al
// lado cliente -> buscar -> perfil público -> agendar -> confirmar el hold
// -> ver la cita desde la agenda del negocio -> iniciarla -> completarla.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import 'package:full_pinta/app.dart';
import 'package:full_pinta/features/business/local_admin_screen.dart';

const _nombresDias = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];

Future<void> _shot(IntegrationTestWidgetsFlutterBinding binding, WidgetTester tester, String name) async {
  await tester.pumpAndSettle(const Duration(milliseconds: 200), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 30));
  try {
    await binding.takeScreenshot(name);
  } catch (e) {
    // ignore: avoid_print
    print('screenshot "$name" no soportado acá: $e');
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('flujo completo: registro, negocio, local, agendar y completar', (tester) async {
    final sufijo = DateTime.now().millisecondsSinceEpoch.toString().substring(5);
    final email = 'qa$sufijo@fullpinta.test';
    final telefono = '09${sufijo.padLeft(8, '0').substring(0, 8)}';
    final nombreMarca = 'Barbería QA $sufijo';
    final manana = DateTime.now().add(const Duration(days: 1));
    final diaManana = _nombresDias[manana.weekday % 7];

    await tester.pumpWidget(const ProviderScope(child: FullPintaApp()));
    await _shot(binding, tester, '01_splash');

    // ---- Registro por correo ----
    expect(find.text('Ingresar con celular'), findsOneWidget);
    await tester.tap(find.text('Crear cuenta con correo'));
    await _shot(binding, tester, '02_registro_correo');

    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre completo'), 'QA Tester');
    await tester.enterText(find.widgetWithText(TextFormField, 'Correo'), email);
    await tester.enterText(find.widgetWithText(TextFormField, 'Celular'), telefono);
    await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña'), 'clave12345');
    await tester.tap(find.text('Crear cuenta'));
    await _shot(binding, tester, '03_home_cliente');
    expect(find.text('Locales cerca de ti'), findsOneWidget);

    // ---- Crear negocio ----
    await tester.tap(find.text('Cuenta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear o administrar un negocio'));
    await _shot(binding, tester, '04_negocio_form');

    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre de la marca'), nombreMarca);
    await tester.tap(find.text('Crear negocio'));
    await _shot(binding, tester, '05_negocio_detalle');

    // ---- Crear local ----
    await tester.tap(find.text('Crear local'));
    await _shot(binding, tester, '06_local_form');

    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre (ej. "Sucursal Alborada")'), 'Sucursal QA');
    await tester.enterText(find.widgetWithText(TextFormField, 'Dirección'), 'Av. de Prueba 123');
    await tester.tap(find.text('Crear local'));
    await _shot(binding, tester, '07_local_admin');
    expect(find.text('Sucursal QA'), findsOneWidget);

    final localId = tester.widget<LocalAdminScreen>(find.byType(LocalAdminScreen)).localId;

    // ---- Horario: cubrir el día de mañana completo (9:00-19:00 por defecto) ----
    await tester.tap(find.text('Horarios'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar'));
    await _shot(binding, tester, '08_horario_form');

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(diaManana).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await _shot(binding, tester, '09_horario_creado');
    await tester.pageBack();
    await tester.pumpAndSettle();

    // ---- Servicio desde el catálogo maestro ----
    await tester.tap(find.text('Servicios y precios'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar'));
    await _shot(binding, tester, '10_servicio_form');

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Corte clásico').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Precio'), '8');
    await tester.tap(find.text('Guardar'));
    await _shot(binding, tester, '11_servicio_creado');
    await tester.pageBack();
    await tester.pumpAndSettle();

    // ---- Activar el local ----
    await tester.tap(find.text('Activar'));
    await _shot(binding, tester, '12_local_activo');
    expect(find.text('Activo'), findsOneWidget);

    // ---- Personal: alta de profesional con asignación inicial ----
    await tester.tap(find.text('Personal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar'));
    await _shot(binding, tester, '13_profesional_form');

    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre completo'), 'Kevin QA');
    await tester.tap(find.text('Dar de alta'));
    await _shot(binding, tester, '14_personal_lista');
    expect(find.text('Kevin QA'), findsOneWidget);

    await tester.tap(find.text('Kevin QA'));
    await _shot(binding, tester, '15_profesional_admin');

    // ---- Turno cubriendo mañana (9:00-18:00 por defecto) ----
    await tester.tap(find.text('Turnos en este local'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar'));
    await _shot(binding, tester, '16_turno_form');

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(diaManana).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await _shot(binding, tester, '17_turno_creado');
    await tester.pageBack();
    await tester.pumpAndSettle();

    // ---- Habilidad: que Kevin pueda atender "Corte clásico" ----
    await tester.tap(find.text('Habilidades (qué atiende)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar'));
    await _shot(binding, tester, '18_habilidad_form');

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Corte clásico').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await _shot(binding, tester, '19_habilidad_creada');

    // ---- Volver al home del cliente por ruta (más robusto que contar pops) ----
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/');
    await _shot(binding, tester, '20_de_vuelta_en_home_cliente');

    // ---- Buscar el local recién creado ----
    expect(find.text('Sucursal QA'), findsOneWidget);
    await tester.tap(find.text('Sucursal QA'));
    await _shot(binding, tester, '21_perfil_publico_local');
    expect(find.textContaining('Corte clásico'), findsWidgets);

    // ---- Agendar ----
    await tester.tap(find.text('Agendar'));
    await _shot(binding, tester, '22_seleccion_servicios');

    await tester.tap(find.text('Corte clásico'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ListTile, 'Fecha'));
    await _shot(binding, tester, '23_selector_fecha');
    await tester.tap(find.text('${manana.day}').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver horarios'));
    await _shot(binding, tester, '24_slots');

    expect(find.byType(ActionChip), findsWidgets);
    await tester.tap(find.byType(ActionChip).first);
    await _shot(binding, tester, '25_confirmar_reserva');

    await tester.tap(find.text('Reservar'));
    await _shot(binding, tester, '26_hold');

    final hayConfirmarAhora = find.text('Confirmar ahora').evaluate().isNotEmpty;
    if (hayConfirmarAhora) {
      await tester.tap(find.text('Confirmar ahora'));
      await _shot(binding, tester, '27_cita_confirmada');
    }

    // ---- Gestionar la cita desde la agenda del negocio ----
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/locales/$localId/agenda');
    await _shot(binding, tester, '28_agenda_negocio');

    await tester.tap(find.byType(Card).first);
    await _shot(binding, tester, '29_cita_staff_detalle');

    if (find.text('El cliente llegó').evaluate().isNotEmpty) {
      await tester.tap(find.text('El cliente llegó'));
      await _shot(binding, tester, '30_cita_en_curso');
    }
    if (find.text('Completar').evaluate().isNotEmpty) {
      await tester.tap(find.text('Completar').first); // abre el diálogo de propina
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Completar').last); // confirma en el diálogo
      await _shot(binding, tester, '31_cita_completada');
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
