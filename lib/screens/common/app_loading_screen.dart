import 'package:flutter/material.dart';
import '../../widgets/common/lottie_loading_widget.dart';
import '../../widgets/splash/compact_video_logo.dart';

class AppLoadingScreen extends StatelessWidget {
  final String? message;
  
  const AppLoadingScreen({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CompactVideoLogo(
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 32),
            const LottieLoadingWidget(width: 100, height: 100),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}