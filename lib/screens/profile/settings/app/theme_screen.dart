// lib/screens/profile/settings/app/theme_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/theme_provider.dart';

class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Theme'),
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildThemeOption(
                context,
                title: 'System',
                subtitle: 'Follow system theme',
                isSelected: themeProvider.isSystem,
                onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                icon: Icons.brightness_auto,
              ),
              const SizedBox(height: 8),
              _buildThemeOption(
                context,
                title: 'Light',
                subtitle: 'Light theme',
                isSelected: themeProvider.isLight,
                onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                icon: Icons.light_mode,
              ),
              const SizedBox(height: 8),
              _buildThemeOption(
                context,
                title: 'Dark',
                subtitle: 'Dark theme',
                isSelected: themeProvider.isDark,
                onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                icon: Icons.dark_mode,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).primaryColor.withAlpha(25)
            : Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: Theme.of(context).primaryColor)
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                color:
                    isSelected ? Theme.of(context).primaryColor : Colors.grey,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
