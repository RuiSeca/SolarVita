import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../debug/range_error_tracker.dart';
import '../debug/director_coach_analyzer.dart';
import '../debug/add_director_coach_firebase.dart';
import '../debug/update_quantum_coach_firebase.dart';
import '../debug/translation_populator_debug.dart';

/// Temporary maintenance screen to debug RangeError issues
class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.orange[50] ?? Colors.orange.withValues(alpha: 0.1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Add top spacing for better layout
              const SizedBox(height: 40),
              
              Icon(
                Icons.engineering,
                size: 100,
                color: Colors.orange[600] ?? Colors.orange,
              ),
              const SizedBox(height: 24),
              Text(
                'Avatar System Maintenance',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800] ?? Colors.orange,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'We\'re temporarily fixing animation issues.\nDebug tools are available below.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.orange[700] ?? Colors.orange,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // Debug Tools
              _buildDebugButton(
                context,
                'RangeError Tracker',
                'Monitor real-time RangeError exceptions',
                Icons.bug_report,
                Colors.red,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RangeErrorTracker()),
                ),
              ),
              
              const SizedBox(height: 16),
              
              
              const SizedBox(height: 16),
              
              _buildDebugButton(
                context,
                'Director Coach Analyzer',
                'Analyze director_coach.riv file structure',
                Icons.movie,
                Colors.purple,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DirectorCoachAnalyzer()),
                ),
              ),
              
              const SizedBox(height: 16),
              
              _buildDebugButton(
                context,
                'Add Director Coach',
                'Add director_coach to Firebase collection',
                Icons.cloud_upload,
                Colors.green,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddDirectorCoachFirebase()),
                ),
              ),
              
              const SizedBox(height: 16),
              
              _buildDebugButton(
                context,
                'Update Quantum Coach',
                'Fix quantum_coach animations in Firebase',
                Icons.psychology,
                Colors.purple,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UpdateQuantumCoachFirebase()),
                ),
              ),
              
              const SizedBox(height: 16),
              
              
              const SizedBox(height: 16),
              
              _buildDebugButton(
                context,
                'Populate Translations',
                'Seed Firestore with localized avatar data',
                Icons.translate,
                Colors.indigo,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TranslationPopulatorDebug()),
                ),
              ),
              
              const SizedBox(height: 16),
              
              
              
              const SizedBox(height: 40),
              
              // Back Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600] ?? Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue with Static Avatars',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              // Add bottom padding to ensure scroll space
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebugButton(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    MaterialColor color,
    VoidCallback onTap,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color[600] ?? color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800] ?? Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600] ?? Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400] ?? Colors.grey,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}