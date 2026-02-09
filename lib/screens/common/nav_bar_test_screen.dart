import 'package:flutter/material.dart';
import '../../widgets/common/futuristic_nav_bar.dart';

/// Test screen to preview the futuristic navigation bar
class NavBarTestScreen extends StatefulWidget {
  const NavBarTestScreen({super.key});

  @override
  State<NavBarTestScreen> createState() => _NavBarTestScreenState();
}

class _NavBarTestScreenState extends State<NavBarTestScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _DemoScreen(title: 'Dashboard', icon: Icons.dashboard, color: Colors.blue),
    const _DemoScreen(title: 'Search', icon: Icons.search, color: Colors.purple),
    const _DemoScreen(title: 'PULSE AI Assistant', icon: Icons.psychology, color: Colors.green),
    const _DemoScreen(title: 'Health', icon: Icons.favorite, color: Colors.red),
    const _DemoScreen(title: 'Profile', icon: Icons.person, color: Colors.orange),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Futuristic Nav Bar Preview'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: FuturisticNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          
          // Show feedback when PULSE is tapped
          if (index == 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Opening PULSE AI Assistant...'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        },
      ),
    );
  }
}

class _DemoScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _DemoScreen({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.1),
            Colors.white,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: color,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Test the navigation bar:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Tap icons to see smooth animations\n'
                    '• Watch PULSE mascot breathing effect\n'
                    '• Notice gradient border rotation\n'
                    '• See glowing green eyes pulse\n'
                    '• Test color changes (gray/green)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
