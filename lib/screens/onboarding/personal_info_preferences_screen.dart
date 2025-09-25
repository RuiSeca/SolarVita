import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../widgets/common/lottie_loading_widget.dart';
import '../../services/database/user_profile_service.dart';
import '../../providers/riverpod/user_profile_provider.dart';
import 'screens/workout_preferences_screen.dart';
import '../onboarding/models/onboarding_models.dart' as onboarding_models;
import 'services/onboarding_audio_service.dart';
import 'components/onboarding_base_screen.dart';

class PersonalInfoPreferencesScreen extends OnboardingBaseScreen {
  const PersonalInfoPreferencesScreen({super.key});

  @override
  ConsumerState<PersonalInfoPreferencesScreen> createState() =>
      _PersonalInfoPreferencesScreenState();
}

class _PersonalInfoPreferencesScreenState
    extends OnboardingBaseScreenState<PersonalInfoPreferencesScreen> {
  final UserProfileService _userProfileService = UserProfileService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final OnboardingAudioService _audioService = OnboardingAudioService();
  bool _isLoading = false;

  // Form controllers
  late TextEditingController _displayNameController;
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _ageController;

  String _activityLevel = 'Intermediate';
  String _weeklyActivity = '3-4 times';
  String _gender = 'prefer_not_to_say';
  File? _imageFile;

  final List<String> _activityLevelOptions = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  final List<String> _weeklyActivityOptions = [
    '1-2 times',
    '3-4 times',
    '5+ times',
  ];

  final List<String> _genderOptions = ['male', 'female', 'prefer_not_to_say'];

  @override
  void initState() {
    super.initState();
    // Initialize audio service for sound effects
    _audioService.initialize();
    _displayNameController = TextEditingController();
    _usernameController = TextEditingController();
    _phoneController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _ageController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // Play button sound for image picker action
    _audioService.playButtonSound();

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_imageFile == null) return null;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = storageRef.putFile(_imageFile!);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  void _removeProfileImage() {
    // Play button sound for remove action
    _audioService.playButtonSound();
    setState(() {
      _imageFile = null;
    });
  }

  @override
  Widget buildScreenContent(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Information'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildProfilePictureSection(),
              const SizedBox(height: 24),
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildPhysicalInfoSection(),
              const SizedBox(height: 24),
              _buildFitnessSection(),
              const SizedBox(height: 48),
              _buildContinueButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tell us about yourself',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'This information helps us personalize your fitness experience.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildProfilePictureSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : null,
                backgroundColor: Colors.grey[300],
                child: _imageFile == null
                    ? Icon(Icons.person, size: 60, color: Colors.grey[600])
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Add a profile picture (optional)',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        if (_imageFile != null) const SizedBox(height: 8),
        if (_imageFile != null)
          TextButton.icon(
            onPressed: _removeProfileImage,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Remove picture'),
            style: TextButton.styleFrom(foregroundColor: Colors.red[600]),
          ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _displayNameController,
          onTap: () => _audioService.playTextFieldSound(),
          decoration: const InputDecoration(
            labelText: 'Display Name',
            hintText: 'John Doe',
            helperText: 'This name will appear on your profile and dashboard',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your display name';
            }
            if (value.length < 2) {
              return 'Display name must be at least 2 characters';
            }
            if (value.length > 50) {
              return 'Display name must be less than 50 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _usernameController,
          onTap: () => _audioService.playTextFieldSound(),
          decoration: const InputDecoration(
            labelText: 'Username',
            hintText: 'yourname',
            helperText: 'Letters, numbers, and underscores allowed',
            prefixIcon: Icon(Icons.alternate_email),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a username';
            }
            if (value.length < 3) {
              return 'Username must be at least 3 characters';
            }
            if (value.length > 20) {
              return 'Username must be less than 20 characters';
            }
            if (value.contains(' ')) {
              return 'Username cannot contain spaces';
            }
            if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
              return 'Username can contain letters, numbers, and underscores';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          onTap: () => _audioService.playTextFieldSound(),
          decoration: const InputDecoration(
            labelText: 'Phone Number (Optional)',
            hintText: '+1 234 567 8900',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _gender,
          decoration: const InputDecoration(
            labelText: 'Gender',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          items: _genderOptions.map((gender) {
            return DropdownMenuItem(
              value: gender,
              child: Text(_formatGenderName(gender)),
            );
          }).toList(),
          onChanged: (value) {
            _audioService.playButtonSound();
            setState(() {
              _gender = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPhysicalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Physical Information',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _ageController,
                onTap: () => _audioService.playTextFieldSound(),
                decoration: const InputDecoration(
                  labelText: 'Age',
                  hintText: '25',
                  prefixIcon: Icon(Icons.cake),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your age';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 13 || age > 120) {
                    return 'Please enter a valid age';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _heightController,
                onTap: () => _audioService.playTextFieldSound(),
                decoration: const InputDecoration(
                  labelText: 'Height (cm)',
                  hintText: '175',
                  prefixIcon: Icon(Icons.height),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your height';
                  }
                  final height = int.tryParse(value);
                  if (height == null || height < 100 || height > 250) {
                    return 'Please enter a valid height';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _weightController,
          onTap: () => _audioService.playTextFieldSound(),
          decoration: const InputDecoration(
            labelText: 'Weight (kg)',
            hintText: '70',
            prefixIcon: Icon(Icons.monitor_weight),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your weight';
            }
            final weight = double.tryParse(value);
            if (weight == null || weight < 30 || weight > 300) {
              return 'Please enter a valid weight';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildFitnessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fitness Level',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _activityLevel,
          decoration: const InputDecoration(
            labelText: 'Current Activity Level',
            prefixIcon: Icon(Icons.fitness_center),
            border: OutlineInputBorder(),
          ),
          items: _activityLevelOptions.map((level) {
            return DropdownMenuItem(value: level, child: Text(level));
          }).toList(),
          onChanged: (value) {
            _audioService.playButtonSound();
            setState(() {
              _activityLevel = value!;
            });
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _weeklyActivity,
          decoration: const InputDecoration(
            labelText: 'Weekly Exercise Frequency',
            prefixIcon: Icon(Icons.calendar_today),
            border: OutlineInputBorder(),
          ),
          items: _weeklyActivityOptions.map((frequency) {
            return DropdownMenuItem(value: frequency, child: Text(frequency));
          }).toList(),
          onChanged: (value) {
            _audioService.playButtonSound();
            setState(() {
              _weeklyActivity = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () {
          _audioService.playContinueSound();
          _savePersonalInfo();
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const LottieLoadingWidget()
            : const Text('Continue to Workout Preferences'),
      ),
    );
  }

  String _formatGenderName(String gender) {
    switch (gender) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'prefer_not_to_say':
        return 'Prefer not to say';
      default:
        return gender;
    }
  }

  Future<void> _savePersonalInfo() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Check username availability
        final username = _usernameController.text.trim();
        final isUsernameAvailable = await _userProfileService
            .isUsernameAvailable(username);
        if (!isUsernameAvailable) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Username is already taken. Please choose a different one.',
                ),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _isLoading = false;
            });
          }
          return;
        }

        // Upload profile image if one was selected
        final imageUrl = await _uploadProfileImage();

        final profile = await _userProfileService.getOrCreateUserProfile();
        final updatedAdditionalData = Map<String, dynamic>.from(
          profile.additionalData,
        );

        updatedAdditionalData.addAll({
          'phone': _phoneController.text,
          'height': _heightController.text,
          'weight': _weightController.text,
          'age': _ageController.text,
          'gender': _gender,
          'activityLevel': _activityLevel,
          'weeklyActivity': _weeklyActivity,
        });

        final updatedProfile = profile.copyWith(
          displayName: _displayNameController.text.trim(),
          username: _usernameController.text.trim(),
          photoURL: imageUrl,
          additionalData: updatedAdditionalData,
        );

        await _userProfileService.updateUserProfile(updatedProfile);

        if (mounted) {
          // Update the provider
          ref
              .read(userProfileNotifierProvider.notifier)
              .setUserProfile(updatedProfile);

          // Create onboarding UserProfile from the updated data
          final onboardingProfile = onboarding_models.UserProfile(
            name: updatedProfile.displayName,
            username: updatedProfile.username,
            email: updatedProfile.email,
            password: '', // Not available in main profile
            age: int.tryParse(updatedAdditionalData['age']?.toString() ?? '25') ?? 25,
            fitnessLevel: onboarding_models.FitnessLevel.values.firstWhere(
              (level) => level.toString().split('.').last == (updatedAdditionalData['activityLevel'] ?? 'beginner'),
              orElse: () => onboarding_models.FitnessLevel.beginner,
            ),
            selectedIntents: updatedProfile.selectedIntents.map((intent) {
              return onboarding_models.IntentType.values.firstWhere(
                (type) => type.toString().split('.').last == intent.toString().split('.').last,
                orElse: () => onboarding_models.IntentType.fitness,
              );
            }).toSet(),
            currentEcoHabits: <onboarding_models.EcoHabit>{},
            dietaryPreferences: <onboarding_models.DietaryPreference>{},
          );

          // Navigate to workout preferences
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => WorkoutPreferencesScreen(
                userProfile: onboardingProfile,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving personal information: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
