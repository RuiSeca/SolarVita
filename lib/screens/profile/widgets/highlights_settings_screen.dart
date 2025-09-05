import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
            Tab(text: tr(context, 'all_highlights_stories')),
            Tab(text: tr(context, 'hidden_highlights')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllHighlightsTab(currentUser.uid),
          _buildHiddenHighlightsTab(currentUser.uid),
        ],
      ),
    );
  }

  Widget _buildAllHighlightsTab(String userId) {
    if (userId.isEmpty) {
      return const Center(child: Text('Invalid user'));
    }
    
    final allHighlights = ref.watch(userStoryHighlightsProvider(userId));
    
    return allHighlights.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        debugPrint('Error loading highlights: $error');
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
                  Icons.photo_library_outlined,
                  size: 64,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  tr(context, 'no_story_highlights_own'),
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
                    tr(context, 'manage_story_permanence'),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(context, 'toggle_story_permanent_status'),
                    style: TextStyle(
                      color: AppTheme.textColor(context).withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        tr(context, 'checked_permanent'),
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.schedule, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        tr(context, 'unchecked_expires_24h'),
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
                  return _buildHighlightExpansionTile(highlight);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHighlightExpansionTile(StoryHighlight highlight) {
    final storyContents = ref.watch(storyContentProvider(highlight.storyContentIds));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: highlight.category.colorGradient.map((c) => Color(c)).toList(),
              ),
            ),
            child: highlight.coverImageUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      highlight.coverImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(
                          _getCategoryIcon(highlight.category),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  )
                : Center(
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
              fontSize: 16,
            ),
          ),
          subtitle: storyContents.when(
            loading: () => Text(
              tr(context, 'loading_stories'),
              style: TextStyle(
                color: AppTheme.textColor(context).withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            error: (error, stack) => Text(
              tr(context, 'error_loading_stories'),
              style: TextStyle(
                color: Colors.red.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            data: (stories) {
              final permanentCount = stories.where((s) => s.isPermanent).length;
              final temporaryCount = stories.length - permanentCount;
              
              return Text(
                '${stories.length} ${tr(context, 'stories')} • '
                '$permanentCount ${tr(context, 'permanent')} • '
                '$temporaryCount ${tr(context, 'temporary')}',
                style: TextStyle(
                  color: AppTheme.textColor(context).withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              );
            },
          ),
          children: [
            storyContents.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  tr(context, 'error_loading_stories'),
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
              data: (stories) {
                if (stories.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      tr(context, 'no_stories_in_highlight'),
                      style: TextStyle(
                        color: AppTheme.textColor(context).withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                
                return Column(
                  children: stories.map((story) => _buildStoryTile(story)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryTile(StoryContent story) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: story.isPermanent 
            ? Colors.green.withValues(alpha: 0.05)
            : Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: story.isPermanent 
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.orange.withValues(alpha: 0.2),
          width: 1,
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
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          story.isPermanent 
              ? '${tr(context, 'permanent')} • ${_formatDate(story.createdAt)}'
              : '${tr(context, 'expires')} ${_formatTimeRemaining(story.createdAt)}',
          style: TextStyle(
            color: story.isPermanent ? Colors.green : Colors.orange,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Checkbox(
          value: story.isPermanent,
          onChanged: (value) => _toggleStoryPermanence(story, value ?? false),
          activeColor: Colors.green,
          checkColor: Colors.white,
        ),
        dense: true,
      ),
    );
  }

  void _toggleStoryPermanence(StoryContent story, bool makePermanent) async {
    try {
      final storyActions = ref.read(storyActionsProvider);
      
      if (makePermanent) {
        await storyActions.makeStoryPermanent(story.id, 'public');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr(context, 'story_made_permanent')),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Make temporary by updating the expiration date
        await _makeStoryTemporary(story.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr(context, 'story_made_temporary')),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'error_updating_story')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _makeStoryTemporary(String storyId) async {
    // Update story to be temporary with 24-hour expiration
    final firestore = FirebaseFirestore.instance;
    
    await firestore
        .collection('story_content')
        .doc(storyId)
        .update({
      'isPermanent': false,
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
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
}