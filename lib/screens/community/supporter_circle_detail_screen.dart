import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/community/supporter_circle.dart';
import '../../utils/translation_helper.dart';
import '../../theme/app_theme.dart';

class SupporterCircleDetailScreen extends ConsumerStatefulWidget {
  final SupporterCircle circle;

  const SupporterCircleDetailScreen({
    super.key,
    required this.circle,
  });

  @override
  ConsumerState<SupporterCircleDetailScreen> createState() => _SupporterCircleDetailScreenState();
}

class _SupporterCircleDetailScreenState extends ConsumerState<SupporterCircleDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.circle.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circle info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.circle.description,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatChip(
                        icon: Icons.people,
                        label: '${widget.circle.memberCount} ${tr(context, 'members')}',
                        color: theme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        icon: _getCircleTypeIcon(widget.circle.type),
                        label: _getCircleTypeName(widget.circle.type),
                        color: _getCircleTypeColor(widget.circle.type),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Members section
            Text(
              tr(context, 'members'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Members list
            ...widget.circle.members.map((member) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: member.photoURL != null
                        ? NetworkImage(member.photoURL!)
                        : null,
                    child: member.photoURL == null
                        ? Text(member.displayName.isNotEmpty
                            ? member.displayName[0].toUpperCase()
                            : '?')
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.displayName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _getRoleName(member.role),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getRoleColor(member.role),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (member.role == CircleMemberRole.creator)
                    Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 20,
                    ),
                ],
              ),
            )),

            const SizedBox(height: 100), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCircleTypeColor(CircleType type) {
    switch (type) {
      case CircleType.fitness:
        return Colors.orange;
      case CircleType.nutrition:
        return Colors.green;
      case CircleType.sustainability:
        return Colors.teal;
      case CircleType.family:
        return Colors.pink;
      case CircleType.professional:
        return Colors.blue;
      case CircleType.support:
        return Colors.purple;
    }
  }

  IconData _getCircleTypeIcon(CircleType type) {
    switch (type) {
      case CircleType.fitness:
        return Icons.fitness_center;
      case CircleType.nutrition:
        return Icons.restaurant;
      case CircleType.sustainability:
        return Icons.eco;
      case CircleType.family:
        return Icons.family_restroom;
      case CircleType.professional:
        return Icons.work_outline;
      case CircleType.support:
        return Icons.favorite_outline;
    }
  }

  String _getCircleTypeName(CircleType type) {
    switch (type) {
      case CircleType.fitness:
        return tr(context, 'fitness');
      case CircleType.nutrition:
        return tr(context, 'nutrition');
      case CircleType.sustainability:
        return tr(context, 'sustainability');
      case CircleType.family:
        return tr(context, 'family');
      case CircleType.professional:
        return tr(context, 'professional');
      case CircleType.support:
        return tr(context, 'support');
    }
  }

  String _getRoleName(CircleMemberRole role) {
    switch (role) {
      case CircleMemberRole.creator:
        return tr(context, 'creator');
      case CircleMemberRole.mentor:
        return tr(context, 'mentor');
      case CircleMemberRole.mentee:
        return tr(context, 'mentee');
      case CircleMemberRole.member:
        return tr(context, 'member');
    }
  }

  Color _getRoleColor(CircleMemberRole role) {
    switch (role) {
      case CircleMemberRole.creator:
        return Colors.amber;
      case CircleMemberRole.mentor:
        return Colors.blue;
      case CircleMemberRole.mentee:
        return Colors.green;
      case CircleMemberRole.member:
        return Colors.grey;
    }
  }
}