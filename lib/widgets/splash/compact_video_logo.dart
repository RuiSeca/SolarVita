import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CompactVideoLogo extends StatefulWidget {
  final double width;
  final double height;
  final bool autoPlay;
  final bool loop;
  
  const CompactVideoLogo({
    super.key,
    this.width = 120,
    this.height = 120,
    this.autoPlay = true,
    this.loop = true,
  });

  @override
  State<CompactVideoLogo> createState() => _CompactVideoLogoState();
}

class _CompactVideoLogoState extends State<CompactVideoLogo>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isVideoInitialized = false;

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
      
      await _controller.initialize();
      
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        
        _fadeController.forward();
        
        if (widget.loop) {
          _controller.setLooping(true);
        }
        
        if (widget.autoPlay) {
          await _controller.play();
        }
      }
    } catch (e) {
      debugPrint('Error initializing compact video logo: $e');
      // Keep loading state if video fails to load
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
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: _isVideoInitialized
          ? FadeTransition(
              opacity: _fadeAnimation,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
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
          : Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            ),
    );
  }
}