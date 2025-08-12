import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/firebase/firebase_avatar.dart';
import '../../models/store/currency_system.dart';
import '../../models/assets/cached_asset.dart';
import '../firebase/firebase_avatar_service.dart';
import '../store/currency_service.dart';
import '../assets/asset_cache_service.dart';

final log = Logger('AvatarPurchaseService');

/// Enhanced avatar purchase service with asset downloading and caching
class AvatarPurchaseService {
  final FirebaseAvatarService _avatarService;
  final CurrencyService _currencyService;
  final AssetCacheService _assetCacheService;

  // Stream controllers for purchase progress
  final StreamController<PurchaseProgress> _purchaseProgressController = StreamController.broadcast();
  final StreamController<AssetDownloadProgress> _downloadProgressController = StreamController.broadcast();

  /// Stream of purchase progress updates
  Stream<PurchaseProgress> get purchaseProgressStream => _purchaseProgressController.stream;

  /// Stream of asset download progress updates
  Stream<AssetDownloadProgress> get downloadProgressStream => _downloadProgressController.stream;

  AvatarPurchaseService({
    required FirebaseAvatarService avatarService,
    required CurrencyService currencyService,
    required AssetCacheService assetCacheService,
  }) : _avatarService = avatarService,
       _currencyService = currencyService,
       _assetCacheService = assetCacheService;

  /// Purchase avatar with complete flow: currency check → purchase → asset download
  Future<PurchaseResult> purchaseAvatar(String avatarId, {Map<String, dynamic>? metadata}) async {
    log.info('🛒 Starting avatar purchase: $avatarId');
    
    try {
      // Step 1: Validate avatar exists
      _emitProgress(PurchaseStep.validating, 'Validating avatar...');
      
      final avatar = _avatarService.getAvatar(avatarId);
      if (avatar == null) {
        throw PurchaseException('Avatar not found: $avatarId');
      }

      // Step 2: Check currency requirements
      _emitProgress(PurchaseStep.checkingCurrency, 'Checking currency...');
      
      final price = StorePricing.getAvatarPrice(avatarId);
      final userCurrency = _currencyService.getCurrentCurrency();
      
      if (userCurrency == null) {
        throw PurchaseException('User currency not loaded');
      }

      if (price.isNotEmpty && !userCurrency.canAffordMixed(price)) {
        return PurchaseResult.insufficientFunds(price, userCurrency.balances);
      }

      // Step 3: Check if already owned
      _emitProgress(PurchaseStep.checkingOwnership, 'Checking ownership...');
      
      if (_avatarService.doesUserOwnAvatar(avatarId)) {
        log.warning('⚠️ User already owns avatar: $avatarId');
        return PurchaseResult.alreadyOwned();
      }

      // Step 4: Process currency payment
      if (price.isNotEmpty) {
        _emitProgress(PurchaseStep.processingPayment, 'Processing payment...');
        
        final paymentSuccess = await _currencyService.purchaseAvatar(avatarId);
        if (!paymentSuccess) {
          throw PurchaseException('Payment processing failed');
        }
        
        log.info('✅ Payment processed for avatar: $avatarId');
      }

      // Step 5: Purchase avatar in Firebase
      _emitProgress(PurchaseStep.purchasingAvatar, 'Purchasing avatar...');
      
      final purchaseSuccess = await _avatarService.purchaseAvatar(
        avatarId,
        metadata: {
          'purchase_method': 'in_app',
          'price_paid': price,
          'timestamp': DateTime.now().toIso8601String(),
          ...?metadata,
        },
      );

      if (!purchaseSuccess) {
        throw PurchaseException('Avatar purchase failed in Firebase');
      }

      // Step 6: Download assets
      _emitProgress(PurchaseStep.downloadingAssets, 'Downloading avatar assets...');
      
      final assetUrls = await _getAvatarAssetUrls(avatar);
      await _downloadAvatarAssets(avatarId, assetUrls);

      // Step 7: Complete purchase
      _emitProgress(PurchaseStep.completed, 'Purchase completed!');
      
      log.info('🎉 Avatar purchase completed successfully: $avatarId');
      
      return PurchaseResult.success(avatar, price);

    } catch (e, stackTrace) {
      log.severe('❌ Avatar purchase failed: $e', e, stackTrace);
      _emitProgress(PurchaseStep.error, 'Purchase failed: ${e.toString()}');
      
      if (e is PurchaseException) {
        return PurchaseResult.error(e.message, e.code);
      } else {
        return PurchaseResult.error('Purchase failed: ${e.toString()}', 'unknown_error');
      }
    }
  }

  /// Get asset URLs for avatar
  Future<AvatarAssetUrls> _getAvatarAssetUrls(FirebaseAvatar avatar) async {
    // Get URLs from Firebase Storage or CDN
    final previewUrl = 'https://cdn.solarvita.app/avatars/previews/${avatar.avatarId}_preview.webp';
    final riveUrl = 'https://cdn.solarvita.app/avatars/animations/${avatar.avatarId}.riv';
    
    return AvatarAssetUrls(
      previewUrl: previewUrl,
      riveUrl: riveUrl,
      customizationUrl: avatar.customProperties['hasCustomization'] == true
          ? 'https://cdn.solarvita.app/avatars/customizations/${avatar.avatarId}.json'
          : null,
    );
  }

  /// Download all avatar assets
  Future<void> _downloadAvatarAssets(String avatarId, AvatarAssetUrls urls) async {
    final downloadTasks = <Future<void>>[];
    
    // Download preview image
    downloadTasks.add(_downloadAssetWithProgress(
      avatarId,
      'preview',
      () => _assetCacheService.getAvatarPreview(avatarId, customUrl: urls.previewUrl),
    ));
    
    // Download Rive animation
    downloadTasks.add(_downloadAssetWithProgress(
      avatarId,
      'animation',
      () => _assetCacheService.getRiveAnimation(avatarId, customUrl: urls.riveUrl, forceDownload: true),
    ));
    
    // Download customization data if available
    if (urls.customizationUrl != null) {
      downloadTasks.add(_downloadAssetWithProgress(
        avatarId,
        'customization',
        () => _downloadCustomizationData(avatarId, urls.customizationUrl!),
      ));
    }

    // Wait for all downloads to complete
    await Future.wait(downloadTasks);
    log.info('✅ All assets downloaded for avatar: $avatarId');
  }

  /// Download asset with progress tracking
  Future<void> _downloadAssetWithProgress(
    String avatarId,
    String assetType,
    Future<CachedAsset> Function() downloadFunction,
  ) async {
    final assetId = '${avatarId}_$assetType';
    
    try {
      // Emit download started
      _downloadProgressController.add(AssetDownloadProgress.started(assetId));
      
      // Perform download
      final asset = await downloadFunction();
      
      // Emit download completed
      _downloadProgressController.add(AssetDownloadProgress.completed(assetId, asset.sizeBytes));
      
    } catch (e) {
      _downloadProgressController.add(AssetDownloadProgress.error(assetId, e.toString()));
      rethrow;
    }
  }

  /// Download customization data
  Future<CachedAsset> _downloadCustomizationData(String avatarId, String url) async {
    try {
      log.info('📄 Downloading customization data for: $avatarId');
      
      // Download the JSON file
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        // Parse JSON to validate it's valid customization data
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Validate required fields
        final requiredFields = ['version', 'avatarId', 'customizationOptions'];
        for (final field in requiredFields) {
          if (!jsonData.containsKey(field)) {
            log.warning('⚠️ Invalid customization data: missing $field');
            throw Exception('Invalid customization data format');
          }
        }
        
        // Save to local cache
        final customizationDir = Directory('${await getApplicationDocumentsDirectory().then((d) => d.path)}/avatar_cache/customizations');
        if (!await customizationDir.exists()) {
          await customizationDir.create(recursive: true);
        }
        
        final localPath = '${customizationDir.path}/${avatarId}_customization.json';
        final localFile = File(localPath);
        await localFile.writeAsString(response.body);
        
        log.info('✅ Customization data downloaded and cached: $avatarId');
        
        return CachedAsset(
          id: '${avatarId}_customization',
          type: AssetType.customization,
          data: Uint8List.fromList(response.bodyBytes),
          localPath: localPath,
          isLocal: true,
          downloadTime: DateTime.now(),
          url: url,
          metadata: {
            'avatarId': avatarId,
            'customizationVersion': jsonData['version'],
            'optionCount': (jsonData['customizationOptions'] as List?)?.length ?? 0,
          },
        );
      } else {
        log.warning('⚠️ Failed to download customization data: HTTP ${response.statusCode}');
        throw Exception('HTTP ${response.statusCode}: Failed to download customization data');
      }
    } catch (e, stackTrace) {
      log.severe('❌ Error downloading customization data for $avatarId: $e', e, stackTrace);
      
      // Return empty customization data as fallback
      return CachedAsset(
        id: '${avatarId}_customization',
        type: AssetType.customization,
        data: Uint8List.fromList('{"version": 1, "avatarId": "$avatarId", "customizationOptions": []}'.codeUnits),
        localPath: '',
        isLocal: false,
        downloadTime: DateTime.now(),
        metadata: {
          'avatarId': avatarId,
          'error': e.toString(),
          'fallback': true,
        },
      );
    }
  }

  /// Emit purchase progress update
  void _emitProgress(PurchaseStep step, String message) {
    final progress = PurchaseProgress(
      step: step,
      message: message,
      timestamp: DateTime.now(),
    );
    _purchaseProgressController.add(progress);
  }

  /// Validate purchase prerequisites
  Future<ValidationResult> validatePurchase(String avatarId) async {
    try {
      final avatar = _avatarService.getAvatar(avatarId);
      if (avatar == null) {
        return ValidationResult.invalid('Avatar not found');
      }

      if (_avatarService.doesUserOwnAvatar(avatarId)) {
        return ValidationResult.invalid('Avatar already owned');
      }

      final price = StorePricing.getAvatarPrice(avatarId);
      final userCurrency = _currencyService.getCurrentCurrency();
      
      if (userCurrency == null) {
        return ValidationResult.invalid('Currency not loaded');
      }

      if (price.isNotEmpty && !userCurrency.canAffordMixed(price)) {
        return ValidationResult.invalid('Insufficient currency');
      }

      return ValidationResult.valid();
    } catch (e) {
      return ValidationResult.invalid('Validation failed: $e');
    }
  }

  /// Retry failed asset downloads
  Future<void> retryAssetDownload(String avatarId) async {
    log.info('🔄 Retrying asset download for: $avatarId');
    
    try {
      final avatar = _avatarService.getAvatar(avatarId);
      if (avatar == null) {
        throw Exception('Avatar not found');
      }

      final assetUrls = await _getAvatarAssetUrls(avatar);
      await _downloadAvatarAssets(avatarId, assetUrls);
      
    } catch (e) {
      log.severe('❌ Asset download retry failed: $e');
      rethrow;
    }
  }

  /// Dispose service
  void dispose() {
    _purchaseProgressController.close();
    _downloadProgressController.close();
    log.info('🧹 Avatar Purchase Service disposed');
  }
}

/// Purchase progress information
class PurchaseProgress {
  final PurchaseStep step;
  final String message;
  final DateTime timestamp;

  const PurchaseProgress({
    required this.step,
    required this.message,
    required this.timestamp,
  });

  double get progress {
    switch (step) {
      case PurchaseStep.validating:
        return 0.1;
      case PurchaseStep.checkingCurrency:
        return 0.2;
      case PurchaseStep.checkingOwnership:
        return 0.3;
      case PurchaseStep.processingPayment:
        return 0.5;
      case PurchaseStep.purchasingAvatar:
        return 0.7;
      case PurchaseStep.downloadingAssets:
        return 0.9;
      case PurchaseStep.completed:
        return 1.0;
      case PurchaseStep.error:
        return 0.0;
    }
  }

  @override
  String toString() => 'PurchaseProgress{step: $step, message: $message}';
}

/// Purchase steps
enum PurchaseStep {
  validating,
  checkingCurrency,
  checkingOwnership,
  processingPayment,
  purchasingAvatar,
  downloadingAssets,
  completed,
  error,
}

/// Purchase result
class PurchaseResult {
  final bool success;
  final String? error;
  final String? errorCode;
  final FirebaseAvatar? avatar;
  final Map<CurrencyType, int>? price;
  final Map<String, dynamic>? metadata;

  const PurchaseResult._({
    required this.success,
    this.error,
    this.errorCode,
    this.avatar,
    this.price,
    this.metadata,
  });

  factory PurchaseResult.success(FirebaseAvatar avatar, Map<CurrencyType, int> price) {
    return PurchaseResult._(
      success: true,
      avatar: avatar,
      price: price,
    );
  }

  factory PurchaseResult.error(String error, String errorCode) {
    return PurchaseResult._(
      success: false,
      error: error,
      errorCode: errorCode,
    );
  }

  factory PurchaseResult.insufficientFunds(
    Map<CurrencyType, int> required,
    Map<CurrencyType, int> available,
  ) {
    return PurchaseResult._(
      success: false,
      error: 'Insufficient funds',
      errorCode: 'insufficient_funds',
      metadata: {
        'required': required,
        'available': available,
      },
    );
  }

  factory PurchaseResult.alreadyOwned() {
    return PurchaseResult._(
      success: false,
      error: 'Avatar already owned',
      errorCode: 'already_owned',
    );
  }

  @override
  String toString() => 'PurchaseResult{success: $success, error: $error}';
}

/// Validation result
class ValidationResult {
  final bool isValid;
  final String? error;

  const ValidationResult._(this.isValid, this.error);

  factory ValidationResult.valid() => const ValidationResult._(true, null);
  factory ValidationResult.invalid(String error) => ValidationResult._(false, error);

  @override
  String toString() => 'ValidationResult{valid: $isValid, error: $error}';
}

/// Avatar asset URLs
class AvatarAssetUrls {
  final String previewUrl;
  final String riveUrl;
  final String? customizationUrl;

  const AvatarAssetUrls({
    required this.previewUrl,
    required this.riveUrl,
    this.customizationUrl,
  });

  @override
  String toString() => 'AvatarAssetUrls{preview: $previewUrl, rive: $riveUrl}';
}

/// Purchase exception
class PurchaseException implements Exception {
  final String message;
  final String code;

  const PurchaseException(this.message, [this.code = 'purchase_error']);

  @override
  String toString() => 'PurchaseException: $message ($code)';
}