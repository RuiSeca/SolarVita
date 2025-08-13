import 'package:rive/rive.dart' as rive;
import 'package:logging/logging.dart';

final log = Logger('RiveUtils');

/// Utility class for safe Rive operations to prevent RuntimeArtboard casting errors
class RiveUtils {

  /// Load a fresh artboard from asset to completely avoid RuntimeArtboard issues
  static Future<rive.Artboard?> loadFreshArtboard(String assetPath, String context) async {
    try {
      log.info('🔄 Loading fresh artboard from $assetPath for $context');
      final rivFile = await rive.RiveFile.asset(assetPath);
      final artboard = rivFile.mainArtboard;
      final fresh = artboard.instance();
      log.info('✅ Fresh artboard loaded successfully for $context');
      return fresh;
    } catch (e) {
      log.severe('❌ Failed to load fresh artboard from $assetPath for $context: $e');
      return null;
    }
  }
  
  /// Safely create an artboard instance with enhanced RuntimeArtboard handling
  static rive.Artboard? safeCloneArtboard(rive.Artboard originalArtboard, String context) {
    try {
      // Method 1: Standard instance cloning
      final cloned = originalArtboard.instance();
      log.info('✅ Successfully cloned artboard for $context');
      return cloned;
    } catch (e) {
      log.warning('⚠️ Standard cloning failed for $context: $e');
      
      // Method 2: Check if it's a RuntimeArtboard and handle differently  
      try {
        if (originalArtboard.runtimeType.toString().contains('RuntimeArtboard')) {
          log.info('🔄 Detected RuntimeArtboard, using direct reference for $context');
          // For RuntimeArtboard, don't clone - use direct reference
          return originalArtboard;
        } else {
          // For regular artboards, try instance again
          final cloned = originalArtboard.instance();
          return cloned;
        }
      } catch (fallbackError) {
        log.warning('⚠️ RuntimeArtboard handling failed for $context: $fallbackError');
      }
      
      // Method 3: Last resort - return original
      try {
        log.info('🔄 Using original artboard as last resort for $context');
        return originalArtboard;
      } catch (originalError) {
        log.severe('❌ Original artboard also failed for $context: $originalError');
      }
      
      return null;
    }
  }
  
  /// Safely create a StateMachineController with enhanced error handling
  static rive.StateMachineController? safeCreateStateMachine(
    rive.Artboard artboard, 
    String stateMachineName, 
    String context
  ) {
    try {
      final controller = rive.StateMachineController.fromArtboard(
        artboard,
        stateMachineName,
      );
      
      if (controller != null) {
        log.info('✅ StateMachineController created for $context');
        return controller;
      } else {
        log.warning('⚠️ StateMachineController is null for $context');
        return null;
      }
    } catch (e) {
      log.severe('❌ Error creating StateMachineController for $context: $e');
      return null;
    }
  }
  
  /// Safely fire a trigger input with multiple fallback methods
  static bool safeTriggerAnimation(
    rive.StateMachineController controller, 
    String animationName, 
    String context
  ) {
    try {
      for (final input in controller.inputs) {
        if (input.name.toLowerCase() == animationName.toLowerCase()) {
          return _safeTriggerInput(input, animationName, context);
        }
      }
      
      log.warning('⚠️ Animation trigger not found: $animationName for $context');
      return false;
    } catch (e) {
      log.severe('❌ Error triggering animation $animationName for $context: $e');
      return false;
    }
  }
  
  /// Internal method to safely trigger an input with multiple approaches
  static bool _safeTriggerInput(rive.SMIInput input, String animationName, String context) {
    // Method 1: Direct type check
    try {
      if (input is rive.SMITrigger) {
        input.fire();
        log.info('🎬 Fired animation: $animationName for $context (direct cast)');
        return true;
      }
    } catch (castError) {
      log.warning('⚠️ Direct cast failed for $animationName in $context: $castError');
    }
    
    // Method 2: Runtime type check as fallback
    try {
      if (input.runtimeType.toString().contains('SMITrigger')) {
        (input as dynamic).fire();
        log.info('🎬 Fired animation: $animationName for $context (dynamic cast)');
        return true;
      }
    } catch (dynamicError) {
      log.warning('⚠️ Dynamic cast failed for $animationName in $context: $dynamicError');
    }
    
    // Method 3: Try direct method call
    try {
      if (input.name.toLowerCase() == animationName.toLowerCase()) {
        // Use reflection-like approach
        final dynamic dynInput = input;
        if (dynInput.hasMethod('fire')) {
          dynInput.fire();
          log.info('🎬 Fired animation: $animationName for $context (reflection)');
          return true;
        }
      }
    } catch (reflectionError) {
      log.warning('⚠️ Reflection approach failed for $animationName in $context: $reflectionError');
    }
    
    return false;
  }
  
  /// Safely set a number input
  static bool safeSetNumberInput(
    rive.StateMachineController controller,
    String inputName,
    double value,
    String context
  ) {
    try {
      final input = controller.findInput<double>(inputName);
      if (input is rive.SMINumber) {
        input.value = value;
        log.fine('✅ Set number input $inputName = $value for $context');
        return true;
      } else {
        log.warning('⚠️ Number input $inputName not found for $context');
        return false;
      }
    } catch (e) {
      log.warning('⚠️ Error setting number input $inputName for $context: $e');
      return false;
    }
  }
  
  /// Safely set a boolean input
  static bool safeSetBoolInput(
    rive.StateMachineController controller,
    String inputName,
    bool value,
    String context
  ) {
    try {
      final input = controller.findInput<bool>(inputName);
      if (input is rive.SMIBool) {
        input.value = value;
        log.fine('✅ Set boolean input $inputName = $value for $context');
        return true;
      } else {
        log.warning('⚠️ Boolean input $inputName not found for $context');
        return false;
      }
    } catch (e) {
      log.warning('⚠️ Error setting boolean input $inputName for $context: $e');
      return false;
    }
  }
}

/// Extension to add hasMethod check for dynamic objects
extension DynamicMethodCheck on dynamic {
  bool hasMethod(String methodName) {
    try {
      // Try to see if the method exists by checking the type
      return runtimeType.toString().contains('SMI');
    } catch (e) {
      return false;
    }
  }
}