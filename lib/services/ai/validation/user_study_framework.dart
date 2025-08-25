// lib/services/ai/validation/user_study_framework.dart

import 'dart:convert';
import 'dart:io';
import 'user_study_models.dart';

/// Framework for conducting user studies for dissertation validation
class UserStudyFramework {
  final List<UserStudySession> _sessions = [];
  
  /// Add a completed study session
  void addSession(UserStudySession session) {
    _sessions.add(session);
  }
  
  /// Generate statistical analysis of all sessions
  Map<String, dynamic> generateStudyAnalysis() {
    if (_sessions.isEmpty) {
      return {'error': 'No study sessions available'};
    }
    
    final privacyScores = _sessions.map((s) => s.privacyResult.comprehensionScore).toList();
    final disclaimerSatisfaction = _sessions.map((s) => s.disclaimerResult.satisfactionRating).toList();
    final securityConfidence = _sessions.map((s) => s.securityResult.securityConfidenceRating).toList();
    
    return {
      'study_overview': {
        'total_participants': _sessions.length,
        'study_period': {
          'start': _sessions.first.sessionStart.toIso8601String(),
          'end': _sessions.last.sessionEnd.toIso8601String(),
        },
        'participant_demographics': _generateDemographics(),
      },
      'privacy_comprehension': {
        'average_score': _calculateAverage(privacyScores),
        'score_distribution': _generateScoreDistribution(privacyScores),
        'comprehension_by_experience': _analyzeByExperience(),
        'task_completion_stats': _analyzeTaskCompletion(),
      },
      'disclaimer_effectiveness': {
        'notice_rate_percent': _calculatePercentage(
          _sessions.where((s) => s.disclaimerResult.noticedHealthDisclaimer).length
        ),
        'helpfulness_rate_percent': _calculatePercentage(
          _sessions.where((s) => s.disclaimerResult.foundDisclaimerHelpful).length
        ),
        'intrusiveness_rate_percent': _calculatePercentage(
          _sessions.where((s) => s.disclaimerResult.foundDisclaimerIntrusive).length
        ),
        'average_satisfaction': _calculateAverage(disclaimerSatisfaction.map((r) => r.toDouble()).toList()),
        'trust_improvement_rate': _calculatePercentage(
          _sessions.where((s) => s.disclaimerResult.increasedTrustInAI).length
        ),
      },
      'security_awareness': {
        'attack_recognition_rate': _calculatePercentage(
          _sessions.where((s) => s.securityResult.recognizedAttackAttempt).length
        ),
        'security_understanding_rate': _calculatePercentage(
          _sessions.where((s) => s.securityResult.understoodSecurityMeasures).length
        ),
        'protection_confidence_rate': _calculatePercentage(
          _sessions.where((s) => s.securityResult.feltDataWasProtected).length
        ),
        'average_confidence_rating': _calculateAverage(securityConfidence.map((r) => r.toDouble()).toList()),
      },
      'statistical_validity': {
        'sample_size_adequate': _sessions.length >= 30,
        'demographic_diversity': _assessDemographicDiversity(),
        'response_consistency': _assessResponseConsistency(),
      }
    };
  }
  
  Map<String, dynamic> _generateDemographics() {
    final ageGroups = <String, int>{};
    final genderDistribution = <String, int>{};
    final techExperience = <String, int>{};
    final healthAppUsage = <String, int>{};
    
    for (final session in _sessions) {
      final p = session.participant;
      
      // Age groups
      String ageGroup;
      if (p.age < 25) {
        ageGroup = '18-24';
      } else if (p.age < 35) {
        ageGroup = '25-34';
      } else if (p.age < 45) {
        ageGroup = '35-44';
      } else if (p.age < 55) {
        ageGroup = '45-54';
      } else {
        ageGroup = '55+';
      }
      ageGroups[ageGroup] = (ageGroups[ageGroup] ?? 0) + 1;
      
      genderDistribution[p.gender] = (genderDistribution[p.gender] ?? 0) + 1;
      techExperience[p.techExperience] = (techExperience[p.techExperience] ?? 0) + 1;
      healthAppUsage[p.healthAppUsage] = (healthAppUsage[p.healthAppUsage] ?? 0) + 1;
    }
    
    return {
      'age_groups': ageGroups,
      'gender_distribution': genderDistribution,
      'tech_experience': techExperience,
      'health_app_usage': healthAppUsage,
    };
  }
  
  double _calculateAverage(List<double> values) {
    return values.reduce((a, b) => a + b) / values.length;
  }
  
  double _calculatePercentage(int count) {
    return (count / _sessions.length) * 100;
  }
  
  Map<String, int> _generateScoreDistribution(List<double> scores) {
    final distribution = <String, int>{};
    for (final score in scores) {
      String range;
      if (score >= 0.9) {
        range = '90-100%';
      } else if (score >= 0.8) {
        range = '80-89%';
      } else if (score >= 0.7) {
        range = '70-79%';
      } else if (score >= 0.6) {
        range = '60-69%';
      } else {
        range = '<60%';
      }
      distribution[range] = (distribution[range] ?? 0) + 1;
    }
    return distribution;
  }
  
  Map<String, double> _analyzeByExperience() {
    final experienceGroups = <String, List<double>>{};
    
    for (final session in _sessions) {
      final experience = session.participant.techExperience;
      final score = session.privacyResult.comprehensionScore;
      experienceGroups.putIfAbsent(experience, () => []).add(score);
    }
    
    return experienceGroups.map((key, scores) => 
      MapEntry(key, _calculateAverage(scores))
    );
  }
  
  Map<String, dynamic> _analyzeTaskCompletion() {
    final completionTimes = _sessions.map((s) => s.privacyResult.taskCompletionTime).toList();
    final incorrectAttempts = _sessions.map((s) => s.privacyResult.incorrectAttempts).toList();
    
    return {
      'average_completion_time_sec': _calculateAverage(completionTimes.map((t) => t.toDouble()).toList()),
      'average_incorrect_attempts': _calculateAverage(incorrectAttempts.map((a) => a.toDouble()).toList()),
      'task_success_rate_percent': _calculatePercentage(
        _sessions.where((s) => s.privacyResult.incorrectAttempts == 0).length
      ),
    };
  }
  
  bool _assessDemographicDiversity() {
    final demographics = _generateDemographics();
    final ageGroups = demographics['age_groups'] as Map<String, int>;
    final genders = demographics['gender_distribution'] as Map<String, int>;
    
    // Check for reasonable distribution
    return ageGroups.length >= 3 && genders.length >= 2;
  }
  
  bool _assessResponseConsistency() {
    // Simple consistency check - satisfaction should correlate with helpfulness
    final consistent = _sessions.where((s) => 
      (s.disclaimerResult.foundDisclaimerHelpful && s.disclaimerResult.satisfactionRating >= 4) ||
      (!s.disclaimerResult.foundDisclaimerHelpful && s.disclaimerResult.satisfactionRating <= 2)
    ).length;
    
    return (consistent / _sessions.length) >= 0.7; // 70% consistency threshold
  }
  
  /// Save study results to file
  Future<void> saveStudyResults() async {
    final analysis = generateStudyAnalysis();
    final file = File('user_study_results.json');
    await file.writeAsString(JsonEncoder.withIndent('  ').convert(analysis));
    // ignore: avoid_print
    print('📊 User study results saved to: user_study_results.json');
  }
  
  /// Generate consent form for participants
  String generateConsentForm() {
    return '''
PARTICIPANT CONSENT FORM
SolarVita AI Security Framework User Study

Purpose: This study evaluates the effectiveness and usability of AI security features in health applications for academic research.

Participation involves:
- Privacy settings comprehension tasks (10-15 minutes)
- AI interaction with security disclaimers
- Feedback questionnaire (5-10 minutes)

Data Collection:
- Task performance metrics (completion time, errors)
- Satisfaction ratings and feedback
- Demographic information (age, gender, tech experience)

Privacy:
- All data is anonymized and stored securely
- No personal health information is collected
- Results used solely for academic research
- Right to withdraw at any time

By signing below, I consent to participate in this study:

Participant Name: _________________
Signature: _________________
Date: _________________

Researcher: _________________
''';
  }
}