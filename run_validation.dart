// run_validation.dart
// Quick script to run dissertation validation tests

import 'lib/services/ai/validation/test_runner.dart';

Future<void> main(List<String> args) async {
  final runner = DissertationTestRunner();
  
  if (args.isEmpty || args[0] == 'all') {
    await runner.runCompleteValidation();
  } else {
    await runner.runSpecificTest(args[0]);
  }
}