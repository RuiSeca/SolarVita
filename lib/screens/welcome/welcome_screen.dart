import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../login/login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  WelcomeScreenState createState() => WelcomeScreenState();
}

class WelcomeScreenState extends State<WelcomeScreen> {
  int _currentIndex = 0;

  final List<String> images = [
    'assets/images/fitness1.jpg',
    'assets/images/fitness2.jpg',
    'assets/images/fitness3.jpg',
  ];

  final List<String> titles = [
    "Sustainable Fitness",
    "Empower Your Body",
    "Mind & Strength",
  ];

  final List<String> descriptions = [
    "Train with an eco-friendly mindset, using sustainable resources.",
    "Achieve your fitness goals while reducing your carbon footprint.",
    "Balance strength, endurance, and mindfulness in your journey.",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Custom Rich Text Welcome Message
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Welcome to ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const TextSpan(
                      text: 'Solar Vitas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green, // Changed to blue
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),

            // Carousel Slider (centered and enlarged)
            Center(
              child: CarouselSlider(
                options: CarouselOptions(
                  height: 350, // Increased height for a larger carousel
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 4),
                  enlargeCenterPage: true,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                ),
                items: images.map((imgPath) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      imgPath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),

            // Dot indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (index) {
                return Container(
                  width: 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index
                        ? Colors.white
                        : Colors.white.withAlpha(71),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // Title Changing with Images
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                titles[_currentIndex],
                key: ValueKey<String>(titles[_currentIndex]),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 8),

            // Description Changing with Images
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                descriptions[_currentIndex],
                key: ValueKey<String>(descriptions[_currentIndex]),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const Spacer(),

            // "Get Moving" Button
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Get Moving',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
