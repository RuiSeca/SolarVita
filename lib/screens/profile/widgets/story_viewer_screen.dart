import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../../models/social/story_highlight.dart';
import '../../../utils/translation_helper.dart';
import '../../../providers/riverpod/story_provider.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  final List<StoryHighlight> highlights;
  final int initialHighlightIndex;
  final bool isOwnStory;

  const StoryViewerScreen({
    super.key,
    required this.highlights,
    this.initialHighlightIndex = 0,
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
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  Timer? _storyTimer;
  VideoPlayerController? _videoController;
  int _currentHighlightIndex = 0;
  int _currentStoryIndex = 0;
  List<StoryContent> _stories = [];
  bool _isLoading = true;
  bool _isPaused = false;
  DateTime? _viewStartTime;

  static const Duration _storyDuration = Duration(seconds: 5); // Default story duration

  @override
  void initState() {
    super.initState();
    _currentHighlightIndex = widget.initialHighlightIndex;
    _pageController = PageController();
    _progressController = AnimationController(
      duration: _storyDuration,
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_progressController);
    
    // Don't add a general listener as it can cause infinite rebuilds
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));

    // Don't change system UI to prevent screen shake
    _loadStories();
  }

  @override
  void dispose() {
    _storyTimer?.cancel();
    _progressController.dispose();
    _slideController.dispose();
    _videoController?.dispose();
    _pageController.dispose();
    
    // No system UI changes needed
    super.dispose();
  }

  void _loadStories() {
    final currentHighlight = widget.highlights[_currentHighlightIndex];
    debugPrint('Loading stories for highlight: ${currentHighlight.id}');
    debugPrint('Story content IDs: ${currentHighlight.storyContentIds}');
    
    if (currentHighlight.storyContentIds.isEmpty) {
      debugPrint('No story content IDs found in highlight');
      if (mounted) {
        setState(() {
          _stories = [];
          _isLoading = false;
        });
      }
      return;
    }
    
    ref.read(storyContentProvider(currentHighlight.storyContentIds).future).then((stories) {
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
      
      // Slide animation from right to left
      _slideAnimation = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeInOut,
      ));
      
      setState(() {
        _currentStoryIndex++;
      });
      
      _slideController.reset();
      _slideController.forward();
      _startStory();
    } else {
      _nextHighlight();
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      _recordCurrentStoryView();
      
      // Slide animation from left to right
      _slideAnimation = Tween<Offset>(
        begin: const Offset(-1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeInOut,
      ));
      
      setState(() {
        _currentStoryIndex--;
      });
      
      _slideController.reset();
      _slideController.forward();
      _startStory();
    } else {
      _previousHighlight();
    }
  }

  void _previousHighlight() {
    if (_currentHighlightIndex > 0) {
      _recordCurrentStoryView();
      
      setState(() {
        _currentHighlightIndex--;
        _currentStoryIndex = 0; // Reset to first story of the highlight
        _isLoading = true;
      });
      
      _stopCurrentStory();
      _loadStories(); // Load stories for the new highlight
    } else {
      _exitViewer();
    }
  }

  void _nextHighlight() {
    if (_currentHighlightIndex < widget.highlights.length - 1) {
      _recordCurrentStoryView();
      
      setState(() {
        _currentHighlightIndex++;
        _currentStoryIndex = 0; // Reset to first story of the highlight
        _isLoading = true;
      });
      
      _stopCurrentStory();
      _loadStories(); // Load stories for the new highlight
    } else {
      _exitViewer();
    }
  }

  void _stopCurrentStory() {
    _progressController.stop();
    _progressController.reset();
    _storyTimer?.cancel();
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
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
    
    // Use the current progress controller's duration, not the default
    final currentDuration = _progressController.duration ?? _storyDuration;
    final remainingTime = Duration(
      milliseconds: ((currentDuration.inMilliseconds) * (1.0 - _progressController.value)).round(),
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

  void _jumpToStory(int targetIndex) {
    if (targetIndex < 0 || targetIndex >= _stories.length || targetIndex == _currentStoryIndex) {
      return;
    }

    _recordCurrentStoryView();
    
    // Determine slide direction based on target
    final isForward = targetIndex > _currentStoryIndex;
    _slideAnimation = Tween<Offset>(
      begin: isForward ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
    
    setState(() {
      _currentStoryIndex = targetIndex;
    });
    
    _slideController.reset();
    _slideController.forward();
    _startStory();
  }

  void _showStoryPreview(int index) {
    if (index < 0 || index >= _stories.length) return;
    
    final story = _stories[index];
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () {
            Navigator.pop(context);
            _jumpToStory(index);
          },
          child: Container(
            width: 200,
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildStoryPreviewContent(story),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoryPreviewContent(StoryContent story) {
    switch (story.contentType) {
      case StoryContentType.image:
      case StoryContentType.textWithImage:
        if (story.mediaUrl != null) {
          return Image.network(
            story.mediaUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[800],
              child: Icon(Icons.error, color: Colors.white),
            ),
          );
        }
        return _buildTextPreview(story);
      case StoryContentType.video:
        return Stack(
          children: [
            if (story.mediaUrl != null)
              Image.network(
                story.mediaUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[800],
                  child: Icon(Icons.error, color: Colors.white),
                ),
              ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.play_arrow, color: Colors.white, size: 24),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildTextPreview(StoryContent story) {
    final category = widget.highlights[_currentHighlightIndex].category;
    final colors = category.colorGradient;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors.map((c) => Color(c)).toList(),
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            story.text ?? (widget.highlights[_currentHighlightIndex].customTitle?.isNotEmpty == true 
                ? widget.highlights[_currentHighlightIndex].customTitle!
                : tr(context, widget.highlights[_currentHighlightIndex].category.translationKey)),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_stories.isEmpty) {
      return _buildEmptyScreen();
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _recordCurrentStoryView();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
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
          onPanStart: (details) {
            // Pause story during pan
            if (!_isPaused) {
              _pauseStory();
            }
          },
          onPanUpdate: (details) {
            // Visual feedback during swipe (optional)
          },
          onPanEnd: (details) {
            final velocity = details.velocity.pixelsPerSecond.dx;
            
            // Resume if no significant swipe
            if (velocity.abs() < 500) {
              if (_isPaused) {
                _resumeStory();
              }
              return;
            }
            
            // Handle horizontal swipes for highlight navigation (fast swipes)
            if (velocity.abs() > 800) {
              if (velocity > 0) {
                // Fast swipe right - previous highlight
                _previousHighlight();
              } else {
                // Fast swipe left - next highlight
                _nextHighlight();
              }
            } else {
              // Medium swipes for story navigation
              if (velocity > 0) {
                // Swipe right - previous story
                _previousStory();
              } else {
                // Swipe left - next story
                _nextStory();
              }
            }
          },
          child: Stack(
            children: [
              // Story Content with slide animation
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: _slideAnimation.value,
                    child: _buildStoryContent(_stories[_currentStoryIndex]),
                  );
                },
              ),
              
              // Progress Indicators
              _buildProgressIndicators(),
              
              // Pause Overlay
              if (_isPaused) _buildPauseOverlay(),
            ],
          ),
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
    final category = widget.highlights[_currentHighlightIndex].category;
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
            story.text ?? (widget.highlights[_currentHighlightIndex].customTitle?.isNotEmpty == true 
                ? widget.highlights[_currentHighlightIndex].customTitle!
                : tr(context, widget.highlights[_currentHighlightIndex].category.translationKey)),
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
    // Cache the current highlight to avoid rebuilds
    if (widget.highlights.isEmpty || _currentHighlightIndex >= widget.highlights.length) {
      return const SizedBox.shrink();
    }
    
    final currentHighlight = widget.highlights[_currentHighlightIndex];
    
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 8,
      right: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with highlight category and navigation dots
          Row(
            children: [
              // Back button
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                iconSize: 24,
              ),
              // Category title
              Expanded(
                child: Text(
                  currentHighlight.displayTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  key: ValueKey('${currentHighlight.id}_$_currentHighlightIndex'), // Add key to prevent unnecessary rebuilds
                ),
              ),
              // Highlight counter
              if (widget.highlights.length > 1) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentHighlightIndex + 1}/${widget.highlights.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Story progress indicators
          Row(
            children: List.generate(_stories.length, (index) {
          final isActive = index == _currentStoryIndex;
          final isCompleted = index < _currentStoryIndex;
          
          return Expanded(
            child: GestureDetector(
              onTap: () => _jumpToStory(index),
              onLongPress: () => _showStoryPreview(index),
              child: Container(
                height: 12, // Larger touch target
                padding: const EdgeInsets.symmetric(vertical: 4),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: isActive ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ] : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return LinearProgressIndicator(
                          value: isCompleted
                              ? 1.0
                              : isActive
                                  ? _progressAnimation.value
                                  : 0.0,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isActive 
                              ? Colors.white 
                              : Colors.white.withValues(alpha: 0.8)
                          ),
                          minHeight: 4,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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

}