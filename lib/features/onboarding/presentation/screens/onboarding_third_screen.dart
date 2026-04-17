import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../widgets/onboarding_screen_layout.dart';

class OnboardingThirdScreen extends StatelessWidget {
  const OnboardingThirdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingScreenLayout(
      title: 'Discover Real\nConnections',
      subtitle:
          'Soul helps you connect with people who share your interests,\nmaking it easy to build meaningful relationships.\nEnjoy a unique communication experience that\nsimplifies finding authentic connections.',
      activeStep: 2,
      titleHorizontalPaddingFactor: 102 / 375,
      subtitleHorizontalPaddingFactor: 10 / 375,
      showSkip: false,
      heroBuilder: (context, width, height) {
        return Positioned(
          left: width * (38 / 375),
          top: height * (70 / 812),
          child: Image.asset(
            'assets/images/onboarding_3_hero.png',
            width: width * (300 / 375),
            height: height * (249 / 812),
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
          ),
        );
      },
      onContinue: () {
        Navigator.of(context).pushReplacementNamed(AppRoutes.authEntry);
      },
    );
  }
}
