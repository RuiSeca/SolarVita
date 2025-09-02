import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/social/story_highlight.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';
import '../../../providers/riverpod/story_provider.dart';
import 'story_viewer_screen.dart';
import 'story_creation_screen.dart';

class ModernAchievementsSection extends ConsumerWidget {
  const ModernAchievementsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = FirebaseAuth.instance.currentUser;
    debugPrint('Current user in ModernAchievementsSection: ${currentUser?.uid}');
    
    if (currentUser == null) {
      debugPrint('No current user, returning empty widget');
      return const SizedBox.shrink();
    }

    debugPrint('Watching story highlights for user: ${currentUser.uid}');
    final storyHighlights = ref.watch(userStoryHighlightsProvider(currentUser.uid));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr(context, 'story_highlights'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showCreateHighlightDialog(context, ref),
                icon: Icon(
                  Icons.add_circle_outline,
                  size: 16,
                  color: AppColors.primary,
                ),
                label: Text(
                  tr(context, 'add_highlight'),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: storyHighlights.when(
              loading: () => _buildLoadingHighlights(),
              error: (error, stackTrace) {
                debugPrint('Story highlights error in widget: $error');
                // For now, show empty state instead of error to keep UI working
                return _buildHighlightsRow(context, ref, []);
              },
              data: (highlights) {
                debugPrint('Story highlights data received: ${highlights.length} items');
                return _buildHighlightsRow(context, ref, highlights);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsRow(BuildContext context, WidgetRef ref, List<StoryHighlight> highlights) {
    if (highlights.isEmpty) {
      return _buildEmptyState(context);
    }

    // Show highlights in a horizontal scrollable list
    final highlightsToShow = highlights.take(12).toList(); // Limit to 12 for clean UI
    
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: highlightsToShow.length + 1, // +1 for "Add New" button
      itemBuilder: (context, index) {
        // Add "New" button as first item
        if (index == 0) {
          return _buildAddHighlightButton(context, ref);
        }

        final highlight = highlightsToShow[index - 1];
        return _buildStoryHighlight(
          context,
          ref,
          highlight,
        );
      },
    );
  }

  Widget _buildAddHighlightButton(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => _showCreateHighlightDialog(context, ref),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  width: 2,
                  style: BorderStyle.solid,
                ),
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.add,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr(context, 'new'),
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textColor(context).withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryHighlight(
    BuildContext context,
    WidgetRef ref,
    StoryHighlight highlight,
  ) {
    final category = highlight.category;
    final colors = category.colorGradient;
    final hasNew = highlight.storyContentIds.isNotEmpty; // Has stories

    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => _openStoryViewer(context, ref, highlight),
        onLongPress: () => _showHighlightOptions(context, ref, highlight),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasNew
                        ? LinearGradient(
                            colors: colors.map((c) => Color(c)).toList(),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: hasNew ? null : Colors.grey.withValues(alpha: 0.3),
                    boxShadow: [
                      BoxShadow(
                        color: Color(colors.first).withValues(alpha: 0.3),
                        spreadRadius: 0,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(hasNew ? 3 : 0),
                  child: Container(
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
                if (hasNew)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.surfaceColor(context),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 80,
              child: Text(
                highlight.displayTitle,
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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
          size: 28,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
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
            tr(context, 'no_story_highlights_own'),
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textColor(context).withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingHighlights() {
    return ListView.builder(
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
              const SizedBox(height: 8),
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

  void _openStoryViewer(BuildContext context, WidgetRef ref, StoryHighlight highlight) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StoryViewerScreen(
          highlight: highlight,
          isOwnStory: true,
        ),
        fullscreenDialog: true,
      ),
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
              leading: Icon(Icons.edit, color: AppColors.primary),
              title: Text(tr(context, 'edit_highlight')),
              onTap: () {
                Navigator.pop(context);
                // Navigate to edit highlight screen
              },
            ),
            
            ListTile(
              leading: Icon(Icons.add_photo_alternate, color: AppColors.primary),
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