import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/lottie_loading_widget.dart';
import '../../services/user_profile_service.dart';
import '../../providers/user_profile_provider.dart';
import 'workout_preferences_screen.dart';

class PersonalInfoPreferencesScreen extends StatefulWidget {
  const PersonalInfoPreferencesScreen({super.key});

  @override
  State<PersonalInfoPreferencesScreen> createState() => _PersonalInfoPreferencesScreenState();
}

class _PersonalInfoPreferencesScreenState extends State<PersonalInfoPreferencesScreen> {
  final UserProfileService _userProfileService = UserProfileService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form controllers
  late TextEditingController _phoneController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _ageController;
  
  String _activityLevel = 'Intermediate';
  String _weeklyActivity = '3-4 times';
  String _gender = 'prefer_not_to_say';

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

  final List<String> _genderOptions = [
    'male',
    'female',
    'prefer_not_to_say',
  ];

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _ageController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildPhysicalInfoSection(),
              const SizedBox(height: 24),
              _buildFitnessSection(),
              const SizedBox(height: 32),
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
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This information helps us personalize your fitness experience.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
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
          value: _gender,
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _ageController,
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _activityLevel,
          decoration: const InputDecoration(
            labelText: 'Current Activity Level',
            prefixIcon: Icon(Icons.fitness_center),
            border: OutlineInputBorder(),
          ),
          items: _activityLevelOptions.map((level) {
            return DropdownMenuItem(
              value: level,
              child: Text(level),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _activityLevel = value!;
            });
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _weeklyActivity,
          decoration: const InputDecoration(
            labelText: 'Weekly Exercise Frequency',
            prefixIcon: Icon(Icons.calendar_today),
            border: OutlineInputBorder(),
          ),
          items: _weeklyActivityOptions.map((frequency) {
            return DropdownMenuItem(
              value: frequency,
              child: Text(frequency),
            );
          }).toList(),
          onChanged: (value) {
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
        onPressed: _isLoading ? null : _savePersonalInfo,
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
        final profile = await _userProfileService.getOrCreateUserProfile();
        final updatedAdditionalData = Map<String, dynamic>.from(profile.additionalData);
        
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
          additionalData: updatedAdditionalData,
        );
        
        await _userProfileService.updateUserProfile(updatedProfile);

        if (mounted) {
          // Update the provider
          final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
          userProfileProvider.setUserProfile(updatedProfile);
          
          // Navigate to workout preferences
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const WorkoutPreferencesScreen(),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving personal information: $e'),
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
  }
}