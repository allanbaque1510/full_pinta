import 'package:flutter/material.dart';

import 'photo_carousel.dart';

/// AppBar compartido por las pantallas del wizard de reserva (§5, §6):
/// logo + título centrado en mayúsculas, avatar del usuario a la derecha.
/// Mismo patrón en las 4 pantallas del mockup `design/*_fullpinta`.
class BookingAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titulo;
  final VoidCallback? onAtras;
  final bool mostrarAtras;
  final String? avatarUrl;

  const BookingAppBar({
    super.key,
    required this.titulo,
    this.onAtras,
    this.mostrarAtras = true,
    this.avatarUrl,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      titleSpacing: 0,
      automaticallyImplyLeading: mostrarAtras && onAtras == null,
      leading: mostrarAtras && onAtras != null ? BackButton(onPressed: onAtras) : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/branding/logo.png', width: 22, height: 22),
          const SizedBox(width: 8),
          Text(
            titulo.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(letterSpacing: 1.1),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: NetworkAvatar(url: avatarUrl, radio: 16),
        ),
      ],
    );
  }
}
