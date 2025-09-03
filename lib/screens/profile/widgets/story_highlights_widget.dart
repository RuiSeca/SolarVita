import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/social/story_highlight.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';
import '../../../providers/riverpod/story_provider.dart';
import 'story_viewer_screen.dart';
import 'story_creation_screen.dart';

class StoryHighlightsWidget extends ConsumerWidget {
  final String userId;
  final bool isOwnProfile;
  final VoidCallback? onAddStoryTap;

  const StoryHighlightsWidget({
    super.key,
    required this.userId,
    required this.isOwnProfile,
    this.onAddStoryTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canViewHighlights = ref.watch(canViewStoryHighlightsProvider(userId));
    final storyHighlights = ref.watch(userStoryHighlightsProvider(userId));

    return canViewHighlights.when(
      loading: () => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: _buildLoadingGrid(),
      ),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (canView) {
        if (!canView && !isOwnProfile) {
          return _buildPrivacyBlockedWidget(context);
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              Row(
                children: [
                  Text(
                    tr(context, 'story_highlights'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  const Spacer(),
                  if (isOwnProfile)
                    TextButton.icon(
                      onPressed: () => _showCreateHighlightDialog(context, ref),
                      icon: Icon(
                        Icons.add_circle_outline,
                        size: 20,
                        color: AppTheme.primaryColor,
                      ),
                      label: Text(
                        tr(context, 'add_highlight'),
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Story Highlights Grid
              storyHighlights.when(
                loading: () => _buildLoadingGrid(),
                error: (error, stackTrace) => _buildErrorWidget(context, error),
                data: (highlights) => _buildHighlightsGrid(context, ref, highlights),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHighlightsGrid(BuildContext context, WidgetRef ref, List<StoryHighlight> highlights) {
    if (highlights.isEmpty) {
      return _buildEmptyState(context, ref);
    }

    // Show highlights in a horizontal scrollable list
    final highlightsToShow = highlights.take(12).toList(); // Limit to 12 for clean UI
    
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: highlightsToShow.length + (isOwnProfile ? 1 : 0),
        itemBuilder: (context, index) {
          // Add "New" button for own profile
          if (isOwnProfile && index == 0) {
            return _buildAddHighlightButton(context, ref);
          }

          final highlightIndex = isOwnProfile ? index - 1 : index;
          final highlight = highlightsToShow[highlightIndex];
          return _buildHighlightCircle(context, ref, highlight, highlightsToShow, highlightIndex);
        },
      ),
    );
  }

  Widget _buildAddHighlightButton(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => _showCreateHighlightDialog(context, ref),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.5),
                  width: 2,
                  style: BorderStyle.solid,
                ),
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.add,
                color: AppTheme.primaryColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tr(context, 'new'),
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textColor(context).withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightCircle(BuildContext context, WidgetRef ref, StoryHighlight highlight, List<StoryHighlight> highlights, int highlightIndex) {
    final category = highlight.category;
    final colors = category.colorGradient;

    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => _openStoryViewer(context, ref, highlights, highlightIndex),
        onLongPress: isOwnProfile 
            ? () => _showHighlightOptions(context, ref, highlight)
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: colors.map((c) => Color(c)).toList(),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(colors.first).withValues(alpha: 0.3),
                    spreadRadius: 0,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surfaceColor(context),
                ),
                child: ClipOval(
                  child: highlight.coverImageUrl.isNotEmpty
                      ? Image.network(
                          highlight.coverImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(category),
                        )
                      : _buildDefaultIcon(category),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 80,
              child: Text(
                highlight.customTitle?.isNotEmpty == true 
                    ? highlight.customTitle!
                    : tr(context, highlight.category.translationKey),
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textColor(context).withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultIcon(StoryHighlightCategory category) {
    final colors = category.colorGradient;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors.map((c) => Color(c).withValues(alpha: 0.2)).toList(),
        ),
      ),
      child: Center(
        child: Icon(
          _getCategoryIcon(category),
          color: Color(colors.first),
          size: 24,
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

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 32,
              color: AppTheme.textColor(context).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              isOwnProfile 
                  ? tr(context, 'no_story_highlights_own')
                  : tr(context, 'no_story_highlights_other'),
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textColor(context).withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (isOwnProfile) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _showCreateHighlightDialog(context, ref),
                child: Text(
                  tr(context, 'create_first_highlight'),
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 60,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, dynamic error) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              tr(context, 'failed_to_load_highlights'),
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyBlockedWidget(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                color: AppTheme.textColor(context).withValues(alpha: 0.5),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                tr(context, 'story_highlights_private'),
                style: TextStyle(
                  color: AppTheme.textColor(context).withValues(alpha: 0.7),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openStoryViewer(BuildContext context, WidgetRef ref, List<StoryHighlight> highlights, int initialIndex) {
    final canViewStories = ref.read(canViewStoriesProvider(userId));
    canViewStories.when(
      loading: () {}, // Show loading or do nothing
      error: (error, stackTrace) {}, // Handle error silently
      data: (canView) {
        if (canView || isOwnProfile) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => StoryViewerScreen(
                highlights: highlights,
                initialHighlightIndex: initialIndex,
                isOwnStory: isOwnProfile,
              ),
              fullscreenDialog: true,
            ),
          );
        }
      },
    );
  }

  void _showCreateHighlightDialog(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const StoryCreationScreen(),
      ),
    );
  }

  void _showHighlightOptions(BuildContext context, WidgetRef ref, StoryHighlight highlight) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            ListTile(
              leading: Icon(Icons.edit, color: AppTheme.primaryColor),
              title: Text(tr(context, 'edit_highlight')),
              onTap: () {
                Navigator.pop(context);
                // Navigate to edit highlight screen
              },
            ),
            
            ListTile(
              leading: Icon(Icons.add_photo_alternate, color: AppTheme.primaryColor),
              title: Text(tr(context, 'add_story')),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => StoryCreationScreen(existingHighlight: highlight),
                  ),
                );
              },
            ),
            
            ListTile(
              leading: Icon(Icons.visibility_off, color: Colors.orange),
              title: Text(tr(context, 'hide_highlight')),
              onTap: () {
                Navigator.pop(context);
                _hideHighlight(ref, highlight);
              },
            ),
            
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text(tr(context, 'delete_highlight')),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteHighlight(context, ref, highlight);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _hideHighlight(WidgetRef ref, StoryHighlight highlight) {
    final storyActions = ref.read(storyActionsProvider);
    storyActions.updateStoryHighlight(
      highlight.id,
      highlight.copyWith(isVisible: false),
    );
  }

  void _confirmDeleteHighlight(BuildContext context, WidgetRef ref, StoryHighlight highlight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text(
          tr(context, 'delete_highlight'),
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
        content: Text(
          tr(context, 'delete_highlight_confirmation'),
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final storyActions = ref.read(storyActionsProvider);
              storyActions.deleteStoryHighlight(highlight.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(tr(context, 'delete')),
          ),
        ],
      ),
    );
  }
}