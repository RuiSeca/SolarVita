import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../../models/social/story_highlight.dart';
import '../../../utils/translation_helper.dart';
import '../../../providers/riverpod/story_provider.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  final StoryHighlight highlight;
  final bool isOwnStory;

  const StoryViewerScreen({
    super.key,
    required this.highlight,
    this.isOwnStory = false,
  });

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  Timer? _storyTimer;
  VideoPlayerController? _videoController;
  int _currentStoryIndex = 0;
  List<StoryContent> _stories = [];
  bool _isLoading = true;
  bool _isPaused = false;
  DateTime? _viewStartTime;

  static const Duration _storyDuration = Duration(seconds: 5); // Default story duration

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      duration: _storyDuration,
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_progressController);

    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _loadStories();
  }

  @override
  void dispose() {
    _storyTimer?.cancel();
    _progressController.dispose();
    _videoController?.dispose();
    _pageController.dispose();
    
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, 
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  void _loadStories() {
    debugPrint('Loading stories for highlight: ${widget.highlight.id}');
    debugPrint('Story content IDs: ${widget.highlight.storyContentIds}');
    
    if (widget.highlight.storyContentIds.isEmpty) {
      debugPrint('No story content IDs found in highlight');
      if (mounted) {
        setState(() {
          _stories = [];
          _isLoading = false;
        });
      }
      return;
    }
    
    ref.read(storyContentProvider(widget.highlight.storyContentIds).future).then((stories) {
      debugPrint('Loaded ${stories.length} stories from provider');
      for (final story in stories) {
        debugPrint('Story: ${story.id}, type: ${story.contentType}, mediaUrl: ${story.mediaUrl}');
      }
      
      if (mounted) {
        setState(() {
          _stories = stories;
          _isLoading = false;
        });
        if (_stories.isNotEmpty) {
          _startStory();
        } else {
          debugPrint('No valid stories found after loading');
        }
      }
    }).catchError((error) {
      debugPrint('Error loading stories: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _startStory() {
    if (_stories.isEmpty) return;
    
    _viewStartTime = DateTime.now();
    final story = _stories[_currentStoryIndex];

    if (story.contentType == StoryContentType.video && story.mediaUrl != null) {
      _setupVideoPlayer(story.mediaUrl!);
    } else {
      _startProgressTimer();
    }
  }

  void _setupVideoPlayer(String videoUrl) async {
    try {
      _videoController?.dispose();
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoController!.initialize();
      
      if (mounted) {
        setState(() {});
        _videoController!.play();
        _startProgressTimer(duration: _videoController!.value.duration);
      }
    } catch (e) {
      // If video fails, treat as image with default duration
      _startProgressTimer();
    }
  }

  void _startProgressTimer({Duration? duration}) {
    _progressController.reset();
    _progressController.duration = duration ?? _storyDuration;
    _progressController.forward();

    _storyTimer?.cancel();
    _storyTimer = Timer(duration ?? _storyDuration, () {
      _nextStory();
    });
  }

  void _nextStory() {
    if (_currentStoryIndex < _stories.length - 1) {
      _recordCurrentStoryView();
      setState(() {
        _currentStoryIndex++;
      });
      _startStory();
    } else {
      _recordCurrentStoryView();
      _exitViewer();
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      _recordCurrentStoryView();
      setState(() {
        _currentStoryIndex--;
      });
      _startStory();
    } else {
      _exitViewer();
    }
  }

  void _pauseStory() {
    setState(() {
      _isPaused = true;
    });
    _progressController.stop();
    _storyTimer?.cancel();
    _videoController?.pause();
  }

  void _resumeStory() {
    setState(() {
      _isPaused = false;
    });
    _progressController.forward();
    _videoController?.play();
    
    final remainingTime = Duration(
      milliseconds: ((_storyDuration.inMilliseconds) * (1.0 - _progressController.value)).round(),
    );
    
    _storyTimer?.cancel();
    _storyTimer = Timer(remainingTime, () {
      _nextStory();
    });
  }

  void _recordCurrentStoryView() {
    if (_viewStartTime != null && !widget.isOwnStory) {
      final viewDuration = DateTime.now().difference(_viewStartTime!);
      final story = _stories[_currentStoryIndex];
      
      ref.read(storyActionsProvider).recordStoryView(
        storyContentId: story.id,
        storyOwnerId: story.userId,
        viewDuration: viewDuration,
      );
    }
  }

  void _exitViewer() {
    _recordCurrentStoryView();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_stories.isEmpty) {
      return _buildEmptyScreen();
    }

    final currentStory = _stories[_currentStoryIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          final tapPosition = details.globalPosition.dx;
          
          if (tapPosition < screenWidth * 0.3) {
            // Left side tap - previous story
            _previousStory();
          } else if (tapPosition > screenWidth * 0.7) {
            // Right side tap - next story
            _nextStory();
          } else {
            // Center tap - pause/resume
            if (_isPaused) {
              _resumeStory();
            } else {
              _pauseStory();
            }
          }
        },
        child: Stack(
          children: [
            // Story Content
            _buildStoryContent(currentStory),
            
            // Progress Indicators
            _buildProgressIndicators(),
            
            // Story Header
            _buildStoryHeader(),
            
            // Pause Overlay
            if (_isPaused) _buildPauseOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent(StoryContent story) {
    switch (story.contentType) {
      case StoryContentType.image:
        return _buildImageContent(story);
      case StoryContentType.video:
        return _buildVideoContent(story);
      case StoryContentType.textWithImage:
        return _buildTextWithImageContent(story);
    }
  }

  Widget _buildImageContent(StoryContent story) {
    return Center(
      child: story.mediaUrl != null
          ? Image.network(
              story.mediaUrl!,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: Colors.white,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorContent();
              },
            )
          : _buildTextOnlyContent(story),
    );
  }

  Widget _buildVideoContent(StoryContent story) {
    if (_videoController != null && _videoController!.value.isInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
      );
    } else {
      return Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
  }

  Widget _buildTextWithImageContent(StoryContent story) {
    return Stack(
      children: [
        if (story.mediaUrl != null)
          Positioned.fill(
            child: Image.network(
              story.mediaUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[900],
              ),
            ),
          ),
        // Dark overlay for text readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
        ),
        // Text content
        if (story.text != null)
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Text(
              story.text!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 3,
                    color: Colors.black54,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildTextOnlyContent(StoryContent story) {
    final category = widget.highlight.category;
    final colors = category.colorGradient;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors.map((c) => Color(c)).toList(),
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            story.text ?? widget.highlight.displayTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorContent() {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              tr(context, 'failed_to_load_story'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicators() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 8,
      right: 8,
      child: Row(
        children: List.generate(_stories.length, (index) {
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: LinearProgressIndicator(
                value: index < _currentStoryIndex
                    ? 1.0
                    : index == _currentStoryIndex
                        ? _progressAnimation.value
                        : 0.0,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStoryHeader() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 16,
      right: 16,
      child: Row(
        children: [
          // Profile info
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getCategoryIcon(widget.highlight.category),
              color: Color(widget.highlight.category.colorGradient.first),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.highlight.displayTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_currentStoryIndex + 1} of ${_stories.length}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Close button
          IconButton(
            onPressed: _exitViewer,
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPauseOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              color: Colors.white.withValues(alpha: 0.5),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              tr(context, 'no_stories_in_highlight'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(StoryHighlightCategory category) {
    switch (category) {
      case StoryHighlightCategory.workouts:
        return Icons.fitness_center;
      case StoryHighlightCategory.progress:
        return Icons.trending_up;
      case StoryHighlightCategory.challenges:
        return Icons.emoji_events;
      case StoryHighlightCategory.recovery:
        return Icons.spa;
      case StoryHighlightCategory.meals:
        return Icons.restaurant;
      case StoryHighlightCategory.cooking:
        return Icons.kitchen;
      case StoryHighlightCategory.hydration:
        return Icons.local_drink;
      case StoryHighlightCategory.ecoActions:
        return Icons.eco;
      case StoryHighlightCategory.nature:
        return Icons.nature;
      case StoryHighlightCategory.greenLiving:
        return Icons.park;
      case StoryHighlightCategory.dailyLife:
        return Icons.today;
      case StoryHighlightCategory.travel:
        return Icons.flight;
      case StoryHighlightCategory.community:
        return Icons.people;
      case StoryHighlightCategory.motivation:
        return Icons.psychology;
      case StoryHighlightCategory.custom:
        return Icons.star;
    }
  }
}