// lib/screens/profile/settings/account/personal_info_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/user_profile_provider.dart';
import '../../../../theme/app_theme.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _ageController;
  
  String _activityLevel = 'Intermediate';
  String _weeklyActivity = '3-4 times';
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _ageController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (context, userProfileProvider, _) {
        final userProfile = userProfileProvider.userProfile;
        
        // Initialize controllers with user data when available
        if (userProfile != null && !_isEditing) {
          _nameController.text = userProfile.displayName;
          _emailController.text = userProfile.email;
          // Set other fields from additional data if available
          final additionalData = userProfile.additionalData;
          _phoneController.text = additionalData['phone'] ?? '';
          _heightController.text = additionalData['height'] ?? '';
          _weightController.text = additionalData['weight'] ?? '';
          _ageController.text = additionalData['age'] ?? '';
          _activityLevel = additionalData['activityLevel'] ?? 'Intermediate';
          _weeklyActivity = additionalData['weeklyActivity'] ?? '3-4 times';
        }
        
        return Scaffold(
          backgroundColor: AppTheme.surfaceColor(context),
          appBar: AppBar(
            backgroundColor: AppTheme.surfaceColor(context),
            title: Text(
              'Personal Information',
              style: TextStyle(color: AppTheme.textColor(context)),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isEditing ? Icons.save : Icons.edit,
                  color: AppColors.primary,
                ),
                onPressed: _isEditing ? _saveChanges : _toggleEditing,
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    context: context,
                    title: 'Basic Information',
                    children: [
                      _buildTextField(
                        context: context,
                        label: 'Full Name',
                        controller: _nameController,
                        icon: Icons.person,
                        enabled: _isEditing,
                      ),
                      _buildTextField(
                        context: context,
                        label: 'Email',
                        controller: _emailController,
                        icon: Icons.email,
                        enabled: false, // Email should not be editable
                      ),
                      _buildTextField(
                        context: context,
                        label: 'Phone',
                        controller: _phoneController,
                        icon: Icons.phone,
                        enabled: _isEditing,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context: context,
                    title: 'Physical Information',
                    children: [
                      _buildTextField(
                        context: context,
                        label: 'Height',
                        controller: _heightController,
                        icon: Icons.height,
                        enabled: _isEditing,
                        suffix: 'cm',
                      ),
                      _buildTextField(
                        context: context,
                        label: 'Weight',
                        controller: _weightController,
                        icon: Icons.monitor_weight,
                        enabled: _isEditing,
                        suffix: 'kg',
                      ),
                      _buildTextField(
                        context: context,
                        label: 'Age',
                        controller: _ageController,
                        icon: Icons.cake,
                        enabled: _isEditing,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context: context,
                    title: 'Fitness Level',
                    children: [
                      _buildDropdown(
                        context: context,
                        label: 'Activity Level',
                        value: _activityLevel,
                        items: const ['Beginner', 'Intermediate', 'Advanced'],
                        icon: Icons.fitness_center,
                        enabled: _isEditing,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _activityLevel = value;
                            });
                          }
                        },
                      ),
                      _buildDropdown(
                        context: context,
                        label: 'Weekly Activity',
                        value: _weeklyActivity,
                        items: const ['1-2 times', '3-4 times', '5+ times'],
                        icon: Icons.calendar_today,
                        enabled: _isEditing,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _weeklyActivity = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
      final currentProfile = userProfileProvider.userProfile;
      
      if (currentProfile != null) {
        final updatedAdditionalData = Map<String, dynamic>.from(currentProfile.additionalData);
        updatedAdditionalData.addAll({
          'phone': _phoneController.text,
          'height': _heightController.text,
          'weight': _weightController.text,
          'age': _ageController.text,
          'activityLevel': _activityLevel,
          'weeklyActivity': _weeklyActivity,
        });
        
        final updatedProfile = currentProfile.copyWith(
          displayName: _nameController.text,
          additionalData: updatedAdditionalData,
        );
        
        await userProfileProvider.updateUserProfile(updatedProfile);
        
        setState(() {
          _isEditing = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Personal information updated successfully'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    }
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
    String? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.textColor(context).withValues(alpha: 153),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: controller,
                  enabled: enabled,
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: enabled ? 'Enter $label' : null,
                    suffixText: suffix,
                    suffixStyle: TextStyle(
                      color: AppTheme.textColor(context).withValues(alpha: 153),
                    ),
                  ),
                  validator: (value) {
                    if (enabled && (value == null || value.isEmpty)) {
                      return 'Please enter $label';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required BuildContext context,
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required bool enabled,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.textColor(context).withValues(alpha: 153),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  dropdownColor: AppTheme.cardColor(context),
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 16,
                  ),
                  underline: Container(
                    height: 1,
                    color: enabled ? AppColors.primary : Colors.transparent,
                  ),
                  onChanged: enabled ? onChanged : null,
                  items: items.map<DropdownMenuItem<String>>((String item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
