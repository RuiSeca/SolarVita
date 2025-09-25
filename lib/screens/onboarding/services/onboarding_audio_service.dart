import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/audio_preference.dart';

/// Audio service for the ceremonial onboarding experience
/// Manages the ambient soundtrack and sound effects
class OnboardingAudioService with WidgetsBindingObserver {
  static final OnboardingAudioService _instance = OnboardingAudioService._internal();
  factory OnboardingAudioService() => _instance;
  OnboardingAudioService._internal() {
    // Register for app lifecycle changes to handle audio properly
    WidgetsBinding.instance.addObserver(this);
  }

  late AudioPlayer _ambientPlayer;
  late AudioPlayer _chimePlayer;
  late AudioPlayer _swipePlayer;
  late AudioPlayer _continuePlayer;
  late AudioPlayer _buttonPlayer;
  late AudioPlayer _textFieldPlayer;

  bool _isInitialized = false;
  bool _isAmbientPlaying = false;
  bool _isMuted = false;
  bool _isInitializing = false;
  bool _soundEffectsEnabled = true;
  AudioPreference _userPreference = AudioPreference.full;

  // Debouncing for sound effects
  DateTime? _lastSwipeSound;
  DateTime? _lastContinueSound;
  DateTime? _lastButtonSound;
  DateTime? _lastTextFieldSound;

  // Sound effect volumes (relative to ambient)
  static const double _swipeVolume = 0.3;
  static const double _continueVolume = 0.5;
  static const double _buttonVolume = 0.4;
  static const double _textFieldVolume = 0.6;

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
      // Load user audio preference
      await _loadUserPreference();

      debugPrint('🎵 Initializing audio players... (User preference: ${_userPreference.name})');
      _ambientPlayer = AudioPlayer();
      _chimePlayer = AudioPlayer();
      _swipePlayer = AudioPlayer();
      _continuePlayer = AudioPlayer();
      _buttonPlayer = AudioPlayer();
      _textFieldPlayer = AudioPlayer();

      // Listen to player state changes for debugging
      _ambientPlayer.playerStateStream.listen((state) {
        debugPrint('🎵 Player state changed: ${state.playing ? "PLAYING" : "PAUSED"} - ${state.processingState}');
      });

      _ambientPlayer.playbackEventStream.listen((event) {
        debugPrint('🎵 Playback event: ${event.runtimeType}');
      });

      debugPrint('🎵 Loading audio assets...');

      // Load the ethereal ambient track
      await _ambientPlayer.setAsset('assets/audio/ethereal_onboardscreen.mp3');
      await _ambientPlayer.setLoopMode(LoopMode.one);
      debugPrint('🎵 Ambient track loaded');

      // Load sound effects with graceful error handling
      await _loadSoundEffect(_swipePlayer, 'assets/audio/swipe.mp3', 'Swipe sound');
      await _loadSoundEffect(_continuePlayer, 'assets/audio/continue.mp3', 'Continue sound');
      await _loadSoundEffect(_buttonPlayer, 'assets/audio/on-boarding-general-buttons.mp3', 'Button sound');
      await _loadSoundEffect(_textFieldPlayer, 'assets/audio/text-boxes.mp3', 'Text field sound');

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

  /// Load user audio preference
  Future<void> _loadUserPreference() async {
    try {
      _userPreference = await AudioPreferences.getAudioPreference();
      debugPrint('🎵 User audio preference loaded: ${_userPreference.name}');
    } catch (e) {
      debugPrint('🔇 Failed to load user preference, using default: $e');
      _userPreference = AudioPreference.full;
    }
  }

  /// Reload user audio preference and apply changes immediately
  Future<void> reloadUserPreference() async {
    final previousPreference = _userPreference;

    // Load the new preference
    await _loadUserPreference();

    if (previousPreference != _userPreference) {
      debugPrint('🎵 Audio preference changed from ${previousPreference.name} to ${_userPreference.name}');

      // Apply changes based on the new preference
      if (_userPreference == AudioPreference.silent) {
        // Stop ambient audio if it's playing
        if (_isAmbientPlaying) {
          debugPrint('🎵 Stopping ambient audio due to silent preference');
          await fadeOutAmbient(fadeOutDuration: const Duration(milliseconds: 500));
        }
      } else if (previousPreference == AudioPreference.silent &&
                 (_userPreference == AudioPreference.full || _userPreference == AudioPreference.backgroundOnly)) {
        // Start ambient audio if user switched from silent to any audio option
        if (!_isAmbientPlaying && _isInitialized && !_isMuted) {
          debugPrint('🎵 Starting ambient audio due to preference change from silent');
          await startAmbientTrack(fadeInDuration: const Duration(milliseconds: 500));
        }
      }

      debugPrint('🎵 Audio preference update applied successfully');
    } else {
      debugPrint('🎵 Audio preference unchanged: ${_userPreference.name}');
    }
  }

  /// Load a sound effect with error handling
  Future<void> _loadSoundEffect(AudioPlayer player, String assetPath, String name) async {
    try {
      await player.setAsset(assetPath);
      debugPrint('🎵 $name loaded successfully');
    } catch (e) {
      debugPrint('🔇 Failed to load $name: $e');
      // Continue without this specific sound effect
    }
  }

  /// Start the ambient soundtrack with fade-in
  Future<void> startAmbientTrack({Duration fadeInDuration = const Duration(seconds: 3)}) async {
    debugPrint('🎵 🌟 STARTING GLOBAL AMBIENT TRACK - will play continuously throughout onboarding');
    debugPrint('🎵 startAmbientTrack called - initialized: $_isInitialized, playing: $_isAmbientPlaying, muted: $_isMuted, preference: ${_userPreference.name}');

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
    if (_userPreference == AudioPreference.silent) {
      debugPrint('🔇 User prefers silent experience - skipping ambient track');
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

  /// Play swipe sound effect (for PageView navigation)
  Future<void> playSwipeSound() async {
    if (_userPreference != AudioPreference.full) {
      debugPrint('🔇 Swipe sound skipped - user preference: ${_userPreference.name}');
      return;
    }
    debugPrint('🎵 🎯 SWIPE SOUND REQUESTED');
    await _playSoundEffect(
      _swipePlayer,
      _swipeVolume,
      'swipe',
      _lastSwipeSound,
      const Duration(milliseconds: 200),
      (time) => _lastSwipeSound = time,
    );
  }

  /// Play continue sound effect (for navigation buttons)
  Future<void> playContinueSound() async {
    if (_userPreference != AudioPreference.full) {
      debugPrint('🔇 Continue sound skipped - user preference: ${_userPreference.name}');
      return;
    }
    debugPrint('🎵 🎯 CONTINUE SOUND REQUESTED');
    await _playSoundEffect(
      _continuePlayer,
      _continueVolume,
      'continue',
      _lastContinueSound,
      const Duration(milliseconds: 300),
      (time) => _lastContinueSound = time,
    );
  }

  /// Play general button sound effect
  Future<void> playButtonSound() async {
    if (_userPreference != AudioPreference.full) {
      debugPrint('🔇 Button sound skipped - user preference: ${_userPreference.name}');
      return;
    }
    debugPrint('🎵 🎯 BUTTON SOUND REQUESTED');
    await _playSoundEffect(
      _buttonPlayer,
      _buttonVolume,
      'button',
      _lastButtonSound,
      const Duration(milliseconds: 150),
      (time) => _lastButtonSound = time,
    );
  }

  /// Play text field focus sound effect
  Future<void> playTextFieldSound() async {
    if (_userPreference != AudioPreference.full) {
      debugPrint('🔇 Text field sound skipped - user preference: ${_userPreference.name}');
      return;
    }
    debugPrint('🎵 🎯 TEXT FIELD SOUND REQUESTED');
    await _playSoundEffect(
      _textFieldPlayer,
      _textFieldVolume,
      'text field',
      _lastTextFieldSound,
      const Duration(milliseconds: 250),
      (time) => _lastTextFieldSound = time,
    );
  }

  /// Generic method to play sound effects with debouncing
  Future<void> _playSoundEffect(
    AudioPlayer player,
    double volume,
    String soundName,
    DateTime? lastPlayed,
    Duration debounceInterval,
    Function(DateTime) updateLastPlayed,
  ) async {
    if (!_isInitialized || _isMuted || !_soundEffectsEnabled) {
      return;
    }

    // Debouncing: prevent rapid-fire sounds
    final now = DateTime.now();
    if (lastPlayed != null && now.difference(lastPlayed) < debounceInterval) {
      debugPrint('🎵 $soundName sound debounced');
      return;
    }

    try {
      // Reset to beginning and set volume
      await player.seek(Duration.zero);
      await player.setVolume(volume);
      await player.play();
      updateLastPlayed(now);
      debugPrint('🎵 $soundName sound played');
    } catch (e) {
      debugPrint('🔇 Failed to play $soundName sound: $e');
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

  /// Toggle sound effects only (keeps ambient music)
  void toggleSoundEffects() {
    _soundEffectsEnabled = !_soundEffectsEnabled;
    debugPrint('🔇 Sound effects ${_soundEffectsEnabled ? "enabled" : "disabled"}');
  }

  /// Check if audio is currently muted
  bool get isMuted => _isMuted;

  /// Check if ambient track is playing
  bool get isAmbientPlaying => _isAmbientPlaying;

  /// Get current position in the track (for ceremony synchronization)
  Duration get currentPosition => _ambientPlayer.position;

  /// Get total duration of the track
  Duration? get totalDuration => _ambientPlayer.duration;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        debugPrint('🎵 App lifecycle changed to $state - pausing ambient audio');
        _pauseAmbientForLifecycle();
        break;
      case AppLifecycleState.resumed:
        debugPrint('🎵 App resumed - checking if ambient audio should resume');
        // Don't auto-resume - let the app decide if it wants to continue
        break;
    }
  }

  /// Pause ambient audio when app goes to background
  Future<void> _pauseAmbientForLifecycle() async {
    if (_isInitialized && _isAmbientPlaying) {
      try {
        await _ambientPlayer.pause();
        debugPrint('🎵 Ambient audio paused for app lifecycle');
      } catch (e) {
        debugPrint('🔇 Error pausing ambient audio: $e');
      }
    }
  }

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
      // Remove lifecycle observer
      WidgetsBinding.instance.removeObserver(this);

      // Stop and dispose all players
      await _ambientPlayer.stop();
      await _ambientPlayer.dispose();
      await _chimePlayer.dispose();
      await _swipePlayer.dispose();
      await _continuePlayer.dispose();
      await _buttonPlayer.dispose();
      await _textFieldPlayer.dispose();

      _isInitialized = false;
      _isAmbientPlaying = false;
      debugPrint('🎵 Audio service fully disposed with lifecycle observer removed');
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