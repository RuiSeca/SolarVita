import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/community/community_challenge.dart';
import '../../services/community/community_challenge_service.dart';
import '../../theme/app_theme.dart';
import 'admin_challenge_form_screen.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CommunityChallengeService _challengeService = CommunityChallengeService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        title: Row(
          children: [
            Icon(
              Icons.admin_panel_settings,
              color: theme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Admin Panel',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.textColor(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active', icon: Icon(Icons.play_circle)),
            Tab(text: 'Draft', icon: Icon(Icons.drafts)),
            Tab(text: 'Completed', icon: Icon(Icons.check_circle)),
          ],
          labelColor: theme.primaryColor,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: theme.primaryColor,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChallengesList(ChallengeStatus.active),
          _buildChallengesList(ChallengeStatus.upcoming),
          _buildChallengesList(ChallengeStatus.completed),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewChallenge,
        backgroundColor: theme.primaryColor,
        label: const Text('New Challenge'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildChallengesList(ChallengeStatus status) {
    return StreamBuilder<List<CommunityChallenge>>(
      stream: _getChallengesByStatus(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading challenges',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final challenges = snapshot.data ?? [];

        if (challenges.isEmpty) {
          return _buildEmptyState(status);
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Trigger rebuild
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: challenges.length,
            itemBuilder: (context, index) {
              final challenge = challenges[index];
              return _buildChallengeCard(challenge);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ChallengeStatus status) {
    String message;
    IconData icon;

    switch (status) {
      case ChallengeStatus.active:
        message = 'No active challenges';
        icon = Icons.play_circle_outline;
        break;
      case ChallengeStatus.upcoming:
        message = 'No draft challenges';
        icon = Icons.drafts_outlined;
        break;
      case ChallengeStatus.completed:
        message = 'No completed challenges';
        icon = Icons.check_circle_outline;
        break;
      case ChallengeStatus.cancelled:
        message = 'No cancelled challenges';
        icon = Icons.cancel_outlined;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            message,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Create your first challenge to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(CommunityChallenge challenge) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.cardColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  challenge.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor(context),
                        ),
                      ),
                      Text(
                        challenge.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleChallengeAction(challenge, value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy),
                          SizedBox(width: 8),
                          Text('Duplicate'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: challenge.status == ChallengeStatus.active ? 'deactivate' : 'activate',
                      child: Row(
                        children: [
                          Icon(challenge.status == ChallengeStatus.active
                              ? Icons.pause : Icons.play_arrow),
                          const SizedBox(width: 8),
                          Text(challenge.status == ChallengeStatus.active
                              ? 'Deactivate' : 'Activate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.group,
                  label: _getChallengeTypeLabel(challenge.mode),
                  color: _getChallengeTypeColor(challenge.mode),
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.category,
                  label: _getCategoryLabel(challenge.type),
                  color: _getCategoryColor(challenge.type),
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.people,
                  label: '${challenge.getTotalParticipants()}',
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${_formatDate(challenge.startDate)} - ${_formatDate(challenge.endDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Text(
                  '${challenge.daysRemaining} days left',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: challenge.daysRemaining > 7
                        ? Colors.green
                        : challenge.daysRemaining > 3
                            ? Colors.orange
                            : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<CommunityChallenge>> _getChallengesByStatus(ChallengeStatus status) {
    // For now, return all challenges and filter in the UI
    // In a real implementation, you'd filter at the database level
    return _challengeService.getActiveChallenges().map((challenges) {
      return challenges.where((c) => c.status == status).toList();
    });
  }

  void _createNewChallenge() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminChallengeFormScreen(),
      ),
    );
  }

  void _handleChallengeAction(CommunityChallenge challenge, String action) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminChallengeFormScreen(challenge: challenge),
          ),
        );
        break;
      case 'duplicate':
        _duplicateChallenge(challenge);
        break;
      case 'activate':
      case 'deactivate':
        _toggleChallengeStatus(challenge);
        break;
      case 'delete':
        _deleteChallenge(challenge);
        break;
    }
  }

  void _duplicateChallenge(CommunityChallenge challenge) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminChallengeFormScreen(
          challenge: challenge,
          isDuplicate: true,
        ),
      ),
    );
  }

  Future<void> _toggleChallengeStatus(CommunityChallenge challenge) async {
    try {
      final newStatus = challenge.status == ChallengeStatus.active
          ? ChallengeStatus.upcoming // Changed to "Draft"
          : ChallengeStatus.active;

      // Create updated challenge with new status
      final updatedChallenge = CommunityChallenge(
        id: challenge.id,
        title: challenge.title,
        description: challenge.description,
        type: challenge.type,
        mode: challenge.mode,
        status: newStatus,
        startDate: challenge.startDate,
        endDate: challenge.endDate,
        targetValue: challenge.targetValue,
        unit: challenge.unit,
        icon: challenge.icon,
        participants: challenge.participants,
        leaderboard: challenge.leaderboard,
        prize: challenge.prize,
        teams: challenge.teams,
        teamLeaderboard: challenge.teamLeaderboard,
        maxTeamSize: challenge.maxTeamSize,
        maxTeams: challenge.maxTeams,
      );

      await _challengeService.updateChallenge(challenge.id, updatedChallenge);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == ChallengeStatus.active
                  ? 'Challenge activated successfully!'
                  : 'Challenge moved to drafts',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating challenge: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteChallenge(CommunityChallenge challenge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Challenge'),
        content: Text('Are you sure you want to delete "${challenge.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await _challengeService.deleteChallenge(challenge.id);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Challenge deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting challenge: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _getChallengeTypeLabel(ChallengeMode mode) {
    switch (mode) {
      case ChallengeMode.individual:
        return 'Individual';
      case ChallengeMode.team:
        return 'Team';
      case ChallengeMode.mixed:
        return 'Mixed';
    }
  }

  Color _getChallengeTypeColor(ChallengeMode mode) {
    switch (mode) {
      case ChallengeMode.individual:
        return Colors.blue;
      case ChallengeMode.team:
        return Colors.green;
      case ChallengeMode.mixed:
        return Colors.purple;
    }
  }

  String _getCategoryLabel(ChallengeType type) {
    switch (type) {
      case ChallengeType.fitness:
        return 'Fitness';
      case ChallengeType.nutrition:
        return 'Nutrition';
      case ChallengeType.sustainability:
        return 'Eco';
      case ChallengeType.community:
        return 'Community';
    }
  }

  Color _getCategoryColor(ChallengeType type) {
    switch (type) {
      case ChallengeType.fitness:
        return Colors.orange;
      case ChallengeType.nutrition:
        return Colors.green;
      case ChallengeType.sustainability:
        return Colors.teal;
      case ChallengeType.community:
        return Colors.indigo;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}