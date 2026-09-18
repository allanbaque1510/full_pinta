import 'package:flutter/material.dart';

/// Barra de progreso "Paso N de M" del wizard de reserva — mismo patrón en
/// las 3 primeras pantallas del flujo (`design/*_fullpinta`); el paso final
/// (hold/confirmación) no la lleva porque ya no hay "siguiente paso".
class BookingStepIndicator extends StatelessWidget {
  final int paso;
  final int total;
  final String etiqueta;

  const BookingStepIndicator({super.key, required this.paso, required this.total, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: scheme.primary,
                child: Text(
                  '$paso',
                  style: TextStyle(color: scheme.onPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'PASO $paso DE $total',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.primary),
              ),
              const Spacer(),
              Text(
                etiqueta,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(total, (i) {
              final activo = i < paso;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i == total - 1 ? 0 : 4),
                  decoration: BoxDecoration(
                    color: activo ? scheme.primary : scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
