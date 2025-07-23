import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OrientedImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OrientedImage({
    super.key,
    required this.imageUrl,
    this.fit,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (imageUrl.startsWith('http')) {
      // Network image
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit ?? BoxFit.cover,
        width: width,
        height: height,
        placeholder: (context, url) =>
            placeholder ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        errorWidget: (context, url, error) =>
            errorWidget ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[300],
              child: const Icon(Icons.error),
            ),
        // Force disable caching of problematic WebP orientations
        cacheManager: null,
        // Add headers to request proper orientation
        httpHeaders: const {
          'Accept': 'image/webp,image/jpeg,image/png,*/*;q=0.8',
        },
      );
    } else {
      // Asset image
      imageWidget = Image.asset(
        imageUrl,
        fit: fit ?? BoxFit.cover,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) =>
            errorWidget ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[300],
              child: const Icon(Icons.error),
            ),
      );
    }

    // Wrap with proper orientation handling
    Widget orientedImage = imageWidget;

    // For WebP images, apply orientation fix for tablets
    if (imageUrl.toLowerCase().contains('.webp')) {
      // Detect if we're on a tablet and need to rotate
      final mediaQuery = MediaQuery.of(context);
      final isTablet = mediaQuery.size.shortestSide >= 600; // Standard tablet detection
      
      if (isTablet) {
        // Apply 180-degree rotation for tablets with WebP orientation issues
        orientedImage = Transform.rotate(
          angle: 3.14159, // 180 degrees in radians (π)
          child: imageWidget,
        );
      }
    }

    // Apply border radius if specified
    if (borderRadius != null) {
      orientedImage = ClipRRect(
        borderRadius: borderRadius!,
        child: orientedImage,
      );
    }

    return orientedImage;
  }
}

// Extension to easily replace existing Image widgets
extension ImageUrlExtension on String {
  Widget toOrientedImage({
    BoxFit? fit,
    double? width,
    double? height,
    BorderRadius? borderRadius,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return OrientedImage(
      imageUrl: this,
      fit: fit,
      width: width,
      height: height,
      borderRadius: borderRadius,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
}