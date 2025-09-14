import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Audio service for the ceremonial onboarding experience
/// Manages the ambient soundtrack and ceremonial chimes
class OnboardingAudioService {
  static final OnboardingAudioService _instance = OnboardingAudioService._internal();
  factory OnboardingAudioService() => _instance;
  OnboardingAudioService._internal();

  late AudioPlayer _ambientPlayer;
  late AudioPlayer _chimePlayer;
  
  bool _isInitialized = false;
  bool _isAmbientPlaying = false;
  bool _isMuted = false;
  bool _isInitializing = false;

  /// Initialize the audio service
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('🎵 Audio service already initialized - continuing with existing session');
      return;
    }

    if (_isInitializing) {
      debugPrint('🎵 Audio service already initializing - waiting...');
      return;
    }

    _isInitializing = true;
    try {
      debugPrint('🎵 Initializing audio players...');
      _ambientPlayer = AudioPlayer();
      _chimePlayer = AudioPlayer();

      // Listen to player state changes for debugging
      _ambientPlayer.playerStateStream.listen((state) {
        debugPrint('🎵 Player state changed: ${state.playing ? "PLAYING" : "PAUSED"} - ${state.processingState}');
      });

      _ambientPlayer.playbackEventStream.listen((event) {
        debugPrint('🎵 Playback event: ${event.runtimeType}');
      });

      debugPrint('🎵 Loading ethereal ambient track...');
      // Load the ethereal ambient track
      await _ambientPlayer.setAsset('assets/audio/ethereal_onboardscreen.mp3');
      debugPrint('🎵 Audio asset loaded successfully');

      // Set looping for ambient track to create continuous atmosphere
      await _ambientPlayer.setLoopMode(LoopMode.one); // Loop the track seamlessly
      debugPrint('🎵 Audio loop mode set to LoopMode.one');

      _isInitialized = true;
      debugPrint('🎵 Onboarding audio service initialized successfully');
    } catch (e) {
      debugPrint('🔇 Audio initialization failed: $e');
      _isInitialized = false;
      // Continue without audio if initialization fails
    } finally {
      _isInitializing = false;
    }
  }

  /// Start the ambient soundtrack with fade-in
  Future<void> startAmbientTrack({Duration fadeInDuration = const Duration(seconds: 3)}) async {
    debugPrint('🎵 🌟 STARTING GLOBAL AMBIENT TRACK - will play continuously throughout onboarding');
    debugPrint('🎵 startAmbientTrack called - initialized: $_isInitialized, playing: $_isAmbientPlaying, muted: $_isMuted');

    if (!_isInitialized) {
      debugPrint('🔇 Audio service not initialized');
      return;
    }
    if (_isAmbientPlaying) {
      debugPrint('🎵 ✅ Audio already playing - continuing existing session');
      return;
    }
    if (_isMuted) {
      debugPrint('🔇 Audio is muted');
      return;
    }

    try {
      debugPrint('🎵 Setting initial volume and starting playback...');
      // Start at very low but audible volume to avoid focus issues
      await _ambientPlayer.setVolume(0.1);
      await _ambientPlayer.play();
      debugPrint('🎵 Playback started successfully');

      // Short delay to ensure playback is stable
      await Future.delayed(const Duration(milliseconds: 500));

      if (_ambientPlayer.playing) {
        debugPrint('🎵 Audio confirmed playing, beginning fade-in...');
        // Fade in gradually
        await _fadeInAmbient(fadeInDuration);
        debugPrint('🎵 Ambient track started with fade-in');
      } else {
        debugPrint('🔇 Audio playback was interrupted, retrying...');
        // Try to restart if it was stopped
        await _ambientPlayer.play();
        await _fadeInAmbient(fadeInDuration);
      }

      _isAmbientPlaying = true;
    } catch (e) {
      debugPrint('🔇 Failed to start ambient track: $e');
    }
  }

  /// Fade in the ambient track
  Future<void> _fadeInAmbient(Duration duration) async {
    if (!_isInitialized) {
      debugPrint('🔇 Cannot fade in - audio not initialized');
      return;
    }

    debugPrint('🎵 Starting fade-in over ${duration.inSeconds} seconds...');

    const int steps = 20;
    const double startVolume = 0.1; // Starting volume
    const double targetVolume = 0.4; // Gentle background level
    final double volumeDifference = targetVolume - startVolume;
    final double volumeStep = volumeDifference / steps;
    final int delayMs = duration.inMilliseconds ~/ steps;

    for (int i = 1; i <= steps; i++) {
      await Future.delayed(Duration(milliseconds: delayMs));
      if (_isInitialized) {
        try {
          final volume = startVolume + (volumeStep * i);
          await _ambientPlayer.setVolume(volume);
          if (i == steps) {
            debugPrint('🎵 Fade-in completed - volume at $volume');
          }
        } catch (e) {
          debugPrint('🔇 Error setting volume during fade-in: $e');
        }
      }
    }
  }

  /// Fade out the ambient track
  Future<void> fadeOutAmbient({Duration fadeOutDuration = const Duration(seconds: 2)}) async {
    if (!_isInitialized || !_isAmbientPlaying) return;
    
    try {
      const int steps = 10;
      final double currentVolume = _ambientPlayer.volume;
      final double volumeStep = currentVolume / steps;
      final int delayMs = fadeOutDuration.inMilliseconds ~/ steps;
      
      for (int i = steps - 1; i >= 0; i--) {
        await Future.delayed(Duration(milliseconds: delayMs));
        if (_isInitialized) {
          await _ambientPlayer.setVolume(volumeStep * i);
        }
      }
      
      await _ambientPlayer.pause();
      _isAmbientPlaying = false;
      debugPrint('🎵 Ambient track faded out');
    } catch (e) {
      debugPrint('🔇 Failed to fade out ambient track: $e');
    }
  }

  /// Play ceremonial chime (for key moments)
  Future<void> playChime(ChimeType type) async {
    if (!_isInitialized || _isMuted) return;
    
    try {
      // Since we don't have separate chime files, we'll create a subtle volume pulse
      // In a full implementation, you'd have separate chime audio files
      await _createChimeEffect(type);
      debugPrint('🔔 Ceremonial chime played: $type');
    } catch (e) {
      debugPrint('🔇 Failed to play chime: $e');
    }
  }

  /// Create a chime effect by briefly modulating the ambient track
  Future<void> _createChimeEffect(ChimeType type) async {
    if (!_isAmbientPlaying) return;
    
    final currentVolume = _ambientPlayer.volume;
    
    switch (type) {
      case ChimeType.progression:
        // Gentle volume swell for screen progression
        await _ambientPlayer.setVolume(currentVolume * 1.3);
        await Future.delayed(const Duration(milliseconds: 300));
        await _ambientPlayer.setVolume(currentVolume);
        break;
        
      case ChimeType.selection:
        // Quick pulse for selections
        await _ambientPlayer.setVolume(currentVolume * 1.2);
        await Future.delayed(const Duration(milliseconds: 150));
        await _ambientPlayer.setVolume(currentVolume);
        break;
        
      case ChimeType.commitment:
        // Dramatic swell for final commitment
        await _ambientPlayer.setVolume(currentVolume * 1.5);
        await Future.delayed(const Duration(milliseconds: 800));
        await _ambientPlayer.setVolume(currentVolume * 0.8);
        await Future.delayed(const Duration(seconds: 1));
        await _ambientPlayer.setVolume(currentVolume);
        break;
    }
  }

  /// Toggle mute state
  void toggleMute() {
    _isMuted = !_isMuted;
    
    if (_isMuted) {
      _ambientPlayer.setVolume(0.0);
    } else {
      _ambientPlayer.setVolume(0.4);
    }
    
    debugPrint('🔇 Audio ${_isMuted ? "muted" : "unmuted"}');
  }

  /// Check if audio is currently muted
  bool get isMuted => _isMuted;

  /// Check if ambient track is playing
  bool get isAmbientPlaying => _isAmbientPlaying;

  /// Get current position in the track (for ceremony synchronization)
  Duration get currentPosition => _ambientPlayer.position;

  /// Get total duration of the track
  Duration? get totalDuration => _ambientPlayer.duration;

  /// Clean up resources
  Future<void> dispose() async {
    if (!_isInitialized) {
      debugPrint('🎵 Audio service not initialized - skipping disposal');
      return;
    }

    // Wait for initialization to complete if it's in progress
    while (_isInitializing) {
      debugPrint('🎵 Waiting for initialization to complete before disposal...');
      await Future.delayed(const Duration(milliseconds: 100));
    }

    try {
      await _ambientPlayer.dispose();
      await _chimePlayer.dispose();
      _isInitialized = false;
      _isAmbientPlaying = false;
      debugPrint('🎵 Audio service disposed');
    } catch (e) {
      debugPrint('🔇 Error disposing audio service: $e');
    }
  }

  /// Create a subtle audio visualization data (for future wave sync)
  Stream<AudioVisualizationData> get visualizationStream {
    // This would return real-time audio analysis data
    // For now, return a simple stream that pulses with the waves
    return Stream.periodic(const Duration(milliseconds: 200), (count) {
      final time = count * 0.1;
      return AudioVisualizationData(
        amplitude: 0.5 + 0.3 * (0.5 + 0.5 * (time.sin() + 0.3 * (time * 2).sin())),
        frequency: 440.0 + 100.0 * time.sin(),
        isPlaying: _isAmbientPlaying,
      );
    });
  }
}

/// Types of ceremonial chimes for different moments
enum ChimeType {
  progression, // Moving to next screen
  selection,   // Selecting an intent
  commitment,  // Final commitment moment
}

/// Audio visualization data for wave synchronization
class AudioVisualizationData {
  final double amplitude;
  final double frequency;
  final bool isPlaying;

  AudioVisualizationData({
    required this.amplitude,
    required this.frequency,
    required this.isPlaying,
  });
}

/// Extension for mathematical functions
extension MathUtils on double {
  double sin() => math.sin(this);
  double cos() => math.cos(this);
}