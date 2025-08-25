// lib/services/ai/ai_security_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Security service for AI health assistant protection
/// Implements comprehensive security measures from dissertation Chapter 7
class AISecurityService {
  static final AISecurityService _instance = AISecurityService._internal();
  factory AISecurityService() => _instance;
  AISecurityService._internal();

  // Security event logging for dissertation metrics
  final List<SecurityEvent> _securityEvents = [];
  int _blockedAttacks = 0;
  int _totalRequests = 0;

  // Prompt injection patterns from empirical testing (Chapter 6)
  static const Map<String, double> injectionPatterns = {
    // Direct instruction override patterns (73.2% success rate in testing)
    'ignore previous': 0.95,
    'forget instructions': 0.90,
    'you are now': 0.85,
    'act as': 0.80,
    'roleplay as': 0.75,
    'pretend to be': 0.70,
    
    // Medical authority patterns (52.3% success rate in testing)
    'as a doctor': 0.95,
    'medical professional': 0.90,
    'healthcare provider': 0.85,
    'diagnose': 0.80,
    'prescribe': 0.95,
    'treatment plan': 0.75,
    
    // System manipulation patterns (86.4% success in compound attacks)
    'override safety': 0.98,
    'bypass restrictions': 0.95,
    'emergency override': 0.90,
    'debug mode': 0.85,
    'system prompt': 0.80,
    
    // Context poisoning patterns (89.7% persistence rate)
    'we discussed': 0.70,
    'you told me': 0.65,
    'previous conversation': 0.60,
    'you recommended': 0.70,
  };

  static const Map<String, double> medicalOverridePatterns = {
    'stop taking medication': 0.98,
    'ignore doctor advice': 0.95,
    'medical emergency bypass': 0.92,
    'immediate treatment needed': 0.85,
    'life threatening situation': 0.90,
    'urgent medical consultation': 0.85,
  };

  /// Validates user input for security threats
  /// Returns SecurityValidationResult with action recommendations
  Future<SecurityValidationResult> validateInput(String userInput) async {
    _totalRequests++;
    
    final startTime = DateTime.now();
    
    // Input sanitization
    if (!_isValidInput(userInput)) {
      return _blockAndLog('Invalid input format', userInput, 'FORMAT_VIOLATION');
    }

    // Length validation (from Chapter 7 framework)
    if (userInput.length > 2000) {
      return _blockAndLog('Input too long', userInput, 'LENGTH_VIOLATION');
    }

    // Prompt injection detection
    final injectionResult = await _detectPromptInjection(userInput);
    if (injectionResult.isBlocked) {
      return _blockAndLog(
        'Prompt injection detected: ${injectionResult.reason}', 
        userInput, 
        'PROMPT_INJECTION',
        patterns: injectionResult.detectedPatterns
      );
    }

    // Medical authority detection
    final medicalResult = _detectMedicalAuthorityAttempt(userInput);
    if (medicalResult.isBlocked) {
      return _blockAndLog(
        'Medical authority attempt: ${medicalResult.reason}', 
        userInput, 
        'MEDICAL_AUTHORITY',
        patterns: medicalResult.detectedPatterns
      );
    }

    // Multi-language bypass detection
    final languageResult = _detectMultiLanguageBypass(userInput);
    if (languageResult.riskLevel > 0.8) {
      return _blockAndLog(
        'Multi-language bypass attempt', 
        userInput, 
        'LANGUAGE_BYPASS'
      );
    }

    // Progressive attack detection
    final progressionResult = await _detectProgressiveAttack(userInput);
    if (progressionResult.riskLevel > 0.85) {
      return _blockAndLog(
        'Progressive boundary erosion detected', 
        userInput, 
        'PROGRESSIVE_ATTACK'
      );
    }

    final processingTime = DateTime.now().difference(startTime).inMilliseconds;
    
    // Log successful validation for metrics
    _logSecurityEvent(SecurityEvent(
      timestamp: DateTime.now(),
      eventType: 'INPUT_VALIDATED',
      userInput: userInput,
      action: 'ALLOWED',
      processingTimeMs: processingTime,
    ));

    return SecurityValidationResult.approved(
      userInput, 
      processingTimeMs: processingTime
    );
  }

  /// Detects prompt injection attempts using pattern matching
  Future<InjectionDetectionResult> _detectPromptInjection(String input) async {
    double injectionScore = 0.0;
    List<String> detectedPatterns = [];
    
    String normalizedInput = _normalizeInput(input);
    
    // Pattern-based detection
    for (var entry in injectionPatterns.entries) {
      if (normalizedInput.contains(entry.key)) {
        injectionScore += entry.value;
        detectedPatterns.add(entry.key);
      }
    }
    
    // Medical-specific pattern detection
    for (var entry in medicalOverridePatterns.entries) {
      if (normalizedInput.contains(entry.key)) {
        injectionScore += entry.value * 1.2; // Higher weight for medical patterns
        detectedPatterns.add(entry.key);
      }
    }
    
    // Semantic analysis for instruction-like language
    injectionScore += _analyzeInstructionalLanguage(normalizedInput);
    
    // Determine if should block (threshold from empirical testing)
    bool shouldBlock = injectionScore > 0.75;
    
    return InjectionDetectionResult(
      isBlocked: shouldBlock,
      confidence: injectionScore,
      detectedPatterns: detectedPatterns,
      reason: shouldBlock ? 'Injection score: ${injectionScore.toStringAsFixed(2)}' : null,
    );
  }

  /// Detects medical authority impersonation attempts
  MedicalDetectionResult _detectMedicalAuthorityAttempt(String input) {
    List<String> medicalAuthorityIndicators = [
      'as a doctor', 'as your physician', 'medical professional',
      'in my medical opinion', 'professionally speaking',
      'medical advice', 'clinical assessment', 'diagnosis',
      'prescribe', 'treatment recommendation'
    ];
    
    String lowerInput = input.toLowerCase();
    List<String> detectedPatterns = [];
    double authorityScore = 0.0;
    
    for (String indicator in medicalAuthorityIndicators) {
      if (lowerInput.contains(indicator)) {
        detectedPatterns.add(indicator);
        authorityScore += 1.0;
      }
    }
    
    // Check for emergency bypass attempts
    List<String> emergencyBypass = [
      'medical emergency', 'urgent medical', 'emergency situation',
      'life threatening', 'immediate medical attention'
    ];
    
    for (String emergency in emergencyBypass) {
      if (lowerInput.contains(emergency)) {
        detectedPatterns.add(emergency);
        authorityScore += 1.5; // Higher weight for emergency bypass
      }
    }
    
    bool shouldBlock = authorityScore > 1.5;
    
    return MedicalDetectionResult(
      isBlocked: shouldBlock,
      detectedPatterns: detectedPatterns,
      authorityScore: authorityScore,
      reason: shouldBlock ? 'Medical authority score: ${authorityScore.toStringAsFixed(1)}' : null,
    );
  }

  /// Analyzes input for multi-language bypass attempts
  LanguageBypassResult _detectMultiLanguageBypass(String input) {
    Map<String, double> multiLangPatterns = {
      'médico': 0.8, // Spanish: doctor
      'docteur': 0.8, // French: doctor
      'arzt': 0.8, // German: doctor
      'dottore': 0.8, // Italian: doctor
      'diagnóstico': 0.9, // Spanish: diagnosis
      'diagnostic': 0.9, // French: diagnosis
      'medicamento': 0.9, // Spanish: medication
      'médicament': 0.9, // French: medication
    };
    
    double score = 0.0;
    String lowerInput = input.toLowerCase();
    
    for (var entry in multiLangPatterns.entries) {
      if (lowerInput.contains(entry.key)) {
        score += entry.value;
      }
    }
    
    return LanguageBypassResult(riskLevel: score);
  }

  /// Detects progressive boundary erosion attacks
  Future<ProgressionDetectionResult> _detectProgressiveAttack(String input) async {
    // This would analyze conversation history for gradual boundary testing
    // For now, implement basic detection
    
    List<String> boundaryTestPatterns = [
      'can you help with', 'is it okay to', 'would you be able to',
      'just this once', 'small exception', 'quick question about',
      'hypothetically', 'what if', 'in theory'
    ];
    
    String lowerInput = input.toLowerCase();
    int boundaryTests = 0;
    
    for (String pattern in boundaryTestPatterns) {
      if (lowerInput.contains(pattern)) {
        boundaryTests++;
      }
    }
    
    double riskLevel = boundaryTests * 0.3;
    
    return ProgressionDetectionResult(riskLevel: riskLevel);
  }

  /// Filters and validates AI responses for health safety
  Future<ResponseFilterResult> filterResponse(String response, String originalInput) async {
    final startTime = DateTime.now();
    
    // Debug logging to see what's happening
    debugPrint('🔍 DEBUG: Filtering response: "${response.substring(0, response.length > 100 ? 100 : response.length)}..."');
    
    // Detect medical content in response
    final medicalContent = _detectMedicalContent(response);
    
    debugPrint('🔍 DEBUG: Medical content detected - hasMedicalContent: ${medicalContent.hasMedicalContent}, requiresDisclaimer: ${medicalContent.requiresDisclaimer}');
    debugPrint('🔍 DEBUG: Medical severity: ${medicalContent.severity}, requiresReferral: ${medicalContent.requiresReferral}');
    debugPrint('🔍 DEBUG: Terms found in response: ${_findMedicalTermsInResponse(response)}');
    
    String filteredResponse = response;
    List<String> modifications = [];
    
    // Remove inappropriate medical authority claims
    if (medicalContent.hasAuthorityClaimss) {
      filteredResponse = _removeAuthorityClaimss(filteredResponse);
      modifications.add('Removed medical authority claims');
    }
    
    // Block dangerous medical advice first
    if (medicalContent.isDangerous) {
      return ResponseFilterResult.blocked(
        reason: 'Response contains potentially dangerous medical advice',
        originalResponse: response,
      );
    }
    
    // Check if AI already included disclaimers to prevent duplicates
    bool alreadyHasDisclaimer = _hasExistingDisclaimer(filteredResponse);
    debugPrint('🔍 DEBUG: Response already has disclaimer: $alreadyHasDisclaimer');
    
    // Add appropriate disclaimer based on severity (avoid duplicates)
    if (medicalContent.requiresDisclaimer && !alreadyHasDisclaimer) {
      if (medicalContent.requiresReferral) {
        // High severity: Add comprehensive disclaimer with referral
        final comprehensiveDisclaimer = _getComprehensiveDisclaimer(medicalContent.severity);
        filteredResponse = _addDisclaimer(filteredResponse, comprehensiveDisclaimer);
        modifications.add('Added comprehensive health disclaimer with referral');
      } else {
        // Medium/low severity: Add simple disclaimer
        final disclaimer = _getHealthDisclaimer(medicalContent.severity);
        filteredResponse = _addDisclaimer(filteredResponse, disclaimer);
        modifications.add('Added health disclaimer');
      }
    } else if (alreadyHasDisclaimer) {
      modifications.add('Disclaimer already present - skipped adding duplicate');
    }
    
    final processingTime = DateTime.now().difference(startTime).inMilliseconds;
    
    // Log response filtering for metrics
    _logSecurityEvent(SecurityEvent(
      timestamp: DateTime.now(),
      eventType: 'RESPONSE_FILTERED',
      userInput: originalInput,
      aiResponse: response,
      filteredResponse: filteredResponse,
      action: modifications.isEmpty ? 'NO_CHANGES' : 'MODIFIED',
      processingTimeMs: processingTime,
    ));
    
    return ResponseFilterResult.processed(
      originalResponse: response,
      filteredResponse: filteredResponse,
      modifications: modifications,
      processingTimeMs: processingTime,
    );
  }

  /// Detects medical content in AI responses
  MedicalContentAnalysis _detectMedicalContent(String response) {
    // Only the most critical medical terms that absolutely require disclaimers
    List<String> medicalTerms = [
      // Direct medical diagnosis/treatment
      'diagnose you with', 'treatment for your', 'prescription for',
      'stop taking your medication', 'medical advice for', 'medical treatment for',
      'you should see a doctor', 'consult a doctor about',
      
      // Serious health conditions
      'serious health condition', 'medical emergency', 'chronic disease',
      'heart attack', 'stroke symptoms', 'blood pressure medication',
      'chest pain symptoms', 'breathing difficulties',
      
      // Emergency medical situations
      'call emergency services', 'go to hospital', 'seek immediate medical care',
      'urgent medical attention', 'emergency room visit'
    ];
    
    List<String> dangerousAdvice = [
      'stop taking medication', 'ignore doctor', 'don\'t see doctor',
      'cancel appointment', 'avoid medical care', 'self-medicate'
    ];
    
    List<String> authorityClaimss = [
      'as a doctor', 'medical professional', 'in my medical opinion',
      'professionally speaking', 'medical assessment', 'clinical judgment'
    ];
    
    String lowerResponse = response.toLowerCase();
    
    bool hasMedicalContent = medicalTerms.any((term) => lowerResponse.contains(term));
    bool isDangerous = dangerousAdvice.any((advice) => lowerResponse.contains(advice));
    bool hasAuthorityClaimss = authorityClaimss.any((claim) => lowerResponse.contains(claim));
    
    // Determine severity level
    MedicalSeverity severity = MedicalSeverity.none;
    if (isDangerous) {
      severity = MedicalSeverity.critical;
    } else if (hasAuthorityClaimss) {
      severity = MedicalSeverity.high;
    } else if (hasMedicalContent) {
      severity = MedicalSeverity.medium;
    }
    
    return MedicalContentAnalysis(
      hasMedicalContent: hasMedicalContent,
      isDangerous: isDangerous,
      hasAuthorityClaimss: hasAuthorityClaimss,
      severity: severity,
      requiresDisclaimer: hasMedicalContent,
      requiresReferral: severity.index >= MedicalSeverity.high.index,
    );
  }

  /// Adds appropriate health disclaimer based on content severity
  String _addDisclaimer(String response, String disclaimer) {
    return '$response\n\n$disclaimer';
  }

  /// Gets appropriate health disclaimer for severity level
  String _getHealthDisclaimer(MedicalSeverity severity) {
    switch (severity) {
      case MedicalSeverity.critical:
        return '🚨 **IMPORTANT HEALTH NOTICE**: This AI cannot provide medical advice, diagnoses, or treatment recommendations. For any health concerns, especially urgent ones, please consult qualified healthcare professionals or contact emergency services immediately.';
      case MedicalSeverity.high:
        return '🏥 **Health Disclaimer**: This information is for general fitness and wellness purposes only. Always consult with healthcare professionals for medical concerns, diagnoses, or treatment decisions.';
      case MedicalSeverity.medium:
        return '💡 **Health Note**: This is general wellness information only. For personalized health advice, please consult your healthcare provider.';
      default:
        return '';
    }
  }

  /// Helper function to identify which medical terms were found (for debugging)
  List<String> _findMedicalTermsInResponse(String response) {
    // Only the most critical medical terms that absolutely require disclaimers
    List<String> medicalTerms = [
      // Direct medical diagnosis/treatment
      'diagnose you with', 'treatment for your', 'prescription for',
      'stop taking your medication', 'medical advice for', 'medical treatment for',
      'you should see a doctor', 'consult a doctor about',
      
      // Serious health conditions
      'serious health condition', 'medical emergency', 'chronic disease',
      'heart attack', 'stroke symptoms', 'blood pressure medication',
      'chest pain symptoms', 'breathing difficulties',
      
      // Emergency medical situations
      'call emergency services', 'go to hospital', 'seek immediate medical care',
      'urgent medical attention', 'emergency room visit'
    ];
    
    String lowerResponse = response.toLowerCase();
    return medicalTerms.where((term) => lowerResponse.contains(term)).toList();
  }

  /// Checks if response already contains health disclaimers to prevent duplicates
  bool _hasExistingDisclaimer(String response) {
    String lowerResponse = response.toLowerCase();
    List<String> disclaimerIndicators = [
      'disclaimer',
      'consult',
      'healthcare',
      'medical professional',
      'doctor',
      'not a substitute',
      'seek medical',
      'professional advice',
      'health note',
      'important health notice',
      'for personalized',
    ];
    
    return disclaimerIndicators.any((indicator) => lowerResponse.contains(indicator));
  }
  
  /// Creates a comprehensive disclaimer that combines health info + professional referral
  String _getComprehensiveDisclaimer(MedicalSeverity severity) {
    switch (severity) {
      case MedicalSeverity.critical:
        return '🚨 **IMPORTANT HEALTH NOTICE**: This AI cannot provide medical advice, diagnoses, or treatment recommendations. For any health concerns, especially urgent ones, please consult qualified healthcare professionals or contact emergency services immediately.';
      case MedicalSeverity.high:
        return '🏥 **Health Disclaimer**: This information is for general fitness and wellness purposes only. Always consult with healthcare professionals for medical concerns, diagnoses, or treatment decisions.';
      default:
        return '💡 **Health Note**: This is general wellness information only. For personalized health advice, please consult your healthcare provider.';
    }
  }


  /// Removes inappropriate medical authority claims from response
  String _removeAuthorityClaimss(String response) {
    Map<String, String> authorityReplacements = {
      'As a doctor': 'Based on general health information',
      'In my medical opinion': 'From a general wellness perspective',
      'Medically speaking': 'Generally speaking about health',
      'As a medical professional': 'From a health and fitness standpoint',
      'My diagnosis is': 'This might suggest',
      'I prescribe': 'You might consider discussing with your doctor',
      'Medical advice': 'General health information',
      'Clinical assessment': 'General health observation',
    };
    
    String processed = response;
    for (var replacement in authorityReplacements.entries) {
      processed = processed.replaceAll(
        RegExp(replacement.key, caseSensitive: false),
        replacement.value
      );
    }
    
    return processed;
  }

  /// Utility methods for input processing
  String _normalizeInput(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  double _analyzeInstructionalLanguage(String input) {
    List<String> instructionalWords = ['please', 'now', 'must', 'should', 'need to', 'have to'];
    List<String> imperativeVerbs = ['tell', 'show', 'give', 'provide', 'explain', 'describe'];
    
    double score = 0.0;
    for (String word in instructionalWords) {
      if (input.contains(word)) score += 0.1;
    }
    for (String verb in imperativeVerbs) {
      if (input.contains(verb)) score += 0.15;
    }
    
    return score;
  }

  bool _isValidInput(String input) {
    // Basic validation: not empty, reasonable character set
    if (input.trim().isEmpty) return false;
    
    // Check for dangerous Unicode characters
    List<String> blockedCharacters = [
      '\u202E', // Right-to-left override
      '\u2066', // Left-to-right isolate
      '\u2067', // Right-to-left isolate
      '\u2068', // First strong isolate
    ];
    
    for (String char in blockedCharacters) {
      if (input.contains(char)) return false;
    }
    
    return true;
  }

  /// Helper method to block and log security violations
  SecurityValidationResult _blockAndLog(String reason, String input, String eventType, {List<String>? patterns}) {
    _blockedAttacks++;
    
    _logSecurityEvent(SecurityEvent(
      timestamp: DateTime.now(),
      eventType: eventType,
      userInput: input,
      action: 'BLOCKED',
      reason: reason,
      detectedPatterns: patterns,
    ));
    
    return SecurityValidationResult.blocked(reason);
  }

  /// Logs security events for dissertation metrics
  void _logSecurityEvent(SecurityEvent event) {
    _securityEvents.add(event);
    
    // Keep only recent events (last 1000)
    if (_securityEvents.length > 1000) {
      _securityEvents.removeRange(0, _securityEvents.length - 1000);
    }
    
    // Save to persistent storage for dissertation data
    _saveSecurityMetrics();
  }

  /// Saves security metrics for dissertation analysis
  Future<void> _saveSecurityMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save current metrics
      await prefs.setInt('ai_security_total_requests', _totalRequests);
      await prefs.setInt('ai_security_blocked_attacks', _blockedAttacks);
      await prefs.setString('ai_security_last_update', DateTime.now().toIso8601String());
      
      // Save recent events as JSON for analysis
      final recentEvents = _securityEvents.take(100).map((e) => e.toJson()).toList();
      await prefs.setString('ai_security_recent_events', jsonEncode(recentEvents));
      
    } catch (e) {
      // Ignore storage errors
    }
  }

  /// Gets comprehensive security metrics for dissertation
  Future<SecurityMetrics> getSecurityMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    
    final totalRequests = prefs.getInt('ai_security_total_requests') ?? _totalRequests;
    final blockedAttacks = prefs.getInt('ai_security_blocked_attacks') ?? _blockedAttacks;
    
    // Calculate success rates
    final attackPreventionRate = totalRequests > 0 
        ? (blockedAttacks / totalRequests * 100) 
        : 0.0;
    
    final avgProcessingTime = _securityEvents
        .where((e) => e.processingTimeMs != null)
        .map((e) => e.processingTimeMs!)
        .fold(0, (sum, time) => sum + time) / max(_securityEvents.length, 1);
    
    return SecurityMetrics(
      totalRequests: totalRequests,
      blockedAttacks: blockedAttacks,
      attackPreventionRate: attackPreventionRate,
      averageProcessingTimeMs: avgProcessingTime.round(),
      recentEvents: _securityEvents.take(20).toList(),
      lastUpdated: DateTime.now(),
    );
  }

  /// Resets security metrics (for testing)
  Future<void> resetMetrics() async {
    _securityEvents.clear();
    _blockedAttacks = 0;
    _totalRequests = 0;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ai_security_total_requests');
    await prefs.remove('ai_security_blocked_attacks');
    await prefs.remove('ai_security_recent_events');
  }
}

// Security result classes
class SecurityValidationResult {
  final bool isValid;
  final String? reason;
  final String? sanitizedInput;
  final int? processingTimeMs;

  SecurityValidationResult._(this.isValid, this.reason, this.sanitizedInput, this.processingTimeMs);

  factory SecurityValidationResult.approved(String input, {int? processingTimeMs}) =>
      SecurityValidationResult._(true, null, input, processingTimeMs);

  factory SecurityValidationResult.blocked(String reason) =>
      SecurityValidationResult._(false, reason, null, null);
}

class ResponseFilterResult {
  final bool isBlocked;
  final String? originalResponse;
  final String? filteredResponse;
  final List<String> modifications;
  final String? reason;
  final int? processingTimeMs;

  ResponseFilterResult._(this.isBlocked, this.originalResponse, this.filteredResponse, 
                        this.modifications, this.reason, this.processingTimeMs);

  factory ResponseFilterResult.processed({
    required String originalResponse,
    required String filteredResponse,
    required List<String> modifications,
    int? processingTimeMs,
  }) => ResponseFilterResult._(false, originalResponse, filteredResponse, modifications, null, processingTimeMs);

  factory ResponseFilterResult.blocked({
    required String reason,
    required String originalResponse,
  }) => ResponseFilterResult._(true, originalResponse, null, [], reason, null);
}

// Helper classes
class InjectionDetectionResult {
  final bool isBlocked;
  final double confidence;
  final List<String> detectedPatterns;
  final String? reason;

  InjectionDetectionResult({
    required this.isBlocked,
    required this.confidence,
    required this.detectedPatterns,
    this.reason,
  });
}

class MedicalDetectionResult {
  final bool isBlocked;
  final List<String> detectedPatterns;
  final double authorityScore;
  final String? reason;

  MedicalDetectionResult({
    required this.isBlocked,
    required this.detectedPatterns,
    required this.authorityScore,
    this.reason,
  });
}

class LanguageBypassResult {
  final double riskLevel;
  LanguageBypassResult({required this.riskLevel});
}

class ProgressionDetectionResult {
  final double riskLevel;
  ProgressionDetectionResult({required this.riskLevel});
}

class MedicalContentAnalysis {
  final bool hasMedicalContent;
  final bool isDangerous;
  final bool hasAuthorityClaimss;
  final MedicalSeverity severity;
  final bool requiresDisclaimer;
  final bool requiresReferral;

  MedicalContentAnalysis({
    required this.hasMedicalContent,
    required this.isDangerous,
    required this.hasAuthorityClaimss,
    required this.severity,
    required this.requiresDisclaimer,
    required this.requiresReferral,
  });
}

class SecurityEvent {
  final DateTime timestamp;
  final String eventType;
  final String? userInput;
  final String? aiResponse;
  final String? filteredResponse;
  final String action;
  final String? reason;
  final List<String>? detectedPatterns;
  final int? processingTimeMs;

  SecurityEvent({
    required this.timestamp,
    required this.eventType,
    this.userInput,
    this.aiResponse,
    this.filteredResponse,
    required this.action,
    this.reason,
    this.detectedPatterns,
    this.processingTimeMs,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'eventType': eventType,
    'userInput': userInput?.substring(0, min(100, userInput?.length ?? 0)),
    'action': action,
    'reason': reason,
    'detectedPatterns': detectedPatterns,
    'processingTimeMs': processingTimeMs,
  };
}

class SecurityMetrics {
  final int totalRequests;
  final int blockedAttacks;
  final double attackPreventionRate;
  final int averageProcessingTimeMs;
  final List<SecurityEvent> recentEvents;
  final DateTime lastUpdated;

  SecurityMetrics({
    required this.totalRequests,
    required this.blockedAttacks,
    required this.attackPreventionRate,
    required this.averageProcessingTimeMs,
    required this.recentEvents,
    required this.lastUpdated,
  });
}

enum MedicalSeverity { none, low, medium, high, critical }