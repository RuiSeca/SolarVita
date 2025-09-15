import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../utils/translation_helper.dart';

class OutroScreen extends StatefulWidget {
  const OutroScreen({super.key});

  @override
  State<OutroScreen> createState() => _OutroScreenState();
}

class _OutroScreenState extends State<OutroScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset('assets/videos/outro_screen.mp4');

      await _controller.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // Start playing the video automatically
        _controller.play();

        // Listen for video completion
        _controller.addListener(_videoListener);
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
      // If video fails, navigate directly to dashboard
      _navigateToDashboard();
    }
  }

  void _videoListener() {
    // Check if video has finished playing
    if (_controller.value.position == _controller.value.duration) {
      _navigateToDashboard();
    }
  }

  void _navigateToDashboard() {
    if (mounted) {
      // Navigate to main app - remove all onboarding routes
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isInitialized
          ? Stack(
              children: [
                // Video player covering the entire screen
                Positioned.fill(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                ),

                // Optional: Add a subtle skip button in case user wants to skip
                Positioned(
                  top: 50,
                  right: 20,
                  child: SafeArea(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _navigateToDashboard,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            tr(context, 'skip_button'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
    );
  }
}