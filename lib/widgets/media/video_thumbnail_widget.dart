// lib/widgets/media/video_thumbnail_widget.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

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
  String? _thumbnailPath; // TODO: Use for local thumbnail caching

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
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
    } catch (e) {
      // TODO: Replace with proper logging
      debugPrint('Error initializing video for thumbnail: $e');
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
              if (_isInitialized && _controller != null)
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