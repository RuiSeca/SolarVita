import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import '../services/auth_service.dart';

class UserProfileProvider with ChangeNotifier {
  final UserProfileService _userProfileService = UserProfileService();
  final AuthService _authService = AuthService();
  final Logger _logger = Logger('UserProfileProvider');

  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOnboardingComplete {
    final result = _userProfile?.isOnboardingComplete ?? false;
    _logger.info('isOnboardingComplete: $result, userProfile: ${_userProfile?.uid}');
    return result;
  }

  UserProfileProvider() {
    _initializeUserProfile();
  }

  Future<void> _initializeUserProfile() async {
    _authService.authStateChanges.listen((User? user) async {
      if (user != null) {
        // Clear cache for new user sessions
        _userProfileService.clearCache();
        
        // Ensure we're in loading state before starting profile load
        if (!_isLoading) {
          _setLoading(true);
        }
        await _loadUserProfile();
      } else {
        _clearUserProfile();
        // Clear cache when user logs out
        _userProfileService.clearCache();
      }
    });
  }

  Future<void> _loadUserProfile() async {
    // Don't set loading here since it's now set in the caller
    _clearError();

    try {
      final newProfile = await _userProfileService.getOrCreateUserProfile();
      
      // Always update the profile for new users or when profile data changes
      if (_userProfile == null || 
          _userProfile!.uid != newProfile.uid ||
          _userProfile!.lastUpdated != newProfile.lastUpdated ||
          _userProfile!.isOnboardingComplete != newProfile.isOnboardingComplete) {
        _userProfile = newProfile;
        _logger.info('👤 User profile loaded successfully - UID: ${newProfile.uid}, isOnboardingComplete: ${newProfile.isOnboardingComplete}');
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to load user profile: $e');
      _logger.severe('Error loading user profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshUserProfile() async {
    _setLoading(true);
    await _loadUserProfile();
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedProfile = await _userProfileService.updateUserProfile(profile);
      _userProfile = updatedProfile;
      _logger.info('User profile updated successfully');
      notifyListeners();
    } catch (e) {
      _setError('Failed to update user profile: $e');
      _logger.severe('Error updating user profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Method to update the profile in memory without fetching from server
  void setUserProfile(UserProfile profile) {
    _userProfile = profile;
    notifyListeners();
  }

  Future<void> updateWorkoutPreferences(WorkoutPreferences preferences) async {
    if (_userProfile == null) return;

    _setLoading(true);
    _clearError();

    try {
      final updatedProfile = await _userProfileService.updateWorkoutPreferences(
        _userProfile!.uid,
        preferences,
      );
      _userProfile = updatedProfile;
      _logger.info('Workout preferences updated successfully');
      notifyListeners();
    } catch (e) {
      _setError('Failed to update workout preferences: $e');
      _logger.severe('Error updating workout preferences: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateSustainabilityPreferences(SustainabilityPreferences preferences) async {
    if (_userProfile == null) return;

    _setLoading(true);
    _clearError();

    try {
      final updatedProfile = await _userProfileService.updateSustainabilityPreferences(
        _userProfile!.uid,
        preferences,
      );
      _userProfile = updatedProfile;
      _logger.info('Sustainability preferences updated successfully');
      notifyListeners();
    } catch (e) {
      _setError('Failed to update sustainability preferences: $e');
      _logger.severe('Error updating sustainability preferences: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateDiaryPreferences(DiaryPreferences preferences) async {
    if (_userProfile == null) return;

    _setLoading(true);
    _clearError();

    try {
      final updatedProfile = await _userProfileService.updateDiaryPreferences(
        _userProfile!.uid,
        preferences,
      );
      _userProfile = updatedProfile;
      _logger.info('Diary preferences updated successfully');
      notifyListeners();
    } catch (e) {
      _setError('Failed to update diary preferences: $e');
      _logger.severe('Error updating diary preferences: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> completeOnboarding() async {
    if (_userProfile == null) return;

    _setLoading(true);
    _clearError();

    try {
      final updatedProfile = await _userProfileService.completeOnboarding(_userProfile!.uid);
      _userProfile = updatedProfile;
      _logger.info('Onboarding completed successfully');
      notifyListeners();
    } catch (e) {
      _setError('Failed to complete onboarding: $e');
      _logger.severe('Error completing onboarding: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfileField(String field, dynamic value) async {
    if (_userProfile == null) return;

    _setLoading(true);
    _clearError();

    try {
      await _userProfileService.updateProfileField(_userProfile!.uid, field, value);
      await _loadUserProfile();
      _logger.info('Profile field $field updated successfully');
    } catch (e) {
      _setError('Failed to update profile field: $e');
      _logger.severe('Error updating profile field: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateAdditionalData(Map<String, dynamic> data) async {
    if (_userProfile == null) return;

    _setLoading(true);
    _clearError();

    try {
      await _userProfileService.updateAdditionalData(_userProfile!.uid, data);
      await _loadUserProfile();
      _logger.info('Additional data updated successfully');
    } catch (e) {
      _setError('Failed to update additional data: $e');
      _logger.severe('Error updating additional data: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteUserProfile() async {
    if (_userProfile == null) return;

    _setLoading(true);
    _clearError();

    try {
      await _userProfileService.deleteUserProfile(_userProfile!.uid);
      _clearUserProfile();
      _logger.info('User profile deleted successfully');
    } catch (e) {
      _setError('Failed to delete user profile: $e');
      _logger.severe('Error deleting user profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _logger.info('🔄 Setting loading state to: $loading (was: $_isLoading)');
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void _clearUserProfile() {
    _userProfile = null;
    _clearError();
    notifyListeners();
  }

  Stream<UserProfile?> get userProfileStream {
    return _userProfileService.getCurrentUserProfileStream();
  }

  WorkoutPreferences? get workoutPreferences => _userProfile?.workoutPreferences;
  SustainabilityPreferences? get sustainabilityPreferences => _userProfile?.sustainabilityPreferences;
  DiaryPreferences? get diaryPreferences => _userProfile?.diaryPreferences;
  
  String? get displayName => _userProfile?.displayName;
  String? get email => _userProfile?.email;
  String? get photoURL => _userProfile?.photoURL;
  DateTime? get createdAt => _userProfile?.createdAt;
  DateTime? get lastUpdated => _userProfile?.lastUpdated;
}