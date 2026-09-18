import 'package:flutter/material.dart';

/// Selección múltiple por chips, usada por el patrón "reemplazar el
/// conjunto completo" (amenidades del local — `PUT /locales/{id}/amenidades`,
/// api-referencia.md). No agrega/quita uno por uno: junta la selección y el
/// caller manda la lista final entera.
class MultiSelectChips<T> extends StatelessWidget {
  final List<T> opciones;
  final Set<T> seleccionados;
  final String Function(T) etiqueta;
  final ValueChanged<Set<T>> onChanged;

  const MultiSelectChips({
    super.key,
    required this.opciones,
    required this.seleccionados,
    required this.etiqueta,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: opciones.map((opcion) {
        final activo = seleccionados.contains(opcion);
        return FilterChip(
          label: Text(etiqueta(opcion)),
          selected: activo,
          onSelected: (valor) {
            final nuevo = Set<T>.from(seleccionados);
            if (valor) {
              nuevo.add(opcion);
            } else {
              nuevo.remove(opcion);
            }
            onChanged(nuevo);
          },
        );
      }).toList(),
    );
  }
}

/// Igual que [MultiSelectChips], pero las opciones se agrupan bajo un
/// encabezado por categoría (ej. amenidades del local agrupadas por
/// `Amenidad.categoria`). La selección sigue siendo un solo `Set` compartido
/// entre todos los grupos — cada chip delega en el mismo [MultiSelectChips].
class GroupedMultiSelectChips<T> extends StatelessWidget {
  final List<T> opciones;
  final Set<T> seleccionados;
  final String Function(T) etiqueta;
  final String Function(T) categoria;
  final ValueChanged<Set<T>> onChanged;

  const GroupedMultiSelectChips({
    super.key,
    required this.opciones,
    required this.seleccionados,
    required this.etiqueta,
    required this.categoria,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final porCategoria = <String, List<T>>{};
    for (final opcion in opciones) {
      porCategoria.putIfAbsent(categoria(opcion), () => []).add(opcion);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: porCategoria.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.key, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              MultiSelectChips<T>(
                opciones: entry.value,
                seleccionados: seleccionados,
                etiqueta: etiqueta,
                onChanged: onChanged,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
