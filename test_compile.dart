// test_compile.dart - Simple compilation test

// ignore_for_file: avoid_print

import 'lib/services/ai/validation/security_test_validator.dart';
import 'lib/services/ai/validation/user_study_framework.dart';
import 'lib/services/ai/validation/user_study_models.dart';
import 'lib/services/ai/validation/test_runner.dart';

void main() {
  print('✅ All validation framework files compile successfully!');
  
  // Test basic instantiation
  final validator = SecurityTestValidator();
  final userStudy = UserStudyFramework();
  final testRunner = DissertationTestRunner();
  
  print('🎯 Framework components initialized:');
  print('  - SecurityTestValidator: ${validator.runtimeType}');
  print('  - UserStudyFramework: ${userStudy.runtimeType}');
  print('  - DissertationTestRunner: ${testRunner.runtimeType}');
  print('');
  print('📋 Ready to run validation tests!');
  print('Usage: dart run_validation.dart all');
}