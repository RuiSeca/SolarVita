import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/community/community_challenge.dart';
import '../../services/community/community_challenge_service.dart';
import '../../theme/app_theme.dart';
import 'team_formation_screen.dart';

class ChallengeParticipationScreen extends ConsumerStatefulWidget {
  final CommunityChallenge challenge;

  const ChallengeParticipationScreen({
    super.key,
    required this.challenge,
  });

  @override
  ConsumerState<ChallengeParticipationScreen> createState() =>
      _ChallengeParticipationScreenState();
}

class _ChallengeParticipationScreenState
    extends ConsumerState<ChallengeParticipationScreen> {
  final CommunityChallengeService _challengeService = CommunityChallengeService();
  ParticipationMode? _selectedMode;
  bool _isJoining = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        title: Text(
          'Join Challenge',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor(context),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildChallengeOverview(),
                  const SizedBox(height: 24),
                  _buildParticipationOptions(),
                  const SizedBox(height: 24),
                  if (_selectedMode != null) _buildModeDescription(),
                ],
              ),
            ),
          ),
          _buildJoinButton(),
        ],
      ),
    );
  }

  Widget _buildChallengeOverview() {
    final theme = Theme.of(context);

    return Card(
      color: AppTheme.cardColor(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getCategoryColor(widget.challenge.type),
                        _getCategoryColor(widget.challenge.type).withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      widget.challenge.icon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.challenge.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor(context),
                        ),
                      ),
                      Text(
                        widget.challenge.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.people,
                  label: '${widget.challenge.getTotalParticipants()} joined',
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.timer,
                  label: '${widget.challenge.daysRemaining} days left',
                  color: widget.challenge.daysRemaining > 7
                      ? Colors.green
                      : widget.challenge.daysRemaining > 3
                          ? Colors.orange
                          : Colors.red,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.flag,
                  label: '${widget.challenge.targetValue} ${widget.challenge.unit}',
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipationOptions() {
    final theme = Theme.of(context);

    return Card(
      color: AppTheme.cardColor(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How would you like to participate?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.challenge.acceptsIndividuals)
              _buildParticipationOption(
                mode: ParticipationMode.individual,
                icon: Icons.person,
                title: 'Individual',
                subtitle: 'Complete the challenge on your own',
                isEnabled: true,
              ),
            if (widget.challenge.acceptsTeams) ...[
              const SizedBox(height: 12),
              _buildParticipationOption(
                mode: ParticipationMode.teamWithSupporter,
                icon: Icons.group,
                title: 'Team with Supporters',
                subtitle: 'Form a team with your existing supporters',
                isEnabled: true,
              ),
              const SizedBox(height: 12),
              _buildParticipationOption(
                mode: ParticipationMode.teamWithAnyone,
                icon: Icons.public,
                title: 'Join Open Team',
                subtitle: 'Join or create a team with anyone',
                isEnabled: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParticipationOption({
    required ParticipationMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isEnabled,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedMode == mode;

    return GestureDetector(
      onTap: isEnabled ? () => setState(() => _selectedMode = mode) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withValues(alpha: 0.1)
              : AppTheme.surfaceColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.primaryColor
                : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.primaryColor
                    : Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? theme.primaryColor
                          : AppTheme.textColor(context),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.primaryColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeDescription() {
    final theme = Theme.of(context);
    String title;
    String description;
    IconData icon;

    switch (_selectedMode!) {
      case ParticipationMode.individual:
        title = 'Individual Challenge';
        description =
            'You\'ll participate solo and track your own progress. Perfect for personal goals and self-motivation.';
        icon = Icons.person;
        break;
      case ParticipationMode.teamWithSupporter:
        title = 'Team with Supporters';
        description =
            'Invite your existing supporters to form a team. Work together towards the challenge goal and motivate each other.';
        icon = Icons.group;
        break;
      case ParticipationMode.teamWithAnyone:
        title = 'Open Team';
        description =
            'Join an existing open team or create a new one that anyone can join. Great for meeting new people with similar goals.';
        icon = Icons.public;
        break;
    }

    return Card(
      color: AppTheme.cardColor(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.primaryColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinButton() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedMode == null || _isJoining ? null : _joinChallenge,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isJoining
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _selectedMode == null
                        ? 'Select participation mode'
                        : 'Join Challenge',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
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

  Future<void> _joinChallenge() async {
    if (_selectedMode == null) return;

    setState(() => _isJoining = true);

    try {
      switch (_selectedMode!) {
        case ParticipationMode.individual:
          final success = await _challengeService.joinChallengeAsIndividual(
            widget.challenge.id,
          );
          if (success) {
            _showSuccessDialog();
          } else {
            _showErrorSnackBar('Failed to join challenge');
          }
          break;

        case ParticipationMode.teamWithSupporter:
        case ParticipationMode.teamWithAnyone:
          // Navigate to team formation screen
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => TeamFormationScreen(
                challenge: widget.challenge,
                mode: _selectedMode!,
              ),
            ),
          );
          if (result == true) {
            _showSuccessDialog();
          }
          break;
      }
    } catch (e) {
      _showErrorSnackBar('Error joining challenge: $e');
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Success!'),
        content: Text(
          'You\'ve successfully joined "${widget.challenge.title}". Good luck!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close participation screen
            },
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
}

enum ParticipationMode {
  individual,
  teamWithSupporter,
  teamWithAnyone,
}