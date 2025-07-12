import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieLoadingWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxFit? fit;

  const LottieLoadingWidget({
    super.key,
    this.width,
    this.height,
    this.fit,
  });

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/lotties/Loading.json',
      width: width ?? 60,
      height: height ?? 60,
      fit: fit ?? BoxFit.contain,
      repeat: true,
    );
  }
}