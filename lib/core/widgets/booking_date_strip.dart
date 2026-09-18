import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final _diaSemanaCorto = DateFormat('EEE', 'es');

/// Selector horizontal de fecha por chips ("Lun 24", "Mar 25"...) — usado en
/// el paso de servicios y en el de horarios del wizard de reserva, siempre
/// acotado a `horizonteDias` del local (no tiene sentido ofrecer una fecha
/// que el local no permite reservar).
class BookingDateStrip extends StatelessWidget {
  final DateTime seleccionada;
  final int diasVisibles;
  final ValueChanged<DateTime> onSeleccionar;

  const BookingDateStrip({
    super.key,
    required this.seleccionada,
    required this.onSeleccionar,
    this.diasVisibles = 14,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hoy = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day);

    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: diasVisibles,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final dia = inicio.add(Duration(days: i));
          final activo = dia.year == seleccionada.year && dia.month == seleccionada.month && dia.day == seleccionada.day;
          final etiqueta = _diaSemanaCorto.format(dia).replaceAll('.', '');
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onSeleccionar(dia),
            child: Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: activo ? scheme.primary : scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    etiqueta[0].toUpperCase() + etiqueta.substring(1),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: activo ? scheme.onPrimary : scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${dia.day}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: activo ? scheme.onPrimary : scheme.onSurface,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
