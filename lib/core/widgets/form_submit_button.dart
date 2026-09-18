import 'package:flutter/material.dart';

import 'primary_button.dart';

/// Botón "Guardar" de los formularios en bottom sheet (horarios, turnos,
/// recursos, habilidades, excepciones, fotos, productos...): valida el
/// formulario, muestra su propio spinner mientras `onGuardar` corre, y se
/// re-habilita si falla. Antes cada pantalla repetía este mismo bloque
/// (`bool _guardando` + `setState` + `validate()`) a mano.
class FormSubmitButton extends StatefulWidget {
  final GlobalKey<FormState>? formKey;
  final String label;
  final bool enabled;
  final Future<void> Function() onGuardar;

  const FormSubmitButton({
    super.key,
    this.formKey,
    this.label = 'Guardar',
    this.enabled = true,
    required this.onGuardar,
  });

  @override
  State<FormSubmitButton> createState() => _FormSubmitButtonState();
}

class _FormSubmitButtonState extends State<FormSubmitButton> {
  bool _guardando = false;

  Future<void> _tap() async {
    if (widget.formKey != null && !widget.formKey!.currentState!.validate()) return;
    setState(() => _guardando = true);
    await widget.onGuardar();
    if (mounted) setState(() => _guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: widget.label,
      isLoading: _guardando,
      onPressed: widget.enabled ? _tap : null,
    );
  }
}
