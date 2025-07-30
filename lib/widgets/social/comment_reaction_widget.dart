// lib/widgets/social/comment_reaction_widget.dart
import 'package:flutter/material.dart';
import '../../models/social_post.dart';
import '../../models/post_comment.dart' as pc;
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';

class CommentReactionWidget extends StatelessWidget {
  final pc.PostComment comment;
  final String currentUserId;
  final Function(String commentId, ReactionType reaction) onReactionTap;
  final Function(String commentId)? onReactionLongPress;

  const CommentReactionWidget({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.onReactionTap,
    this.onReactionLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final userReaction = comment.getUserReaction(currentUserId);
    final hasReacted = userReaction != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Quick reaction button
        GestureDetector(
          onTap: () {
            if (hasReacted) {
              // Remove reaction by tapping the same type
              onReactionTap(comment.id, userReaction);
            } else {
              // Default to like reaction
              onReactionTap(comment.id, ReactionType.like);
            }
          },
          onLongPress: () {
            onReactionLongPress?.call(comment.id);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasReacted
                  ? _getReactionColor(userReaction).withAlpha(51)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: hasReacted
                  ? Border.all(color: _getReactionColor(userReaction).withAlpha(102))
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasReacted ? _getReactionIcon(userReaction) : Icons.favorite_border,
                  size: 16,
                  color: hasReacted
                      ? _getReactionColor(userReaction)
                      : AppTheme.textColor(context).withAlpha(153),
                ),
                if (comment.totalReactions > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '${comment.totalReactions}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasReacted
                          ? _getReactionColor(userReaction)
                          : AppTheme.textColor(context).withAlpha(153),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Show reaction breakdown if there are multiple reactions
        if (comment.totalReactions > 0 && _hasMultipleReactionTypes())
          _buildReactionBreakdown(context),
      ],
    );
  }

  Widget _buildReactionBreakdown(BuildContext context) {
    final reactionCounts = <ReactionType, int>{};
    
    // Count reactions by type
    for (final reaction in comment.reactions.values) {
      reactionCounts[reaction] = (reactionCounts[reaction] ?? 0) + 1;
    }

    return GestureDetector(
      onTap: () => _showReactionDetails(context, reactionCounts),
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.textColor(context).withAlpha(26),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: reactionCounts.entries.take(3).map((entry) {
            return Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Icon(
                _getReactionIcon(entry.key),
                size: 12,
                color: _getReactionColor(entry.key),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  bool _hasMultipleReactionTypes() {
    final uniqueReactions = comment.reactions.values.toSet();
    return uniqueReactions.length > 1;
  }

  void _showReactionDetails(BuildContext context, Map<ReactionType, int> reactionCounts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(context, 'reactions'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 16),
            ...reactionCounts.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getReactionColor(entry.key).withAlpha(51),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getReactionIcon(entry.key),
                        size: 20,
                        color: _getReactionColor(entry.key),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _getReactionDisplayName(context, entry.key),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${entry.value}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getReactionColor(entry.key),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  IconData _getReactionIcon(ReactionType reaction) {
    switch (reaction) {
      case ReactionType.like:
        return Icons.favorite;
      case ReactionType.celebrate:
        return Icons.celebration;
      case ReactionType.boost:
        return Icons.eco;
      case ReactionType.motivate:
        return Icons.fitness_center;
    }
  }

  Color _getReactionColor(ReactionType reaction) {
    switch (reaction) {
      case ReactionType.like:
        return Colors.red;
      case ReactionType.celebrate:
        return Colors.orange;
      case ReactionType.boost:
        return Colors.green;
      case ReactionType.motivate:
        return Colors.blue;
    }
  }

  String _getReactionDisplayName(BuildContext context, ReactionType reaction) {
    switch (reaction) {
      case ReactionType.like:
        return tr(context, 'like');
      case ReactionType.celebrate:
        return tr(context, 'celebrate');
      case ReactionType.boost:
        return tr(context, 'boost');
      case ReactionType.motivate:
        return tr(context, 'motivate');
    }
  }
}

class ReactionPickerWidget extends StatelessWidget {
  final Function(ReactionType) onReactionSelected;
  final VoidCallback onDismiss;

  const ReactionPickerWidget({
    super.key,
    required this.onReactionSelected,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ReactionType.values.map((reaction) {
          return GestureDetector(
            onTap: () => onReactionSelected(reaction),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getReactionColor(reaction).withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getReactionIcon(reaction),
                size: 24,
                color: _getReactionColor(reaction),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getReactionIcon(ReactionType reaction) {
    switch (reaction) {
      case ReactionType.like:
        return Icons.favorite;
      case ReactionType.celebrate:
        return Icons.celebration;
      case ReactionType.boost:
        return Icons.eco;
      case ReactionType.motivate:
        return Icons.fitness_center;
    }
  }

  Color _getReactionColor(ReactionType reaction) {
    switch (reaction) {
      case ReactionType.like:
        return Colors.red;
      case ReactionType.celebrate:
        return Colors.orange;
      case ReactionType.boost:
        return Colors.green;
      case ReactionType.motivate:
        return Colors.blue;
    }
  }
}