import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/storage/app_launch_store.dart';
import '../widgets/onboarding_screen_layout.dart';

class OnboardingSecondScreen extends StatelessWidget {
  const OnboardingSecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingScreenLayout(
      title: 'Explore Authentic\nConnections',
      subtitle:
          'Soul connects you with like-minded individuals to build\nmeaningful relationships effortlessly.',
      activeStep: 1,
      titleHorizontalPaddingFactor: 74 / 375,
      subtitleHorizontalPaddingFactor: 27 / 375,
      heroBuilder: (context, width, height) {
        return Positioned(
          left: width * (38 / 375),
          top: height * (64 / 812),
          child: SvgPicture.asset(
            'assets/images/onboarding_2_hero.svg',
            width: width * (300 / 375),
            height: height * (327 / 812),
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
        Navigator.of(context).pushNamed(AppRoutes.onboardingThird);
      },
    );
  }
}
