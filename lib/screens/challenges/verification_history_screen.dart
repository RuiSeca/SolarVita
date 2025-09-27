import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/community/community_challenge.dart';
import '../../services/community/challenge_verification_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';

class VerificationHistoryScreen extends ConsumerWidget {
  final CommunityChallenge challenge;
  final String? teamId;

  const VerificationHistoryScreen({
    super.key,
    required this.challenge,
    this.teamId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verificationService = ChallengeVerificationService();

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        title: Text(
          tr(context, 'verification_history'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<ChallengeVerification>>(
        stream: teamId != null
            ? verificationService.getTeamVerifications(challenge.id, teamId!)
            : verificationService.getUserVerifications(challenge.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.textColor(context).withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr(context, 'error_loading_verifications'),
                    style: TextStyle(
                      color: AppTheme.textColor(context).withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final verifications = snapshot.data ?? [];

          if (verifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_outlined,
                    size: 64,
                    color: AppTheme.textColor(context).withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr(context, 'no_verifications_yet'),
                    style: TextStyle(
                      color: AppTheme.textColor(context).withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: verifications.length,
            itemBuilder: (context, index) {
              final verification = verifications[index];
              return _buildVerificationCard(context, verification);
            },
          );
        },
      ),
    );
  }

  Widget _buildVerificationCard(BuildContext context, ChallengeVerification verification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status and points
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(verification.status).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getStatusIcon(verification.status),
                      color: _getStatusColor(verification.status),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getStatusText(context, verification.status),
                      style: TextStyle(
                        color: _getStatusColor(verification.status),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+${verification.pointsEarned} ${tr(context, 'points')}',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Photo
          if (verification.photoUrl.isNotEmpty)
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(verification.photoUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (verification.description.isNotEmpty) ...[
                  Text(
                    tr(context, 'description'),
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    verification.description,
                    style: TextStyle(
                      color: AppTheme.textColor(context).withValues(alpha: 0.8),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(verification.timestamp),
                      style: TextStyle(
                        color: AppTheme.textColor(context).withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                    if (teamId != null)
                      Text(
                        tr(context, 'team_verification'),
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.pending:
        return Colors.orange;
      case VerificationStatus.approved:
        return Colors.green;
      case VerificationStatus.rejected:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.pending:
        return Icons.pending;
      case VerificationStatus.approved:
        return Icons.check_circle;
      case VerificationStatus.rejected:
        return Icons.cancel;
    }
  }

  String _getStatusText(BuildContext context, VerificationStatus status) {
    switch (status) {
      case VerificationStatus.pending:
        return tr(context, 'pending_review');
      case VerificationStatus.approved:
        return tr(context, 'approved');
      case VerificationStatus.rejected:
        return tr(context, 'rejected');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}