import 'package:rive/rive.dart' as rive;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// Migration helper for Rive 0.14.0+ compatibility
/// 
/// This class provides a compatibility layer that works with both
/// Rive 0.13.x and 0.14.x APIs. When you're ready to migrate to 0.14.0+:
/// 
/// 1. Update pubspec.yaml: rive: ^0.14.0
/// 2. Add RiveNative.init() to main.dart
/// 3. Set useNewRiveApi = true
/// 4. Test thoroughly
class RiveMigrationHelper {
  // TODO: Set this to true when migrating to Rive 0.14.0+
  static const bool useNewRiveApi = false;
  
  /// Load a Rive file from assets with API compatibility
  static Future<rive.RiveFile> loadRiveFile(String assetPath) async {
    if (useNewRiveApi) {
      // For Rive 0.14.0+ - when available, uncomment and update imports
      // return await rive.File.asset(assetPath);
      throw UnsupportedError('Rive 0.14.0+ API not yet available');
    } else {
      // For Rive 0.13.x
      return rive.RiveFile.asset(assetPath);
    }
  }
  
  /// Load a Rive file from bytes with API compatibility
  static rive.RiveFile loadRiveFileFromBytes(ByteData data) {
    if (useNewRiveApi) {
      // For Rive 0.14.0+ - when available, uncomment and update imports
      // return rive.File.decode(data);
      throw UnsupportedError('Rive 0.14.0+ API not yet available');
    } else {
      // For Rive 0.13.x
      return rive.RiveFile.import(data);
    }
  }
  
  /// Get the main/default artboard with API compatibility
  static rive.Artboard getMainArtboard(rive.RiveFile riveFile) {
    if (useNewRiveApi) {
      // For Rive 0.14.0+ - when available, uncomment and update imports
      // return riveFile.defaultArtboard();
      throw UnsupportedError('Rive 0.14.0+ API not yet available');
    } else {
      // For Rive 0.13.x
      return riveFile.mainArtboard;
    }
  }
  
  /// Create a Rive widget with API compatibility
  static Widget createRiveWidget({
    required rive.Artboard artboard,
    BoxFit fit = BoxFit.contain,
  }) {
    if (useNewRiveApi) {
      // For Rive 0.14.0+ - when available, uncomment and update imports
      // return rive.RiveWidget(artboard: artboard, fit: fit);
      throw UnsupportedError('Rive 0.14.0+ API not yet available');
    } else {
      // For Rive 0.13.x
      return rive.Rive(
        artboard: artboard,
        fit: fit,
      );
    }
  }
  
  /// Initialize Rive Native (only needed for 0.14.0+)
  static Future<void> initializeRive() async {
    if (useNewRiveApi) {
      // For Rive 0.14.0+ - when available, uncomment and update imports
      // await rive.RiveNative.init();
      throw UnsupportedError('Rive 0.14.0+ API not yet available');
    }
    // No initialization needed for 0.13.x
  }
}

// Re-export common types for convenience
typedef RiveFile = rive.RiveFile;
typedef Artboard = rive.Artboard;
typedef StateMachineController = rive.StateMachineController;
typedef SMITrigger = rive.SMITrigger;
typedef SMINumber = rive.SMINumber;
typedef SMIBool = rive.SMIBool;