import 'package:flutter/material.dart';
import '../common/fan_menu_fab.dart';

/// Demo screen to showcase the fan menu FAB functionality
class FanMenuDemoScreen extends StatefulWidget {
  const FanMenuDemoScreen({super.key});

  @override
  State<FanMenuDemoScreen> createState() => _FanMenuDemoScreenState();
}

class _FanMenuDemoScreenState extends State<FanMenuDemoScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fan Menu FAB Demo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDemoSection(
                '🎯 Interactive Fan Menu',
                'Tap the FAB to expand the fan menu, or long-press for futuristic drag-to-select.',
              ),
              const SizedBox(height: 24),
              _buildDemoSection(
                '🌟 Features',
                '• Chinese fan-style animation\n'
                '• Glassmorphism design\n'
                '• Haptic feedback\n'
                '• Scroll-aware hiding\n'
                '• Long-press drag selection\n'
                '• Smooth elastic animations',
              ),
              const SizedBox(height: 24),
              _buildDemoSection(
                '📱 How to Use',
                '1. Tap: Opens/closes the fan menu\n'
                '2. Long-press: Expands menu for drag selection\n'
                '3. Drag: Move finger to hover over options\n'
                '4. Release: Selects the hovered option\n'
                '5. Scroll: FAB hides when scrolling down',
              ),
              const SizedBox(height: 24),
              _buildDemoSection(
                '🎨 Design Elements',
                '• Backdrop blur effects\n'
                '• Semi-transparent backgrounds\n'
                '• Dynamic color theming\n'
                '• Elastic bounce animations\n'
                '• Scale transformations\n'
                '• Rotation effects',
              ),
              // Add more content to enable scrolling
              ...List.generate(20, (index) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Text('${index + 1}'),
                  ),
                  title: Text('Demo Item ${index + 1}'),
                  subtitle: Text('Scroll down to see the FAB hide automatically'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              )),
            ],
          ),
        ),
      ),
      floatingActionButton: FanMenuFAB(
        scrollController: _scrollController,
        backgroundColor: Theme.of(context).primaryColor,
        menuItems: [
          FanMenuItem(
            icon: Icons.fitness_center,
            label: 'Quick Workout',
            color: Theme.of(context).primaryColor,
            onTap: () => _showSnackBar('Quick Workout selected! 💪'),
          ),
          FanMenuItem(
            icon: Icons.restaurant,
            label: 'Add Food',
            color: Colors.green,
            onTap: () => _showSnackBar('Add Food selected! 🥗'),
          ),
          FanMenuItem(
            icon: Icons.edit,
            label: 'Edit Profile',
            color: Colors.blueAccent,
            onTap: () => _showSnackBar('Edit Profile selected! ✏️'),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildDemoSection(String title, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(20),
      ),
    );
  }
}