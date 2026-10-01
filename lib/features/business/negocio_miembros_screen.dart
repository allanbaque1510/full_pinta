import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/form_submit_button.dart';
import '../../core/widgets/list_scaffold.dart';
import '../../data/models/directory_models.dart';
import '../../state/repository_providers.dart';

/// Miembros del negocio (§3.2, §4.4): quién tiene acceso a la app como
/// `admin` o `recepcion`, en todos los locales o en uno. No es lo mismo que
/// contratar un profesional (ficha de trabajo, ver Staffing). Solo
/// propietario/admin del negocio.
class NegocioMiembrosScreen extends ConsumerStatefulWidget {
  final String negocioId;

  const NegocioMiembrosScreen({super.key, required this.negocioId});

  @override
  ConsumerState<NegocioMiembrosScreen> createState() => _NegocioMiembrosScreenState();
}

class _NegocioMiembrosScreenState extends ConsumerState<NegocioMiembrosScreen> {
  AsyncValue<List<NegocioMiembro>> _miembros = const AsyncValue.loading();
  List<Local> _locales = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _miembros = const AsyncValue.loading());
    try {
      final repo = ref.read(directoryRepositoryProvider);
      final lista = await repo.listarMiembros(widget.negocioId);
      try {
        _locales = await repo.listarLocales(widget.negocioId);
      } catch (_) {
        // Solo alimenta el selector de local; el listado sirve igual sin él.
      }
      if (mounted) setState(() => _miembros = AsyncValue.data(lista));
    } catch (e, st) {
      if (mounted) setState(() => _miembros = AsyncValue.error(DioClient.mapearError(e), st));
    }
  }

  Future<void> _agregar() async {
    await showAppFormSheet(
      context,
      title: 'Dar acceso',
      child: _MiembroForm(
        locales: _locales,
        onGuardar: (telefono, rol, localId) async {
          try {
            await ref
                .read(directoryRepositoryProvider)
                .agregarMiembro(widget.negocioId, telefono: telefono, rol: rol, localId: localId);
            if (mounted) Navigator.of(context).pop();
            _cargar();
          } catch (e) {
            final error = DioClient.mapearError(e);
            if (mounted) mostrarError(context, error.errorDe('telefono') ?? error.mensaje);
          }
        },
      ),
    );
  }

  Future<void> _terminar(NegocioMiembro m) async {
    final ok = await confirmarDialogo(
      context,
      titulo: 'Quitar acceso',
      mensaje: '${m.usuarioNombre ?? 'Esta persona'} dejará de tener acceso como ${textoRolMiembro(m.rol).toLowerCase()}. '
          'El registro queda en el historial.',
      textoConfirmar: 'Quitar acceso',
      destructivo: true,
    );
    if (!ok) return;
    try {
      await ref.read(directoryRepositoryProvider).terminarMiembro(m.id);
      _cargar();
    } catch (e) {
      // 422 si es el propietario legal del negocio: el backend lo explica.
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListScaffold<NegocioMiembro>(
      titulo: 'Equipo con acceso',
      items: _miembros,
      onRetry: _cargar,
      onCrear: _agregar,
      mensajeVacio: 'Todavía no hay miembros.',
      iconoVacio: Icons.group_outlined,
      etiquetaContador: 'miembros',
      itemBuilder: (context, m) {
        final vigente = m.vigente;
        return CrudTile(
          icono: m.rol == 'propietario' ? Icons.verified_user_outlined : Icons.badge_outlined,
          colorIcono: vigente ? null : scheme.onSurfaceVariant,
          titulo: '${m.usuarioNombre ?? 'Usuario'} · ${textoRolMiembro(m.rol)}',
          subtitulo: [
            m.localNombre ?? 'Todos los locales',
            if (m.desde != null) 'desde ${m.desde}',
            if (m.hasta != null) 'hasta ${m.hasta}',
          ].join(' · '),
          onEliminar: vigente ? () => _terminar(m) : null,
        );
      },
    );
  }
}

class _MiembroForm extends StatefulWidget {
  final List<Local> locales;
  final Future<void> Function(String telefono, String rol, String? localId) onGuardar;

  const _MiembroForm({required this.locales, required this.onGuardar});

  @override
  State<_MiembroForm> createState() => _MiembroFormState();
}

class _MiembroFormState extends State<_MiembroForm> {
  final _formKey = GlobalKey<FormState>();
  final _telefonoCtrl = TextEditingController();
  String _rol = 'recepcion';
  String? _localId;

  @override
  void dispose() {
    _telefonoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'La persona debe estar registrada en la app. Se busca por el teléfono de su cuenta.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _telefonoCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Teléfono de la cuenta'),
            validator: (v) => AppValidators.requerido(v, 'El teléfono'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _rol,
            decoration: const InputDecoration(labelText: 'Rol'),
            items: const [
              DropdownMenuItem(value: 'recepcion', child: Text('Recepción')),
              DropdownMenuItem(value: 'admin', child: Text('Administrador')),
            ],
            onChanged: (v) => setState(() => _rol = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: _localId,
            decoration: const InputDecoration(labelText: 'Alcance'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Todos los locales')),
              ...widget.locales.map((l) => DropdownMenuItem<String?>(value: l.id, child: Text(l.nombre))),
            ],
            onChanged: (v) => setState(() => _localId = v),
          ),
          const SizedBox(height: 16),
          FormSubmitButton(
            formKey: _formKey,
            label: 'Dar acceso',
            onGuardar: () => widget.onGuardar(_telefonoCtrl.text.trim(), _rol, _localId),
          ),
        ],
      ),
    );
  }
}
