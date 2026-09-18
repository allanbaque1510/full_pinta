import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Carrusel horizontal simple para fotos de local/profesional.
class PhotoCarousel extends StatelessWidget {
  final List<String> urls;
  final double height;

  const PhotoCarousel({super.key, required this.urls, this.height = 220});

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return Container(
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(
          Icons.storefront_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    return SizedBox(
      height: height,
      child: PageView.builder(
        itemCount: urls.length,
        itemBuilder: (context, index) => CachedNetworkImage(
          imageUrl: urls[index],
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }
}

class NetworkAvatar extends StatelessWidget {
  final String? url;
  final double radio;
  final IconData iconoFallback;

  const NetworkAvatar({super.key, this.url, this.radio = 24, this.iconoFallback = Icons.person});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return CircleAvatar(radius: radio, child: Icon(iconoFallback));
    }
    return CircleAvatar(
      radius: radio,
      backgroundImage: CachedNetworkImageProvider(url!),
    );
  }
}
