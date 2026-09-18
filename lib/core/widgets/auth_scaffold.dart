import 'package:flutter/material.dart';

/// Cascarón compartido por las pantallas de autenticación (OTP, correo,
/// registro): header con back button, logo pequeño + título, hero con el
/// isotipo, y una "bento card" de superficie elevada para el formulario.
/// Mismo patrón en las 4 pantallas del mockup `design/*_fullpinta`.
class AuthScaffold extends StatelessWidget {
  final String tituloHeader;
  final String? etiquetaSuperior;
  final String titulo;
  final String subtitulo;
  final Widget child;
  final List<Widget>? debajoDeLaCard;

  const AuthScaffold({
    super.key,
    required this.tituloHeader,
    this.etiquetaSuperior,
    required this.titulo,
    required this.subtitulo,
    required this.child,
    this.debajoDeLaCard,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/branding/logo.png', width: 24, height: 24),
            const SizedBox(width: 8),
            Text(tituloHeader),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: scheme.primary.withValues(alpha: 0.12), blurRadius: 24, spreadRadius: 4),
                        ],
                      ),
                      child: Image.asset('assets/branding/logo.png'),
                    ),
                    const SizedBox(height: 16),
                    if (etiquetaSuperior != null) ...[
                      Text(
                        etiquetaSuperior!.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.primary,
                              letterSpacing: 1.2,
                            ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(titulo, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 6),
                    Text(
                      subtitulo,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: child,
              ),
              if (debajoDeLaCard != null) ...[
                const SizedBox(height: 20),
                ...debajoDeLaCard!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila de confianza tipo "Sin contraseñas · Acceso en 1 clic" — reusada en
/// varias pantallas de auth.
class TrustRow extends StatelessWidget {
  final List<(IconData, String)> items;

  const TrustRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 6,
      children: items
          .map((item) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.$1, size: 15, color: scheme.tertiary),
                  const SizedBox(width: 5),
                  Text(item.$2, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ))
          .toList(),
    );
  }
}
