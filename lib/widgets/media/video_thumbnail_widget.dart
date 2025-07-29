// lib/widgets/media/video_thumbnail_widget.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

class VideoThumbnailWidget extends StatefulWidget {
  final String? videoUrl;
  final File? videoFile;
  final double width;
  final double height;
  final bool showDuration;
  final bool showPlayButton;
  final VoidCallback? onTap;

  const VideoThumbnailWidget({
    super.key,
    this.videoUrl,
    this.videoFile,
    required this.width,
    required this.height,
    this.showDuration = true,
    this.showPlayButton = true,
    this.onTap,
  }) : assert(videoUrl != null || videoFile != null, 'Either videoUrl or videoFile must be provided');

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  Duration _duration = Duration.zero;
  String? _thumbnailPath;
  bool _thumbnailCached = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadThumbnail() async {
    // First try to load cached thumbnail
    final cachedPath = await _getCachedThumbnailPath();
    if (cachedPath != null && await File(cachedPath).exists()) {
      setState(() {
        _thumbnailPath = cachedPath;
        _thumbnailCached = true;
      });
      // Still initialize controller for duration info
      await _initializeControllerForMetadata();
    } else {
      // No cached thumbnail, initialize controller and generate one
      await _initializeController();
    }
  }

  Future<String?> _getCachedThumbnailPath() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final thumbnailDir = Directory('${cacheDir.path}/video_thumbnails');
      if (!await thumbnailDir.exists()) {
        await thumbnailDir.create(recursive: true);
      }

      final videoIdentifier = _getVideoIdentifier();
      final thumbnailPath = '${thumbnailDir.path}/$videoIdentifier.png';
      
      return thumbnailPath;
    } catch (e) {
      debugPrint('Error getting cached thumbnail path: $e');
      return null;
    }
  }

  String _getVideoIdentifier() {
    final source = widget.videoUrl ?? widget.videoFile?.path ?? '';
    final bytes = utf8.encode(source);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  Future<void> _initializeControllerForMetadata() async {
    try {
      if (widget.videoUrl != null) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl!));
      } else if (widget.videoFile != null) {
        _controller = VideoPlayerController.file(widget.videoFile!);
      }

      await _controller!.initialize();
      
      setState(() {
        _isInitialized = true;
        _duration = _controller!.value.duration;
      });
    } catch (e) {
      debugPrint('Error initializing video controller for metadata: $e');
    }
  }

  Future<void> _initializeController() async {
    try {
      if (widget.videoUrl != null) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl!));
      } else if (widget.videoFile != null) {
        _controller = VideoPlayerController.file(widget.videoFile!);
      }

      await _controller!.initialize();
      
      setState(() {
        _isInitialized = true;
        _duration = _controller!.value.duration;
      });

      // Seek to a good frame for thumbnail (25% through the video)
      await _controller!.seekTo(Duration(
        milliseconds: (_duration.inMilliseconds * 0.25).round(),
      ));

      // Generate and cache thumbnail
      await _generateAndCacheThumbnail();
    } catch (e) {
      debugPrint('Error initializing video for thumbnail: $e');
    }
  }

  Future<void> _generateAndCacheThumbnail() async {
    try {
      final cachedPath = await _getCachedThumbnailPath();
      if (cachedPath == null) return;

      // Wait a bit for the seek to complete
      await Future.delayed(const Duration(milliseconds: 500));

      // For now, we'll use a placeholder method since Flutter doesn't have 
      // built-in video frame extraction. In a real app, you'd use a plugin
      // like video_thumbnail or flutter_ffmpeg
      await _savePlaceholderThumbnail(cachedPath);

      setState(() {
        _thumbnailPath = cachedPath;
        _thumbnailCached = true;
      });
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
    }
  }

  Future<void> _savePlaceholderThumbnail(String path) async {
    // This is a placeholder implementation. In a real app, you would:
    // 1. Extract the current frame from the video player
    // 2. Convert it to image bytes
    // 3. Save it to the cache directory
    
    // For now, we'll just create an empty file to indicate cache attempt
    try {
      final file = File(path);
      await file.create(recursive: true);
      // Write a minimal PNG header to create a valid (but empty) PNG file
      final bytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
      ]);
      await file.writeAsBytes(bytes);
    } catch (e) {
      debugPrint('Error saving placeholder thumbnail: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Video thumbnail or placeholder
              if (_thumbnailCached && _thumbnailPath != null)
                _buildCachedThumbnail()
              else if (_isInitialized && _controller != null)
                SizedBox(
                  width: widget.width,
                  height: widget.height,
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),
                )
              else
                _buildPlaceholder(),

              // Dark overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(51),
                      Colors.transparent,
                      Colors.black.withAlpha(128),
                    ],
                  ),
                ),
              ),

              // Play button
              if (widget.showPlayButton)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(128),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                ),

              // Video type indicator
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.withAlpha(204),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.videocam,
                        size: 10,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'VIDEO',
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Duration badge
              if (widget.showDuration && _isInitialized)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(153),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatDuration(_duration),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // Loading indicator
              if (!_isInitialized)
                const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCachedThumbnail() {
    return Image.file(
      File(_thumbnailPath!),
      width: widget.width,
      height: widget.height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // If cached thumbnail is corrupted, fall back to placeholder
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[400]!,
            Colors.grey[600]!,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.movie,
          size: 48,
          color: Colors.white,
        ),
      ),
    );
  }
}