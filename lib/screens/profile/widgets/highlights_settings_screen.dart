import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';
import '../../../models/social/story_highlight.dart';
import '../../../providers/riverpod/story_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HighlightsSettingsScreen extends ConsumerStatefulWidget {
  const HighlightsSettingsScreen({super.key});

  @override
  ConsumerState<HighlightsSettingsScreen> createState() => _HighlightsSettingsScreenState();
}

class _HighlightsSettingsScreenState extends ConsumerState<HighlightsSettingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Hidden highlights restoration
  final Set<String> _selectedHiddenHighlights = <String>{};
  
  // Permanent stories selection
  final Set<String> _selectedStories = <String>{};
  String _selectedVisibility = 'public'; // 'public', 'private', 'friends'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(tr(context, 'highlights_settings')),
          backgroundColor: AppTheme.surfaceColor(context),
        ),
        body: Center(
          child: Text(tr(context, 'please_login')),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        title: Text(
          tr(context, 'highlights_settings'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.textColor(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppTheme.textColor(context).withValues(alpha: 0.6),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          tabs: [
            Tab(text: tr(context, 'hidden_highlights')),
            Tab(text: tr(context, 'permanent_stories')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHiddenHighlightsTab(currentUser.uid),
          _buildPermanentStoriesTab(currentUser.uid),
        ],
      ),
    );
  }

  Widget _buildHiddenHighlightsTab(String userId) {
    if (userId.isEmpty) {
      return const Center(child: Text('Invalid user'));
    }
    final hiddenHighlights = ref.watch(hiddenStoryHighlightsProvider(userId));
    
    return hiddenHighlights.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        debugPrint('Error loading hidden highlights: $error');
        debugPrint('Stack trace: $stack');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                tr(context, 'failed_to_load_highlights'),
                style: TextStyle(
                  color: AppTheme.textColor(context).withValues(alpha: 0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(
                  color: Colors.red.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
      data: (highlights) {
        if (highlights.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.visibility_outlined,
                  size: 64,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  tr(context, 'no_hidden_highlights'),
                  style: TextStyle(
                    color: AppTheme.textColor(context).withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, 'restore_hidden_highlights'),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(context, 'select_highlights_to_restore'),
                    style: TextStyle(
                      color: AppTheme.textColor(context).withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: highlights.length,
                itemBuilder: (context, index) {
                  final highlight = highlights[index];
                  final isSelected = _selectedHiddenHighlights.contains(highlight.id);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? AppColors.primary 
                            : Colors.grey.withValues(alpha: 0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: highlight.category.colorGradient.map((c) => Color(c)).toList(),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            _getCategoryIcon(highlight.category),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      title: Text(
                        highlight.customTitle?.isNotEmpty == true 
                            ? highlight.customTitle!
                            : tr(context, highlight.category.translationKey),
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${highlight.storyContentIds.length} ${tr(context, 'stories')}',
                        style: TextStyle(
                          color: AppTheme.textColor(context).withValues(alpha: 0.7),
                        ),
                      ),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedHiddenHighlights.add(highlight.id);
                            } else {
                              _selectedHiddenHighlights.remove(highlight.id);
                            }
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedHiddenHighlights.remove(highlight.id);
                          } else {
                            _selectedHiddenHighlights.add(highlight.id);
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            if (_selectedHiddenHighlights.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _restoreSelectedHighlights,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '${tr(context, 'restore_selected')} (${_selectedHiddenHighlights.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPermanentStoriesTab(String userId) {
    if (userId.isEmpty) {
      return const Center(child: Text('Invalid user'));
    }
    final temporaryStories = ref.watch(temporaryStoriesProvider(userId));
    
    return temporaryStories.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        debugPrint('Error loading temporary stories: $error');
        debugPrint('Stack trace: $stack');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                tr(context, 'failed_to_load_stories'),
                style: TextStyle(
                  color: AppTheme.textColor(context).withValues(alpha: 0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(
                  color: Colors.red.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
      data: (stories) {
        if (stories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 64,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  tr(context, 'no_temporary_stories'),
                  style: TextStyle(
                    color: AppTheme.textColor(context).withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, 'make_stories_permanent'),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(context, 'select_stories_permanent'),
                    style: TextStyle(
                      color: AppTheme.textColor(context).withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr(context, 'permanent_stories_info'),
                    style: TextStyle(
                      color: AppTheme.textColor(context).withValues(alpha: 0.7),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            
            // Visibility Selection
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, 'permanent_story_visibility'),
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildVisibilityOption('public', Icons.public, tr(context, 'public_permanent_stories')),
                  _buildVisibilityOption('friends', Icons.people, tr(context, 'friends_permanent_stories')),
                  _buildVisibilityOption('private', Icons.lock, tr(context, 'private_permanent_stories')),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: stories.length,
                itemBuilder: (context, index) {
                  final story = stories[index];
                  final isSelected = _selectedStories.contains(story.id);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? AppColors.primary 
                            : Colors.grey.withValues(alpha: 0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: _buildStoryThumbnail(story),
                      title: Text(
                        story.text?.isNotEmpty == true 
                            ? story.text!.length > 30 
                                ? '${story.text!.substring(0, 30)}...'
                                : story.text!
                            : tr(context, _getContentTypeLabel(story.contentType)),
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        _formatTimeRemaining(story.createdAt),
                        style: TextStyle(
                          color: AppTheme.textColor(context).withValues(alpha: 0.7),
                        ),
                      ),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedStories.add(story.id);
                            } else {
                              _selectedStories.remove(story.id);
                            }
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedStories.remove(story.id);
                          } else {
                            _selectedStories.add(story.id);
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            if (_selectedStories.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _makeStoriesPermanent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '${tr(context, 'make_permanent')} (${_selectedStories.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildVisibilityOption(String value, IconData icon, String label) {
    final isSelected = _selectedVisibility == value;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedVisibility = value;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.primary.withValues(alpha: 0.1) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected 
                  ? AppColors.primary 
                  : Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedVisibility = value;
                  });
                },
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: isSelected 
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppTheme.textColor(context).withValues(alpha: 0.7),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : AppTheme.textColor(context),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryThumbnail(StoryContent story) {
    switch (story.contentType) {
      case StoryContentType.image:
      case StoryContentType.textWithImage:
        if (story.mediaUrl != null) {
          return Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                story.mediaUrl!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.image,
                    color: Colors.grey.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          );
        }
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.text_fields,
            color: AppColors.primary,
          ),
        );
      case StoryContentType.video:
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 24,
          ),
        );
    }
  }

  String _getContentTypeLabel(StoryContentType type) {
    switch (type) {
      case StoryContentType.image:
        return 'photo';
      case StoryContentType.video:
        return 'video';
      case StoryContentType.textWithImage:
        return 'text';
    }
  }

  String _formatTimeRemaining(DateTime createdAt) {
    final now = DateTime.now();
    final expiryTime = createdAt.add(const Duration(hours: 24));
    final remaining = expiryTime.difference(now);
    
    if (remaining.isNegative) {
      return tr(context, 'expired');
    }
    
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${tr(context, 'remaining')}';
    } else {
      return '${minutes}m ${tr(context, 'remaining')}';
    }
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

  void _restoreSelectedHighlights() async {
    if (_selectedHiddenHighlights.isEmpty) return;
    
    try {
      final storyActions = ref.read(storyActionsProvider);
      
      for (final highlightId in _selectedHiddenHighlights) {
        await storyActions.updateStoryHighlightVisibility(highlightId, true);
      }
      
      if (mounted) {
        setState(() {
          _selectedHiddenHighlights.clear();
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'highlights_restored')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'error_occurred')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _makeStoriesPermanent() async {
    if (_selectedStories.isEmpty) return;
    
    try {
      final storyActions = ref.read(storyActionsProvider);
      
      for (final storyId in _selectedStories) {
        await storyActions.makeStoryPermanent(storyId, _selectedVisibility);
      }
      
      if (mounted) {
        setState(() {
          _selectedStories.clear();
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'stories_made_permanent')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'error_occurred')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}