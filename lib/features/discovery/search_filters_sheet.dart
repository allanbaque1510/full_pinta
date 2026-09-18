import 'package:flutter/material.dart';

import '../../core/widgets/multi_select_chips.dart';
import '../../data/models/catalog_models.dart';

class SearchFilters {
  final String? vertical;
  final double? precioMin;
  final double? precioMax;
  final Set<String> amenidades;
  final bool soloDisponibles;
  final bool abiertoAhora;

  const SearchFilters({
    this.vertical,
    this.precioMin,
    this.precioMax,
    this.amenidades = const {},
    this.soloDisponibles = false,
    this.abiertoAhora = false,
  });

  bool get activos =>
      vertical != null ||
      precioMin != null ||
      precioMax != null ||
      amenidades.isNotEmpty ||
      soloDisponibles ||
      abiertoAhora;

  SearchFilters copyWith({
    String? vertical,
    bool limpiarVertical = false,
    double? precioMin,
    double? precioMax,
    Set<String>? amenidades,
    bool? soloDisponibles,
    bool? abiertoAhora,
  }) =>
      SearchFilters(
        vertical: limpiarVertical ? null : (vertical ?? this.vertical),
        precioMin: precioMin ?? this.precioMin,
        precioMax: precioMax ?? this.precioMax,
        amenidades: amenidades ?? this.amenidades,
        soloDisponibles: soloDisponibles ?? this.soloDisponibles,
        abiertoAhora: abiertoAhora ?? this.abiertoAhora,
      );
}

class SearchFiltersSheet extends StatefulWidget {
  final SearchFilters filtrosIniciales;

  const SearchFiltersSheet({super.key, required this.filtrosIniciales});

  @override
  State<SearchFiltersSheet> createState() => _SearchFiltersSheetState();
}

class _SearchFiltersSheetState extends State<SearchFiltersSheet> {
  late SearchFilters _filtros = widget.filtrosIniciales;
  late final _precioMinCtrl = TextEditingController(text: _filtros.precioMin?.toStringAsFixed(0) ?? '');
  late final _precioMaxCtrl = TextEditingController(text: _filtros.precioMax?.toStringAsFixed(0) ?? '');

  static const amenidadesComunes = ['wifi', 'aire_acondicionado', 'parqueo', 'parqueo_gratis', 'tarjeta'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Text('Vertical', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Todas'),
                    selected: _filtros.vertical == null,
                    onSelected: (_) => setState(() => _filtros = _filtros.copyWith(limpiarVertical: true)),
                  ),
                  ...verticalesDisponibles.where((v) => v != 'mascotas').map(
                        (v) => ChoiceChip(
                          label: Text(etiquetaVertical(v)),
                          selected: _filtros.vertical == v,
                          onSelected: (_) => setState(() => _filtros = _filtros.copyWith(vertical: v)),
                        ),
                      ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Rango de precio', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _precioMinCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Mínimo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _precioMaxCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Máximo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Amenidades', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              MultiSelectChips<String>(
                opciones: amenidadesComunes,
                seleccionados: _filtros.amenidades,
                etiqueta: (a) => a.replaceAll('_', ' '),
                onChanged: (nuevo) => setState(() => _filtros = _filtros.copyWith(amenidades: nuevo)),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Disponible hoy'),
                value: _filtros.soloDisponibles,
                onChanged: (v) => setState(() => _filtros = _filtros.copyWith(soloDisponibles: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Abierto ahora'),
                value: _filtros.abiertoAhora,
                onChanged: (v) => setState(() => _filtros = _filtros.copyWith(abiertoAhora: v)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(const SearchFilters()),
                      child: const Text('Limpiar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final min = double.tryParse(_precioMinCtrl.text);
                        final max = double.tryParse(_precioMaxCtrl.text);
                        Navigator.of(context).pop(_filtros.copyWith(precioMin: min, precioMax: max));
                      },
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
