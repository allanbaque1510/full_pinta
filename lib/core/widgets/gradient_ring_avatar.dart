import 'package:flutter/material.dart';

/// Avatar circular con anillo degradado (marca FullPinta) — usado en el
/// perfil propio y en el perfil público de un profesional.
class GradientRingAvatar extends StatelessWidget {
  final String? url;
  final double radio;
  final IconData iconoFallback;

  const GradientRingAvatar({super.key, this.url, this.radio = 40, this.iconoFallback = Icons.person});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(colors: [scheme.primary, scheme.secondary, scheme.tertiary, scheme.primary]),
      ),
      child: CircleAvatar(
        radius: radio,
        backgroundColor: scheme.surfaceContainerHigh,
        backgroundImage: url != null ? NetworkImage(url!) : null,
        child: url == null ? Icon(iconoFallback, size: radio * 0.9, color: scheme.onSurfaceVariant) : null,
      ),
    );
  }
}
