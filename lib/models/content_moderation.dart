// lib/models/content_moderation.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum ModerationReason {
  spam,
  harassment,
  inappropriateContent,
  falseInformation,
  hate,
  violence,
  other,
}

enum ModerationStatus {
  pending,
  approved,
  rejected,
  escalated,
}

enum ModerationAction {
  none,
  warning,
  contentRemoval,
  accountSuspension,
  accountBan,
}

class ContentReport {
  final String id;
  final String reporterId;
  final String reporterName;
  final String contentId;
  final String contentType; // 'post' or 'comment'
  final String contentOwnerId;
  final String contentOwnerName;
  final ModerationReason reason;
  final String? customReason;
  final String? description;
  final DateTime reportedAt;
  final ModerationStatus status;
  final String? moderatorId;
  final String? moderatorNotes;
  final DateTime? reviewedAt;
  final ModerationAction action;

  ContentReport({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.contentId,
    required this.contentType,
    required this.contentOwnerId,
    required this.contentOwnerName,
    required this.reason,
    this.customReason,
    this.description,
    required this.reportedAt,
    required this.status,
    this.moderatorId,
    this.moderatorNotes,
    this.reviewedAt,
    required this.action,
  });

  factory ContentReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ContentReport(
      id: doc.id,
      reporterId: data['reporterId'] ?? '',
      reporterName: data['reporterName'] ?? '',
      contentId: data['contentId'] ?? '',
      contentType: data['contentType'] ?? '',
      contentOwnerId: data['contentOwnerId'] ?? '',
      contentOwnerName: data['contentOwnerName'] ?? '',
      reason: ModerationReason.values.firstWhere(
        (e) => e.toString() == data['reason'],
        orElse: () => ModerationReason.other,
      ),
      customReason: data['customReason'],
      description: data['description'],
      reportedAt: (data['reportedAt'] as Timestamp).toDate(),
      status: ModerationStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => ModerationStatus.pending,
      ),
      moderatorId: data['moderatorId'],
      moderatorNotes: data['moderatorNotes'],
      reviewedAt: data['reviewedAt'] != null 
          ? (data['reviewedAt'] as Timestamp).toDate() 
          : null,
      action: ModerationAction.values.firstWhere(
        (e) => e.toString() == data['action'],
        orElse: () => ModerationAction.none,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reporterId': reporterId,
      'reporterName': reporterName,
      'contentId': contentId,
      'contentType': contentType,
      'contentOwnerId': contentOwnerId,
      'contentOwnerName': contentOwnerName,
      'reason': reason.toString(),
      'customReason': customReason,
      'description': description,
      'reportedAt': Timestamp.fromDate(reportedAt),
      'status': status.toString(),
      'moderatorId': moderatorId,
      'moderatorNotes': moderatorNotes,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'action': action.toString(),
    };
  }

  String getReasonDisplayName() {
    switch (reason) {
      case ModerationReason.spam:
        return 'Spam';
      case ModerationReason.harassment:
        return 'Harassment';
      case ModerationReason.inappropriateContent:
        return 'Inappropriate Content';
      case ModerationReason.falseInformation:
        return 'False Information';
      case ModerationReason.hate:
        return 'Hate Speech';
      case ModerationReason.violence:
        return 'Violence';
      case ModerationReason.other:
        return 'Other';
    }
  }

  String getStatusDisplayName() {
    switch (status) {
      case ModerationStatus.pending:
        return 'Pending Review';
      case ModerationStatus.approved:
        return 'Approved';
      case ModerationStatus.rejected:
        return 'Rejected';
      case ModerationStatus.escalated:
        return 'Escalated';
    }
  }

  String getActionDisplayName() {
    switch (action) {
      case ModerationAction.none:
        return 'No Action';
      case ModerationAction.warning:
        return 'Warning Issued';
      case ModerationAction.contentRemoval:
        return 'Content Removed';
      case ModerationAction.accountSuspension:
        return 'Account Suspended';
      case ModerationAction.accountBan:
        return 'Account Banned';
    }
  }
}

class AutoModerationResult {
  final bool flagged;
  final double confidenceScore;
  final List<String> flaggedCategories;
  final String? explanation;
  final bool requiresHumanReview;

  AutoModerationResult({
    required this.flagged,
    required this.confidenceScore,
    required this.flaggedCategories,
    this.explanation,
    required this.requiresHumanReview,
  });
}

class ContentModerationService {
  // Basic profanity filter - in production, use a more sophisticated service
  static const List<String> _profanityList = [
    'spam', 'fake', 'scam', 'hate', // Basic examples
  ];

  static const List<String> _suspiciousPatterns = [
    r'\b(buy|purchase|sale|discount|offer)\b.*\b(now|today|limited)\b',
    r'\b(click|visit|check)\s+(here|link|out)\b',
    r'\$\d+|\d+%\s+(off|discount)',
  ];

  static AutoModerationResult analyzeContent(String content) {
    final lowerContent = content.toLowerCase();
    final flaggedCategories = <String>[];
    double score = 0.0;

    // Check for profanity
    for (final word in _profanityList) {
      if (lowerContent.contains(word)) {
        flaggedCategories.add('inappropriate_language');
        score += 0.3;
      }
    }

    // Check for spam patterns
    for (final pattern in _suspiciousPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(content)) {
        flaggedCategories.add('spam');
        score += 0.4;
      }
    }

    // Check for excessive caps
    final capsCount = content.split('').where((char) => char == char.toUpperCase() && char != char.toLowerCase()).length;
    final capsRatio = capsCount / content.length;
    if (capsRatio > 0.7 && content.length > 10) {
      flaggedCategories.add('excessive_caps');
      score += 0.2;
    }

    // Check for excessive repetition
    final words = content.split(' ');
    final uniqueWords = words.toSet();
    if (words.length > 5 && uniqueWords.length / words.length < 0.3) {
      flaggedCategories.add('repetitive_content');
      score += 0.2;
    }

    final flagged = score > 0.5 || flaggedCategories.isNotEmpty;
    final requiresHumanReview = score > 0.3;

    return AutoModerationResult(
      flagged: flagged,
      confidenceScore: score.clamp(0.0, 1.0),
      flaggedCategories: flaggedCategories,
      explanation: flaggedCategories.isNotEmpty 
          ? 'Content flagged for: ${flaggedCategories.join(', ')}'
          : null,
      requiresHumanReview: requiresHumanReview,
    );
  }

  static String getReasonDescription(ModerationReason reason) {
    switch (reason) {
      case ModerationReason.spam:
        return 'Unwanted promotional content or repetitive messages';
      case ModerationReason.harassment:
        return 'Bullying, threatening, or harassing behavior';
      case ModerationReason.inappropriateContent:
        return 'Content that violates community guidelines';
      case ModerationReason.falseInformation:
        return 'Misleading or false health/fitness information';
      case ModerationReason.hate:
        return 'Hateful speech targeting individuals or groups';
      case ModerationReason.violence:
        return 'Content promoting or depicting violence';
      case ModerationReason.other:
        return 'Other violation of community guidelines';
    }
  }

  static List<String> getSuggestedActions(ModerationReason reason) {
    switch (reason) {
      case ModerationReason.spam:
        return ['Remove content', 'Issue warning', 'Temporary suspension'];
      case ModerationReason.harassment:
        return ['Remove content', 'Issue warning', 'Account suspension', 'Account ban'];
      case ModerationReason.inappropriateContent:
        return ['Remove content', 'Issue warning', 'Request content edit'];
      case ModerationReason.falseInformation:
        return ['Add warning label', 'Remove content', 'Provide correct information'];
      case ModerationReason.hate:
        return ['Remove content', 'Account suspension', 'Account ban'];
      case ModerationReason.violence:
        return ['Remove content', 'Account suspension', 'Account ban', 'Report to authorities'];
      case ModerationReason.other:
        return ['Review content', 'Issue warning', 'Take appropriate action'];
    }
  }
}