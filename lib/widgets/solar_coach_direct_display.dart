import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

/// Direct RIV animation display that bypasses all problematic systems
/// Loads animation directly from RIV file without state machines, controllers, or caching
class SolarCoachDirectDisplay extends StatefulWidget {
  final double width;
  final double height;
  final BoxFit fit;
  final String? avatarType; // Optional: specify which avatar to load

  const SolarCoachDirectDisplay({
    super.key,
    this.width = 200,
    this.height = 200,
    this.fit = BoxFit.contain,
    this.avatarType,
  });

  @override
  State<SolarCoachDirectDisplay> createState() => _SolarCoachDirectDisplayState();
}

class _SolarCoachDirectDisplayState extends State<SolarCoachDirectDisplay> {
  rive.Artboard? _artboard;
  rive.SimpleAnimation? _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDirectAnimation();
  }

  Future<void> _loadDirectAnimation() async {
    // Determine which RIV file to load based on avatar type
    final String assetPath;
    final String debugPrefix;
    
    switch (widget.avatarType) {
      case 'mummy_coach':
        assetPath = 'assets/rive/mummy.riv';
        debugPrefix = '🧟 MUMMY DIRECT';
        break;
      case 'quantum_coach':
        assetPath = 'assets/rive/quantum_coach.riv';
        debugPrefix = '🔮 QUANTUM DIRECT';
        break;
      case 'director_coach':
        assetPath = 'assets/rive/director_coach.riv';
        debugPrefix = '🎬 DIRECTOR DIRECT';
        break;
      case 'solar_coach':
      default:
        assetPath = 'assets/rive/solar.riv';
        debugPrefix = '🌞 SOLAR DIRECT';
        break;
    }
    
    try {
      
      debugPrint('$debugPrefix: Loading $assetPath directly without any systems');
      
      // Load RIV file directly
      final rivFile = await rive.RiveFile.asset(assetPath);
      final artboard = rivFile.mainArtboard.instance();
      
      debugPrint('$debugPrefix: RIV loaded successfully');
      debugPrint('$debugPrefix: Available animations: ${artboard.animations.length}');
      
      // List available animations for debugging - using safe iteration
      for (int i = 0; i < artboard.animations.length; i++) {
        try {
          final animation = artboard.animations[i];
          debugPrint('$debugPrefix: Animation [$i]: ${animation.name}');
        } catch (e) {
          debugPrint('$debugPrefix: Error accessing animation at index $i: $e');
          if (e.toString().contains('RangeError')) {
            debugPrint('$debugPrefix: RangeError - breaking animation enumeration');
            break;
          }
        }
      }
      
      // Find a simple animation to play (avoid "State Machine 1")
      rive.SimpleAnimation? controller;
      
      // Animation priority based on avatar type
      if (widget.avatarType == 'mummy_coach') {
        // For mummy_coach, prioritize Idle animation first
        debugPrint('$debugPrefix: Looking for Idle animation for mummy_coach');
        
        for (int i = 0; i < artboard.animations.length; i++) {
          try {
            final animation = artboard.animations[i];
            if (animation.name.toLowerCase() == 'idle') {
              controller = rive.SimpleAnimation(animation.name);
              artboard.addController(controller);
              debugPrint('$debugPrefix: Using Idle animation: ${animation.name}');
              break;
            }
          } catch (e) {
            debugPrint('$debugPrefix: Error accessing animation at index $i: $e');
            break;
          }
        }
      } else if (widget.avatarType == 'solar_coach') {
        // For solar_coach, try multiple animation names based on what we found in analysis
        debugPrint('$debugPrefix: Looking for solar_coach fly animations');
        
        final solarAnimationPriority = ['FIRST FLY', 'SECOND FLY', 'first fly', 'second fly', 'fly', 'Fly'];
        
        for (final animationName in solarAnimationPriority) {
          for (int i = 0; i < artboard.animations.length; i++) {
            try {
              final animation = artboard.animations[i];
              if (animation.name == animationName) {
                controller = rive.SimpleAnimation(animation.name);
                artboard.addController(controller);
                debugPrint('$debugPrefix: Using solar animation: ${animation.name}');
                break;
              }
            } catch (e) {
              debugPrint('$debugPrefix: Error accessing animation at index $i: $e');
              break;
            }
          }
          if (controller != null) break;
        }
      } else if (widget.avatarType == 'director_coach') {
        // For director_coach, prioritize Timeline 1 (idle) then action animations
        debugPrint('$debugPrefix: Looking for director animations');
        
        final directorAnimationPriority = [
          'Idle', // Primary idle animation (same as quantum_coach)
          'walk', 
          'walk 2',
          'jump', 
          'Act_1', 
          'Act_Touch',
          'starAct_Touch',
          'win'
        ];
        
        for (final animationName in directorAnimationPriority) {
          for (int i = 0; i < artboard.animations.length; i++) {
            try {
              final animation = artboard.animations[i];
              if (animation.name == animationName) {
                controller = rive.SimpleAnimation(animation.name);
                artboard.addController(controller);
                debugPrint('$debugPrefix: Using director animation: ${animation.name}');
                break;
              }
            } catch (e) {
              debugPrint('$debugPrefix: Error accessing animation at index $i: $e');
              break;
            }
          }
          if (controller != null) break;
        }
      } else {
        // For other avatars (like quantum_coach), use generic approach
        debugPrint('$debugPrefix: Looking for generic animations');
        for (int i = 0; i < artboard.animations.length; i++) {
          try {
            final animation = artboard.animations[i];
            if (animation.name.toLowerCase().contains('idle') || 
                animation.name.toLowerCase().contains('fly')) {
              controller = rive.SimpleAnimation(animation.name);
              artboard.addController(controller);
              debugPrint('$debugPrefix: Using animation: ${animation.name}');
              break;
            }
          } catch (e) {
            debugPrint('$debugPrefix: Error accessing animation at index $i: $e');
            break;
          }
        }
      }
      
      // Fallback to first non-state-machine animation
      if (controller == null) {
        debugPrint('$debugPrefix: No priority animation found, using fallback');
        for (int i = 0; i < artboard.animations.length; i++) {
          try {
            final animation = artboard.animations[i];
            if (!animation.name.toLowerCase().contains('state machine')) {
              controller = rive.SimpleAnimation(animation.name);
              artboard.addController(controller);
              debugPrint('$debugPrefix: Using fallback animation: ${animation.name}');
              break;
            }
          } catch (e) {
            debugPrint('$debugPrefix: Error accessing fallback animation at index $i: $e');
            break;
          }
        }
      }
      
      setState(() {
        _artboard = artboard;
        _controller = controller;
        _isLoading = false;
        _error = null;
      });
      
      debugPrint('$debugPrefix: Avatar loaded successfully with direct animation');
      
    } catch (e) {
      debugPrint('❌ DIRECT: Error loading $assetPath directly: $e');
      
      // Check if this is a RangeError - if so, provide more specific feedback
      if (e.toString().contains('RangeError')) {
        debugPrint('🔍 DIRECT: RangeError detected in direct loading for ${widget.avatarType}');
        debugPrint('🔍 DIRECT: This indicates the RIV file may still have structural issues');
      }
      
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    // Clean disposal without any complex systems
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoading();
    }
    
    if (_error != null) {
      return _buildError();
    }
    
    if (_artboard == null) {
      return _buildError();
    }
    
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: rive.Rive(
        artboard: _artboard!,
        fit: widget.fit,
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: widget.width * 0.2,
            height: widget.width * 0.2,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Loading ${widget.avatarType?.split('_').map((word) => '${word[0].toUpperCase()}${word.substring(1)}').join(' ') ?? 'Avatar'}...',
            style: TextStyle(
              color: Colors.orange[700] ?? Colors.orange,
              fontSize: widget.width * 0.06,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wb_sunny,
            size: widget.width * 0.4,
            color: Colors.orange[600] ?? Colors.orange,
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.avatarType?.split('_').map((word) => '${word[0].toUpperCase()}${word.substring(1)}').join(' ') ?? 'Avatar'}\n(Simple Mode)',
            style: TextStyle(
              color: Colors.orange[700] ?? Colors.orange,
              fontSize: widget.width * 0.08,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (_error != null) ...[
            const SizedBox(height: 4),
            Text(
              'Error: ${_error!.length > 50 ? '${_error!.substring(0, 50)}...' : _error}',
              style: TextStyle(
                color: Colors.orange[600] ?? Colors.orange,
                fontSize: widget.width * 0.04,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}