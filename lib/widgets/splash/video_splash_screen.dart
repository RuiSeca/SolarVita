import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../utils/translation_helper.dart';

class VideoSplashScreen extends StatefulWidget {
  final VoidCallback? onVideoEnd;
  final Duration? duration;
  
  const VideoSplashScreen({
    super.key,
    this.onVideoEnd,
    this.duration,
  });

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isVideoInitialized = false;
  bool _hasVideoEnded = false;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset('assets/videos/splash_screen.mp4');

      // Set volume to max to ensure video plays with sound
      _controller.setVolume(1.0);

      await _controller.initialize();

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });

        _fadeController.forward();

        _controller.addListener(() {
          if (_controller.value.position >= _controller.value.duration &&
              !_hasVideoEnded) {
            _hasVideoEnded = true;
            _onVideoCompleted();
          }
        });

        // Play video regardless of device audio mode
        await _controller.play();

        // Remove duration override - let video play to completion
        // Video will end naturally when position >= duration
      }
    } catch (e) {
      debugPrint('Error initializing splash video: $e');
      if (mounted) {
        _onVideoCompleted();
      }
    }
  }

  void _onVideoCompleted() {
    if (mounted) {
      _fadeController.reverse().then((_) {
        if (mounted && widget.onVideoEnd != null) {
          widget.onVideoEnd!();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isVideoInitialized)
            FadeTransition(
              opacity: _fadeAnimation,
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),


          Positioned(
            bottom: 50,
            right: 20,
            child: GestureDetector(
              onTap: _onVideoCompleted,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tr(context, 'skip_button'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}