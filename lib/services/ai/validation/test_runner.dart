// lib/services/ai/validation/test_runner.dart

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'security_test_validator.dart';

/// Automated test runner for dissertation validation
class DissertationTestRunner {
  final SecurityTestValidator _validator = SecurityTestValidator();
  
  /// Run all validation tests and generate academic report
  Future<void> runCompleteValidation() async {
    print('🎯 Starting Comprehensive Security Validation');
    print('=' * 60);
    
    try {
      print('📊 Generating Academic Validation Report...');
      final report = await _validator.generateAcademicValidationReport();
      
      // Save results to file
      final file = File('dissertation_validation_results.json');
      await file.writeAsString(JsonEncoder.withIndent('  ').convert(report));
      
      print('✅ Validation Complete!');
      print('📄 Results saved to: dissertation_validation_results.json');
      
      // Print summary
      _printValidationSummary(report);
      
    } catch (e) {
      print('❌ Validation Error: $e');
    }
  }
  
  /// Run individual test category
  Future<void> runSpecificTest(String testType) async {
    switch (testType.toLowerCase()) {
      case 'dpi':
        print('🛡️ Testing Direct Prompt Injection Detection...');
        final result = await _validator.validateDPIDetection();
        _printTestResult(result);
        break;
        
      case 'mai':
        print('👨‍⚕️ Testing Medical Authority Impersonation Detection...');
        final result = await _validator.validateMAIDetection();
        _printTestResult(result);
        break;
        
      case 'icm':
        print('🎭 Testing Indirect Context Manipulation Detection...');
        final result = await _validator.validateICMDetection();
        _printTestResult(result);
        break;
        
      case 'performance':
        print('⚡ Testing Performance Impact...');
        final result = await _validator.validatePerformanceImpact();
        _printPerformanceResult(result);
        break;
        
      default:
        print('❌ Unknown test type: $testType');
        print('Available tests: dpi, mai, icm, performance');
    }
  }
  
  void _printValidationSummary(Map<String, dynamic> report) {
    print('\\n📈 VALIDATION SUMMARY');
    print('=' * 40);
    
    final security = report['security_validation'] as Map<String, dynamic>;
    final performance = report['performance_validation'] as Map<String, dynamic>;
    final overall = report['overall_assessment'] as Map<String, dynamic>;
    
    print('\\n🛡️ SECURITY EFFECTIVENESS:');
    for (final entry in security.entries) {
      final testData = entry.value as Map<String, dynamic>;
      final category = entry.key.replaceAll('_', ' ').toUpperCase();
      print('  $category:');
      print('    Detection Rate: ${testData['detection_rate_percent']}%');
      print('    False Positives: ${testData['false_positive_rate_percent']}%');
      print('    Processing Time: ${testData['mean_processing_time_ms']}ms ± ${testData['confidence_interval_95']}');
      print('    Status: ${testData['validation_status']}\\n');
    }
    
    print('⚡ PERFORMANCE IMPACT:');
    print('  Baseline: ${performance['baseline_avg_ms']}ms');
    print('  With Security: ${performance['security_avg_ms']}ms');
    print('  Overhead: ${performance['overhead_ms']}ms (${performance['overhead_percent']}%)');
    print('  Status: ${performance['validation_status']}\\n');
    
    print('🎯 OVERALL ASSESSMENT:');
    print('  Framework Effectiveness: ${overall['framework_effectiveness']}');
    print('  Academic Rigor: ${overall['academic_rigor']}');
    print('  Statistical Validity: ${overall['statistical_validity']}');
    print('  Reproducibility: ${overall['reproducibility']}\\n');
  }
  
  void _printTestResult(ValidationResults result) {
    print('\\n📊 TEST RESULTS: ${result.testCategory}');
    print('-' * 40);
    print('Sample Size: ${result.totalTests}');
    print('Detection Rate: ${(result.detectionRate * 100).toStringAsFixed(1)}%');
    print('False Positive Rate: ${(result.falsePositiveRate * 100).toStringAsFixed(1)}%');
    print('Avg Processing Time: ${result.averageProcessingTime.toStringAsFixed(1)}ms');
    print('Standard Deviation: ${result.standardDeviation.toStringAsFixed(1)}ms');
    print('95% Confidence Interval: ±${result.confidenceInterval.toStringAsFixed(1)}ms');
    print('Statistical Significance: ${result.statisticallySignificant ? "p < 0.05" : "p ≥ 0.05"}');
    print('Validation Status: ${result.validationStatus}\\n');
  }
  
  void _printPerformanceResult(Map<String, dynamic> result) {
    print('\\n⚡ PERFORMANCE IMPACT ANALYSIS');
    print('-' * 40);
    print('Sample Size: ${result['sample_size']}');
    print('Baseline Average: ${result['baseline_avg_ms']}ms');
    print('Security Average: ${result['security_avg_ms']}ms');
    print('Processing Overhead: ${result['overhead_ms']}ms');
    print('Percentage Impact: ${result['overhead_percent']}%');
    print('Validation Status: ${result['validation_status']}\\n');
  }
  
  /// Generate LaTeX table for dissertation
  Future<void> generateLatexTables() async {
    print('📝 Generating LaTeX tables for dissertation...');
    
    final report = await _validator.generateAcademicValidationReport();
    final security = report['security_validation'] as Map<String, dynamic>;
    
    var latexContent = '''
% Security Validation Results Table
\\begin{table}[htbp]
\\centering
\\caption{Security Framework Validation Results}
\\label{tab:security_validation}
\\begin{tabular}{|l|c|c|c|c|}
\\hline
\\textbf{Attack Vector} & \\textbf{Detection Rate} & \\textbf{False Positive Rate} & \\textbf{Processing Time (ms)} & \\textbf{Status} \\\\
\\hline
''';
    
    for (final entry in security.entries) {
      final data = entry.value as Map<String, dynamic>;
      final name = entry.key.replaceAll('_', ' ');
      final detection = data['detection_rate_percent'];
      final falsePos = data['false_positive_rate_percent'];
      final time = data['mean_processing_time_ms'];
      final status = data['validation_status'];
      
      latexContent += '$name & $detection\\% & $falsePos\\% & $time & $status \\\\\\\\\n';
    }
    
    final performanceData = report['performance_validation'] as Map<String, dynamic>;
    final finalLatex = '''$latexContent
\\hline
\\end{tabular}
\\end{table}

% Performance Impact Table
\\begin{table}[htbp]
\\centering
\\caption{Performance Impact Analysis}
\\label{tab:performance_impact}
\\begin{tabular}{|l|c|}
\\hline
\\textbf{Metric} & \\textbf{Value} \\\\
\\hline
Baseline Response Time & ${performanceData['baseline_avg_ms']}ms \\\\
Security-Enhanced Response Time & ${performanceData['security_avg_ms']}ms \\\\
Processing Overhead & ${performanceData['overhead_ms']}ms \\\\
Percentage Impact & ${performanceData['overhead_percent']}\\% \\\\
\\hline
\\end{tabular}
\\end{table}
''';
    
    final file = File('dissertation_latex_tables.tex');
    await file.writeAsString(finalLatex);
    print('✅ LaTeX tables saved to: dissertation_latex_tables.tex');
  }
}

/// Command-line interface for running tests
Future<void> main(List<String> args) async {
  final runner = DissertationTestRunner();
  
  if (args.isEmpty) {
    print('🎓 SolarVita Security Validation Suite');
    print('Usage:');
    print('  dart test_runner.dart all          - Run complete validation');
    print('  dart test_runner.dart dpi          - Test Direct Prompt Injection');
    print('  dart test_runner.dart mai          - Test Medical Authority Impersonation');
    print('  dart test_runner.dart icm          - Test Indirect Context Manipulation');
    print('  dart test_runner.dart performance  - Test Performance Impact');
    print('  dart test_runner.dart latex        - Generate LaTeX tables');
    return;
  }
  
  switch (args[0].toLowerCase()) {
    case 'all':
      await runner.runCompleteValidation();
      break;
    case 'latex':
      await runner.generateLatexTables();
      break;
    default:
      await runner.runSpecificTest(args[0]);
  }
}