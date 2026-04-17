import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const Color _backgroundColor = Color(0xFF285F98);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1600), _openNextScreen);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _openNextScreen() {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(AppRoutes.onboardingFirst);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: SplashScreen._backgroundColor,
      body: _SplashArtwork(),
    );
  }
}

class _SplashArtwork extends StatelessWidget {
  const _SplashArtwork();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: SplashScreen._backgroundColor,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: FractionallySizedBox(
            widthFactor: 0.94,
            child: Image(
              image: AssetImage('assets/images/splash_logo.png'),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}
