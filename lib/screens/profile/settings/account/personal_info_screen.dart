// lib/screens/profile/settings/account/personal_info_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../../providers/riverpod/user_profile_provider.dart';
import '../../../../services/database/user_profile_service.dart';
import '../../../../widgets/common/lottie_loading_widget.dart';
import '../../../../utils/translation_helper.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserProfileService _userProfileService = UserProfileService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _displayNameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _ageController;

  String _activityLevel = 'intermediate';
  String _weeklyActivity = 'times_3_4';
  String _gender = 'prefer_not_to_say';
  bool _isLoading = false;
  File? _imageFile;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _ageController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  String _validateGender(String? value) {
    const validGenders = ['male', 'female', 'prefer_not_to_say'];
    if (value == null) return 'prefer_not_to_say';
    final normalized = value.toLowerCase();
    return validGenders.contains(normalized) ? normalized : 'prefer_not_to_say';
  }

  String _validateActivityLevel(String? value) {
    const validLevels = ['beginner', 'intermediate', 'advanced'];
    if (value == null) return 'intermediate';
    final normalized = value.toLowerCase();
    return validLevels.contains(normalized) ? normalized : 'intermediate';
  }

  String _validateWeeklyActivity(String? value) {
    const validActivities = ['times_1_2', 'times_3_4', 'times_5_plus'];
    if (value == null) return 'times_3_4';
    return validActivities.contains(value) ? value : 'times_3_4';
  }

  @override
  Widget build(BuildContext context) {
    final userProfileProvider = ref.watch(userProfileNotifierProvider);
    final userProfile = userProfileProvider.value;

    return Builder(
      builder: (context) {
        // Initialize controllers with user data when available
        if (userProfile != null && !_isLoading) {
          _displayNameController.text = userProfile.displayName;
          _usernameController.text = userProfile.username ?? '';
          _emailController.text = userProfile.email;
          _profileImageUrl = userProfile.photoURL;
          // Set other fields from additional data if available
          final additionalData = userProfile.additionalData;
          _phoneController.text = additionalData['phone'] ?? '';
          _heightController.text = additionalData['height'] ?? '';
          _weightController.text = additionalData['weight'] ?? '';
          _ageController.text = additionalData['age'] ?? '';
          _gender = _validateGender(additionalData['gender']);
          _activityLevel = _validateActivityLevel(additionalData['activityLevel']);
          _weeklyActivity = _validateWeeklyActivity(additionalData['weeklyActivity']);
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              tr(context, 'personal_information'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildProfilePictureSection(),
                  const SizedBox(height: 32),
                  _buildBasicInfoSection(),
                  const SizedBox(height: 24),
                  _buildPhysicalInfoSection(),
                  const SizedBox(height: 24),
                  _buildFitnessSection(),
                  const SizedBox(height: 32),
                  _buildSaveButton(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
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
            content: Text('${tr(context, 'error_picking_image')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_imageFile == null) return _profileImageUrl;

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
            content: Text('${tr(context, 'error_uploading_image')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return _profileImageUrl;
    }
  }

  Future<void> _removeProfileImage() async {
    try {
      setState(() {
        _imageFile = null;
        _profileImageUrl = null;
      });

      final currentProfile = ref.read(userProfileNotifierProvider).value;
      if (currentProfile != null) {
        final updatedProfile = currentProfile.copyWith(photoURL: null);

        await _userProfileService.updateUserProfile(updatedProfile);
        ref
            .read(userProfileNotifierProvider.notifier)
            .setUserProfile(updatedProfile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr(context, 'profile_picture_removed_successfully')),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tr(context, 'error_removing_profile_picture')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _savePersonalInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload profile image if changed
      final imageUrl = await _uploadProfileImage();

      // Check username availability if changed
      final currentProfile = ref.read(userProfileNotifierProvider).value;
      if (currentProfile != null) {
        final username = _usernameController.text.trim();
        if (username.isNotEmpty && username != currentProfile.username) {
          final isUsernameAvailable = await _userProfileService
              .isUsernameAvailable(username);
          if (!isUsernameAvailable) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    tr(context, 'username_already_taken'),
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
        }

        final updatedAdditionalData = Map<String, dynamic>.from(
          currentProfile.additionalData,
        );
        updatedAdditionalData.addAll({
          'phone': _phoneController.text.trim(),
          'height': _heightController.text.trim(),
          'weight': _weightController.text.trim(),
          'age': _ageController.text.trim(),
          'gender': _gender,
          'activityLevel': _activityLevel,
          'weeklyActivity': _weeklyActivity,
        });

        final updatedProfile = currentProfile.copyWith(
          displayName: _displayNameController.text.trim(),
          username: username.isNotEmpty ? username : currentProfile.username,
          photoURL: imageUrl,
          additionalData: updatedAdditionalData,
        );

        await _userProfileService.updateUserProfile(updatedProfile);

        if (mounted) {
          // Update the provider
          ref
              .read(userProfileNotifierProvider.notifier)
              .setUserProfile(updatedProfile);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr(context, 'personal_information_updated_successfully')),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tr(context, 'error_saving_information')}: $e'),
            backgroundColor: Colors.red,
          ),
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'update_your_information'),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          tr(context, 'keep_profile_up_to_date'),
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
                    : _profileImageUrl != null
                    ? NetworkImage(_profileImageUrl!)
                    : null,
                backgroundColor: Colors.grey[300],
                child: _imageFile == null && _profileImageUrl == null
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
          tr(context, 'tap_to_change_profile_picture'),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        if (_profileImageUrl != null || _imageFile != null)
          const SizedBox(height: 8),
        if (_profileImageUrl != null || _imageFile != null)
          TextButton.icon(
            onPressed: _removeProfileImage,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: Text(tr(context, 'remove_profile_picture')),
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
          tr(context, 'basic_information'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _displayNameController,
          decoration: InputDecoration(
            labelText: tr(context, 'display_name'),
            hintText: tr(context, 'display_name_hint'),
            prefixIcon: const Icon(Icons.person),
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return tr(context, 'please_enter_display_name');
            }
            if (value.length < 2) {
              return tr(context, 'display_name_min_length');
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _usernameController,
          decoration: InputDecoration(
            labelText: tr(context, 'username'),
            hintText: tr(context, 'username_hint'),
            helperText: tr(context, 'username_helper_text'),
            prefixIcon: const Icon(Icons.alternate_email),
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (value.length < 3) {
                return tr(context, 'username_min_length');
              }
              if (value.length > 20) {
                return tr(context, 'username_max_length');
              }
              if (value.contains(' ')) {
                return tr(context, 'username_no_spaces');
              }
              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                return tr(context, 'username_allowed_characters');
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          enabled: false,
          decoration: InputDecoration(
            labelText: tr(context, 'email'),
            prefixIcon: const Icon(Icons.email),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: tr(context, 'phone_number_optional'),
            hintText: tr(context, 'phone_number_hint'),
            prefixIcon: const Icon(Icons.phone),
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _gender,
          decoration: InputDecoration(
            labelText: tr(context, 'gender'),
            prefixIcon: const Icon(Icons.person_outline),
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(value: 'male', child: Text(tr(context, 'male'))),
            DropdownMenuItem(value: 'female', child: Text(tr(context, 'female'))),
            DropdownMenuItem(
              value: 'prefer_not_to_say',
              child: Text(tr(context, 'prefer_not_to_say')),
            ),
          ],
          onChanged: (value) {
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
          tr(context, 'physical_information'),
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
                decoration: InputDecoration(
                  labelText: tr(context, 'age'),
                  hintText: tr(context, 'age_hint'),
                  prefixIcon: const Icon(Icons.cake),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final age = int.tryParse(value);
                    if (age == null || age < 13 || age > 120) {
                      return tr(context, 'please_enter_valid_age');
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _heightController,
                decoration: InputDecoration(
                  labelText: tr(context, 'height_cm'),
                  hintText: tr(context, 'height_hint'),
                  prefixIcon: const Icon(Icons.height),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final height = int.tryParse(value);
                    if (height == null || height < 100 || height > 250) {
                      return tr(context, 'please_enter_valid_height');
                    }
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
          decoration: InputDecoration(
            labelText: tr(context, 'weight_kg'),
            hintText: tr(context, 'weight_hint'),
            prefixIcon: const Icon(Icons.monitor_weight),
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final weight = double.tryParse(value);
              if (weight == null || weight < 30 || weight > 300) {
                return tr(context, 'please_enter_valid_weight');
              }
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
          tr(context, 'fitness_level'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _activityLevel,
          decoration: InputDecoration(
            labelText: tr(context, 'current_activity_level'),
            prefixIcon: const Icon(Icons.fitness_center),
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(value: 'beginner', child: Text(tr(context, 'beginner'))),
            DropdownMenuItem(
              value: 'intermediate',
              child: Text(tr(context, 'intermediate')),
            ),
            DropdownMenuItem(value: 'advanced', child: Text(tr(context, 'advanced'))),
          ],
          onChanged: (value) {
            setState(() {
              _activityLevel = value!;
            });
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _weeklyActivity,
          decoration: InputDecoration(
            labelText: tr(context, 'weekly_exercise_frequency'),
            prefixIcon: const Icon(Icons.calendar_today),
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(value: 'times_1_2', child: Text(tr(context, 'times_1_2'))),
            DropdownMenuItem(value: 'times_3_4', child: Text(tr(context, 'times_3_4'))),
            DropdownMenuItem(value: 'times_5_plus', child: Text(tr(context, 'times_5_plus'))),
          ],
          onChanged: (value) {
            setState(() {
              _weeklyActivity = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _savePersonalInfo,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const LottieLoadingWidget(width: 24, height: 24)
            : Text(tr(context, 'save_changes')),
      ),
    );
  }
}
