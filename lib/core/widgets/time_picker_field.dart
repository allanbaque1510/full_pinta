import 'package:flutter/material.dart';

/// Campo de hora con la misma apariencia que un `TextFormField` — abre el
/// selector de hora nativo al tocarlo. Usado en horarios y turnos (siempre
/// en pareja: abre/cierra, entra/sale).
class TimePickerField extends StatelessWidget {
  final String label;
  final TimeOfDay valor;
  final ValueChanged<TimeOfDay> onChanged;

  const TimePickerField({super.key, required this.label, required this.valor, required this.onChanged});

  static String formatear(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final t = await showTimePicker(context: context, initialTime: valor);
        if (t != null) onChanged(t);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.access_time, size: 20)),
        child: Text(formatear(valor)),
      ),
    );
  }
}
