// lib/services/ai/validation/user_study_models.dart


/// User study participant data
class Participant {
  final String id;
  final int age;
  final String gender;
  final String techExperience; // 'low', 'medium', 'high'
  final String healthAppUsage; // 'never', 'occasionally', 'frequently'
  final DateTime studyDate;
  
  Participant({
    required this.id,
    required this.age,
    required this.gender,
    required this.techExperience,
    required this.healthAppUsage,
    required this.studyDate,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'age': age,
    'gender': gender,
    'tech_experience': techExperience,
    'health_app_usage': healthAppUsage,
    'study_date': studyDate.toIso8601String(),
  };
}

/// Privacy settings comprehension test results
class PrivacyComprehensionResult {
  final String participantId;
  final bool understoodHealthDataProcessing;
  final bool understoodConsentRequirements;
  final bool understoodDataExport;
  final bool understoodDataDeletion;
  final bool understoodThirdPartyProcessing;
  final int taskCompletionTime; // seconds
  final int incorrectAttempts;
  final String feedbackComments;
  
  PrivacyComprehensionResult({
    required this.participantId,
    required this.understoodHealthDataProcessing,
    required this.understoodConsentRequirements,
    required this.understoodDataExport,
    required this.understoodDataDeletion,
    required this.understoodThirdPartyProcessing,
    required this.taskCompletionTime,
    required this.incorrectAttempts,
    required this.feedbackComments,
  });
  
  double get comprehensionScore {
    int correct = 0;
    if (understoodHealthDataProcessing) correct++;
    if (understoodConsentRequirements) correct++;
    if (understoodDataExport) correct++;
    if (understoodDataDeletion) correct++;
    if (understoodThirdPartyProcessing) correct++;
    return correct / 5.0; // Score out of 1.0
  }
  
  Map<String, dynamic> toJson() => {
    'participant_id': participantId,
    'health_data_processing': understoodHealthDataProcessing,
    'consent_requirements': understoodConsentRequirements,
    'data_export': understoodDataExport,
    'data_deletion': understoodDataDeletion,
    'third_party_processing': understoodThirdPartyProcessing,
    'comprehension_score': comprehensionScore,
    'task_completion_time_sec': taskCompletionTime,
    'incorrect_attempts': incorrectAttempts,
    'feedback': feedbackComments,
  };
}

/// Disclaimer effectiveness study results
class DisclaimerEffectivenessResult {
  final String participantId;
  final bool noticedHealthDisclaimer;
  final bool foundDisclaimerHelpful;
  final bool foundDisclaimerIntrusive;
  final int satisfactionRating; // 1-5 scale
  final bool increasedTrustInAI;
  final String preferredDisclaimerStyle;
  final String improvementSuggestions;
  
  DisclaimerEffectivenessResult({
    required this.participantId,
    required this.noticedHealthDisclaimer,
    required this.foundDisclaimerHelpful,
    required this.foundDisclaimerIntrusive,
    required this.satisfactionRating,
    required this.increasedTrustInAI,
    required this.preferredDisclaimerStyle,
    required this.improvementSuggestions,
  });
  
  Map<String, dynamic> toJson() => {
    'participant_id': participantId,
    'noticed_disclaimer': noticedHealthDisclaimer,
    'found_helpful': foundDisclaimerHelpful,
    'found_intrusive': foundDisclaimerIntrusive,
    'satisfaction_rating': satisfactionRating,
    'increased_trust': increasedTrustInAI,
    'preferred_style': preferredDisclaimerStyle,
    'improvement_suggestions': improvementSuggestions,
  };
}

/// Security awareness assessment
class SecurityAwarenessResult {
  final String participantId;
  final bool recognizedAttackAttempt;
  final bool understoodSecurityMeasures;
  final bool feltDataWasProtected;
  final int securityConfidenceRating; // 1-5 scale
  final bool wantedMoreSecurityInfo;
  final String securityConcerns;
  
  SecurityAwarenessResult({
    required this.participantId,
    required this.recognizedAttackAttempt,
    required this.understoodSecurityMeasures,
    required this.feltDataWasProtected,
    required this.securityConfidenceRating,
    required this.wantedMoreSecurityInfo,
    required this.securityConcerns,
  });
  
  Map<String, dynamic> toJson() => {
    'participant_id': participantId,
    'recognized_attack': recognizedAttackAttempt,
    'understood_security': understoodSecurityMeasures,
    'felt_protected': feltDataWasProtected,
    'confidence_rating': securityConfidenceRating,
    'wanted_more_info': wantedMoreSecurityInfo,
    'security_concerns': securityConcerns,
  };
}

/// Complete user study session
class UserStudySession {
  final Participant participant;
  final PrivacyComprehensionResult privacyResult;
  final DisclaimerEffectivenessResult disclaimerResult;
  final SecurityAwarenessResult securityResult;
  final DateTime sessionStart;
  final DateTime sessionEnd;
  
  UserStudySession({
    required this.participant,
    required this.privacyResult,
    required this.disclaimerResult,
    required this.securityResult,
    required this.sessionStart,
    required this.sessionEnd,
  });
  
  Duration get sessionDuration => sessionEnd.difference(sessionStart);
  
  Map<String, dynamic> toJson() => {
    'participant': participant.toJson(),
    'privacy_comprehension': privacyResult.toJson(),
    'disclaimer_effectiveness': disclaimerResult.toJson(),
    'security_awareness': securityResult.toJson(),
    'session_duration_minutes': sessionDuration.inMinutes,
    'session_start': sessionStart.toIso8601String(),
    'session_end': sessionEnd.toIso8601String(),
  };
}