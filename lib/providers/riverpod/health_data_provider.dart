import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../models/health_data.dart';
import '../../services/health_data_service.dart';

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
    return await service.fetchHealthData();
  }

  Future<void> syncHealthData() async {
    state = const AsyncValue.loading();
    final service = ref.read(healthDataServiceProvider);
    
    try {
      final healthData = await service.fetchHealthData();
      state = AsyncValue.data(healthData);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> refreshHealthData() async {
    // Invalidate and rebuild the provider
    ref.invalidateSelf();
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