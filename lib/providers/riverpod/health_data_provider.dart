import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../models/health/health_data.dart';
import '../../services/database/health_data_service.dart';
import 'user_progress_provider.dart';

part 'health_data_provider.g.dart';

// Health data service provider
@riverpod
HealthDataService healthDataService(Ref ref) {
  return HealthDataService();
}

// Health permissions status provider
@riverpod
class HealthPermissionsNotifier extends _$HealthPermissionsNotifier {
  @override
  Future<HealthPermissionStatus> build() async {
    final service = ref.read(healthDataServiceProvider);
    return await service.checkPermissionStatus();
  }

  Future<void> requestPermissions() async {
    state = const AsyncValue.loading();
    final service = ref.read(healthDataServiceProvider);

    try {
      final permissionStatus = await service.requestPermissions();
      state = AsyncValue.data(permissionStatus);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> checkPermissions() async {
    state = const AsyncValue.loading();
    final service = ref.read(healthDataServiceProvider);

    try {
      final permissionStatus = await service.checkPermissionStatus();
      state = AsyncValue.data(permissionStatus);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// Health data provider
@riverpod
class HealthDataNotifier extends _$HealthDataNotifier {
  @override
  Future<HealthData> build() async {
    final service = ref.read(healthDataServiceProvider);
    final healthData = await service.fetchHealthData();

    // Auto-trigger strike calculation when health data is first loaded
    try {
      final userProgressNotifier = ref.read(
        userProgressNotifierProvider.notifier,
      );
      await userProgressNotifier.updateProgress(healthData);
    } catch (e) {
      // Don't fail health data loading if strike calculation fails
      // But ensure the error is properly handled
      final syncNotifier = ref.read(healthSyncStatusNotifierProvider.notifier);
      syncNotifier.setSyncError('Strike calculation failed: $e');
    }

    // Start real-time health data watcher for immediate updates
    startRealTimeHealthDataWatcher();

    return healthData;
  }

  Future<void> syncHealthData() async {
    final syncNotifier = ref.read(healthSyncStatusNotifierProvider.notifier);
    syncNotifier.setSyncing();

    state = const AsyncValue.loading();
    final service = ref.read(healthDataServiceProvider);

    try {
      final healthData = await service.fetchHealthData();
      state = AsyncValue.data(healthData);

      // Trigger strike calculation with new health data - with retry logic
      final userProgressNotifier = ref.read(
        userProgressNotifierProvider.notifier,
      );
      await _updateProgressWithRetry(userProgressNotifier, healthData);

      syncNotifier.setSyncSuccess();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      syncNotifier.setSyncError('Health data sync failed: $e');
    }
  }

  Future<void> _updateProgressWithRetry(
    userProgressNotifier,
    HealthData healthData,
  ) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        await userProgressNotifier.updateProgress(healthData);

        // Cache health data after successful strike calculation
        final service = ref.read(healthDataServiceProvider);
        await service.fetchHealthData(); // This will cache the data

        return; // Success - exit retry loop
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          // Final retry failed - set error status
          final syncNotifier = ref.read(
            healthSyncStatusNotifierProvider.notifier,
          );
          syncNotifier.setSyncError(
            'Strike calculation failed after $maxRetries attempts: $e',
          );
          rethrow;
        }
        // Wait before retry with exponential backoff
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }
  }

  Future<void> refreshHealthData() async {
    // Invalidate and rebuild the provider
    ref.invalidateSelf();

    // Also trigger health data sync which will update strikes
    await syncHealthData();
  }

  // Real-time health data watcher with immediate strike updates
  void startRealTimeHealthDataWatcher() async {
    // Start immediate sync if health data changes
    Timer.periodic(const Duration(minutes: 1), (_) async {
      final currentHealthData = state.value;
      if (currentHealthData != null) {
        try {
          final service = ref.read(healthDataServiceProvider);
          final newHealthData = await service.fetchHealthData();

          // Check if health data has actually changed
          if (_hasHealthDataChanged(currentHealthData, newHealthData)) {
            state = AsyncValue.data(newHealthData);

            // Immediately trigger strike calculation for real-time updates
            final userProgressNotifier = ref.read(
              userProgressNotifierProvider.notifier,
            );
            await _updateProgressWithRetry(userProgressNotifier, newHealthData);

            final syncNotifier = ref.read(
              healthSyncStatusNotifierProvider.notifier,
            );
            syncNotifier.setSyncSuccess();
          }
        } catch (e) {
          // Don't update state on error, just log it
          final syncNotifier = ref.read(
            healthSyncStatusNotifierProvider.notifier,
          );
          syncNotifier.setSyncError('Real-time sync failed: $e');
        }
      }
    });
  }

  bool _hasHealthDataChanged(HealthData current, HealthData newData) {
    return current.steps != newData.steps ||
        current.activeMinutes != newData.activeMinutes ||
        current.caloriesBurned != newData.caloriesBurned ||
        current.waterIntake != newData.waterIntake ||
        current.sleepHours != newData.sleepHours ||
        current.heartRate != newData.heartRate;
  }
}

// Last sync time provider
@riverpod
Future<DateTime?> lastSyncTime(Ref ref) async {
  final service = ref.read(healthDataServiceProvider);
  return await service.getLastSyncTime();
}

// Health app installation status provider
@riverpod
Future<bool> healthAppInstalled(Ref ref) async {
  final service = ref.read(healthDataServiceProvider);
  return await service.isHealthAppInstalled();
}

// Convenience providers for specific health metrics
@riverpod
int dailySteps(Ref ref) {
  final healthDataAsync = ref.watch(healthDataNotifierProvider);
  return healthDataAsync.value?.steps ?? 0;
}

@riverpod
int activeMinutes(Ref ref) {
  final healthDataAsync = ref.watch(healthDataNotifierProvider);
  return healthDataAsync.value?.activeMinutes ?? 0;
}

@riverpod
int caloriesBurned(Ref ref) {
  final healthDataAsync = ref.watch(healthDataNotifierProvider);
  return healthDataAsync.value?.caloriesBurned ?? 0;
}

@riverpod
double sleepHours(Ref ref) {
  final healthDataAsync = ref.watch(healthDataNotifierProvider);
  return healthDataAsync.value?.sleepHours ?? 0.0;
}

@riverpod
double heartRate(Ref ref) {
  final healthDataAsync = ref.watch(healthDataNotifierProvider);
  return healthDataAsync.value?.heartRate ?? 0.0;
}

@riverpod
double healthWaterIntake(Ref ref) {
  final healthDataAsync = ref.watch(healthDataNotifierProvider);
  return healthDataAsync.value?.waterIntake ?? 0.0;
}

@riverpod
bool isHealthDataAvailable(Ref ref) {
  final healthDataAsync = ref.watch(healthDataNotifierProvider);
  return healthDataAsync.value?.isDataAvailable ?? false;
}

// Health data sync status provider
@riverpod
class HealthSyncStatusNotifier extends _$HealthSyncStatusNotifier {
  @override
  HealthSyncStatus build() {
    return const HealthSyncStatus.idle();
  }

  void setSyncing() {
    state = const HealthSyncStatus.syncing();
  }

  void setSyncSuccess() {
    state = const HealthSyncStatus.success();
  }

  void setSyncError(String error) {
    state = HealthSyncStatus.error(error);
  }

  void resetStatus() {
    state = const HealthSyncStatus.idle();
  }
}

// Health sync status model
sealed class HealthSyncStatus {
  const HealthSyncStatus();

  const factory HealthSyncStatus.idle() = _IdleStatus;
  const factory HealthSyncStatus.syncing() = _SyncingStatus;
  const factory HealthSyncStatus.success() = _SuccessStatus;
  const factory HealthSyncStatus.error(String message) = _ErrorStatus;
}

class _IdleStatus extends HealthSyncStatus {
  const _IdleStatus();
}

class _SyncingStatus extends HealthSyncStatus {
  const _SyncingStatus();
}

class _SuccessStatus extends HealthSyncStatus {
  const _SuccessStatus();
}

class _ErrorStatus extends HealthSyncStatus {
  final String message;
  const _ErrorStatus(this.message);
}
