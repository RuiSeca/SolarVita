import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:logging/logging.dart';
import 'lottie_loading_widget.dart';

final log = Logger('ExerciseImage');

class ExerciseImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ExerciseImage({
    super.key,
    required this.imageUrl,
    this.width = 100,
    this.height = 100,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      log.warning('ExerciseImage: Empty imageUrl provided');
      return _buildPlaceholder();
    }

    // Check if the URL is a GIF - GIFs need special handling for animations
    final isGif = imageUrl.toLowerCase().contains('.gif');
    log.info('ExerciseImage: Loading ${isGif ? 'GIF' : 'image'}: $imageUrl');
    
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: isGif 
        ? _buildGifWidget()
        : CachedNetworkImage(
            imageUrl: imageUrl,
            width: width,
            height: height,
            fit: fit,
            placeholder: (context, url) => _buildLoadingIndicator(),
            errorWidget: (context, url, error) {
              log.severe('Error loading image: $url, error: $error');
              return _buildErrorWidget();
            },
          ),
    );
  }
  
  Widget _buildGifWidget() {
    log.info('ExerciseImage: Building GIF widget for URL: $imageUrl');
    return SizedBox(
      width: width,
      height: height,
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            log.info('ExerciseImage: GIF loaded successfully: $imageUrl');
            return child;
          }
          final progress = loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
              : 0.0;
          log.info('ExerciseImage: Loading GIF progress: ${(progress * 100).toStringAsFixed(1)}%');
          return _buildLoadingIndicator();
        },
        errorBuilder: (context, error, stackTrace) {
          log.severe('Error loading GIF: $imageUrl, error: $error, stackTrace: $stackTrace');
          return _buildErrorWidget();
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Icon(
        Icons.fitness_center,
        size: width * 0.5,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: LottieLoadingWidget(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[700],
            size: width * 0.3,
          ),
          const SizedBox(height: 4),
          const Text(
            'Failed to load',
            style: TextStyle(
              fontSize: 10,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
