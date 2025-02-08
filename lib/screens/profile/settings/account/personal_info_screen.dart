// lib/screens/profile/settings/account/personal_info_screen.dart
import 'package:flutter/material.dart';

class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Personal Information'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'Basic Information',
              children: [
                _buildTextField(
                  label: 'Full Name',
                  value: 'John Doe',
                  icon: Icons.person,
                ),
                _buildTextField(
                  label: 'Email',
                  value: 'john.doe@example.com',
                  icon: Icons.email,
                ),
                _buildTextField(
                  label: 'Phone',
                  value: '+1 234 567 890',
                  icon: Icons.phone,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Physical Information',
              children: [
                _buildTextField(
                  label: 'Height',
                  value: '180 cm',
                  icon: Icons.height,
                ),
                _buildTextField(
                  label: 'Weight',
                  value: '75 kg',
                  icon: Icons.monitor_weight,
                ),
                _buildTextField(
                  label: 'Age',
                  value: '28',
                  icon: Icons.cake,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Fitness Level',
              children: [
                _buildDropdown(
                  label: 'Activity Level',
                  value: 'Intermediate',
                  items: const ['Beginner', 'Intermediate', 'Advanced'],
                  icon: Icons.fitness_center,
                ),
                _buildDropdown(
                  label: 'Weekly Activity',
                  value: '3-4 times',
                  items: const ['1-2 times', '3-4 times', '5+ times'],
                  icon: Icons.calendar_today,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
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
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.green),
            onPressed: () {
              // Handle edit
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  dropdownColor: Colors.grey[900],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  underline: Container(
                    height: 1,
                    color: Colors.green,
                  ),
                  onChanged: (String? newValue) {
                    // Handle dropdown change
                  },
                  items: items.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
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
