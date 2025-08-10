// Simple test to verify RIVE analyzer functionality
import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RIVE Test',
      home: const TestScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  String result = 'Loading...';

  @override
  void initState() {
    super.initState();
    testRiveFile();
  }

  Future<void> testRiveFile() async {
    try {
      final rivFile = await rive.RiveFile.asset('assets/rive/quantum_coach.riv');
      final artboard = rivFile.mainArtboard;
      
      final info = StringBuffer();
      info.writeln('✅ RIVE file loaded successfully!');
      info.writeln('Artboard: ${artboard.name}');
      info.writeln('Size: ${artboard.width.toStringAsFixed(1)} x ${artboard.height.toStringAsFixed(1)}');
      info.writeln('Animations: ${artboard.animations.length}');
      info.writeln('State Machines: ${artboard.stateMachines.length}');
      info.writeln('Drawables: ${artboard.drawables.length}');
      
      setState(() {
        result = info.toString();
      });
    } catch (e) {
      setState(() {
        result = '❌ Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RIVE Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            result,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ),
    );
  }
}