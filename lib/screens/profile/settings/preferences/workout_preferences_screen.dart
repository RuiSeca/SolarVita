// lib/screens/profile/settings/preferences/workout_preferences_screen.dart
import 'package:flutter/material.dart';

class WorkoutPreferencesScreen extends StatelessWidget {
  const WorkoutPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Workout Preferences'),
      ),
      body: ListView(
        children: const [
          // Add workout preferences
        ],
      ),
    );
  }
}
