// lib/widgets/media/enhanced_video_player.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class EnhancedVideoPlayer extends StatefulWidget {
  final String? videoUrl;
  final File? videoFile;
  final double? width;
  final double? height;
  final bool autoPlay;
  final bool showControls;
  final bool showDuration;
  final VoidCallback? onVideoTap;

  const EnhancedVideoPlayer({
    super.key,
    this.videoUrl,
    this.videoFile,
    this.width,
    this.height,
    this.autoPlay = false,
    this.showControls = true,
    this.showDuration = true,
    this.onVideoTap,
  }) : assert(videoUrl != null || videoFile != null, 'Either videoUrl or videoFile must be provided');

  @override
  State<EnhancedVideoPlayer> createState() => _EnhancedVideoPlayerState();
}

class _EnhancedVideoPlayerState extends State<EnhancedVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showControls = true;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      if (widget.videoUrl != null) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl!));
      } else if (widget.videoFile != null) {
        _controller = VideoPlayerController.file(widget.videoFile!);
      }

      await _controller!.initialize();
      
      setState(() {
        _isInitialized = true;
        _totalDuration = _controller!.value.duration;
      });

      // Add listener for position updates
      _controller!.addListener(_videoListener);

      if (widget.autoPlay) {
        _playPause();
      }
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  void _videoListener() {
    if (!mounted) return;
    
    setState(() {
      _currentPosition = _controller!.value.position;
      _isPlaying = _controller!.value.isPlaying;
    });
  }

  void _playPause() {
    if (_controller == null) return;

    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
  }

  void _seekTo(Duration position) {
    _controller?.seekTo(position);
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
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
    if (!_isInitialized || _controller == null) {
      return _buildLoadingState();
    }

    return GestureDetector(
      onTap: widget.onVideoTap ?? _toggleControls,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video player
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),

              // Loading overlay
              if (_controller!.value.isBuffering)
                Container(
                  color: Colors.black.withAlpha(128),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                ),

              // Controls overlay
              if (widget.showControls && _showControls)
                _buildControlsOverlay(),

              // Duration badge
              if (widget.showDuration)
                _buildDurationBadge(),

              // Video type indicator
              _buildVideoIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const CircularProgressIndicator(),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(153),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.videocam,
                    size: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Loading...',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withAlpha(77),
            Colors.transparent,
            Colors.black.withAlpha(77),
          ],
        ),
      ),
      child: Column(
        children: [
          // Top controls
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(128),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isPlaying ? 'Playing' : 'Paused',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _showControls = false),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(128),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Center play/pause button
          GestureDetector(
            onTap: _playPause,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(128),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                size: 32,
                color: Colors.white,
              ),
            ),
          ),

          const Spacer(),

          // Bottom controls with progress bar
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                // Progress bar
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withAlpha(77),
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    trackHeight: 2,
                  ),
                  child: Slider(
                    value: _currentPosition.inMilliseconds.toDouble(),
                    min: 0,
                    max: _totalDuration.inMilliseconds.toDouble(),
                    onChanged: (value) {
                      _seekTo(Duration(milliseconds: value.toInt()));
                    },
                  ),
                ),

                // Time indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_currentPosition),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatDuration(_totalDuration),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withAlpha(153),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationBadge() {
    return Positioned(
      bottom: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(153),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _formatDuration(_totalDuration),
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildVideoIndicator() {
    return Positioned(
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
    );
  }
}