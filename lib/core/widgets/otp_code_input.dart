import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Entrada de código de 6 dígitos en casillas separadas (mismo patrón que
/// `design/verificar_c_digo_fullpinta`), con auto-avance de foco y soporte
/// de pegado del código completo de una vez.
class OtpCodeInput extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const OtpCodeInput({super.key, required this.onChanged});

  @override
  State<OtpCodeInput> createState() => OtpCodeInputState();
}

class OtpCodeInputState extends State<OtpCodeInput> {
  final _controladores = List.generate(6, (_) => TextEditingController());
  final _focos = List.generate(6, (_) => FocusNode());

  String get _codigo => _controladores.map((c) => c.text).join();

  void limpiar() {
    for (final c in _controladores) {
      c.clear();
    }
    _focos.first.requestFocus();
    widget.onChanged('');
  }

  void _alCambiar(int indice, String valor) {
    if (valor.length > 1) {
      // Pegado del código completo en una sola casilla.
      final digitos = valor.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < _controladores.length; i++) {
        _controladores[i].text = i < digitos.length ? digitos[i] : '';
      }
      final siguiente = digitos.length.clamp(0, 5);
      _focos[siguiente].requestFocus();
    } else if (valor.isNotEmpty && indice < 5) {
      _focos[indice + 1].requestFocus();
    }
    widget.onChanged(_codigo);
  }

  @override
  void dispose() {
    for (final c in _controladores) {
      c.dispose();
    }
    for (final f in _focos) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        if (i == 3) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(width: 10, height: 2, color: scheme.onSurface.withValues(alpha: 0.2)),
          );
        }
        return SizedBox(
          width: 44,
          height: 52,
          child: KeyboardListener(
            focusNode: FocusNode(skipTraversal: true),
            onKeyEvent: (event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.backspace &&
                  _controladores[i].text.isEmpty &&
                  i > 0) {
                _focos[i - 1].requestFocus();
              }
            },
            child: TextField(
              controller: _controladores[i],
              focusNode: _focos[i],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: Theme.of(context).textTheme.headlineSmall,
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: scheme.surfaceContainer,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onChanged: (v) => _alCambiar(i, v),
            ),
          ),
        );
      }),
    );
  }
}
