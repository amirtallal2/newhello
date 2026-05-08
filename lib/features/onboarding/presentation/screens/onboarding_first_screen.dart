import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/storage/app_launch_store.dart';
import '../widgets/onboarding_screen_layout.dart';

class OnboardingFirstScreen extends StatelessWidget {
  const OnboardingFirstScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingScreenLayout(
      title: 'Discover Meaningful\nConnections',
      subtitle:
          'Join Soul today and discover a world of genuine connections.\nSwipe, match, and meet people\nwho share your interests.',
      activeStep: 0,
      titleHorizontalPaddingFactor: 63 / 375,
      subtitleHorizontalPaddingFactor: 10 / 375,
      heroBuilder: (context, width, height) {
        return Positioned(
          left: width * (-12 / 375),
          top: height * (45 / 812),
          child: Image.asset(
            'assets/images/onboarding_1_logo.png',
            width: width * (400 / 375),
            fit: BoxFit.fitWidth,
            filterQuality: FilterQuality.high,
          ),
        );
      },
      onSkip: () {
        AppLaunchStore.instance.markOnboardingSeen().then((_) {
          if (!context.mounted) {
            return;
          }
          Navigator.of(context).pushReplacementNamed(AppRoutes.authEntry);
        });
      },
      onContinue: () {
        Navigator.of(context).pushNamed(AppRoutes.onboardingSecond);
      },
    );
  }
}
