import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';

typedef OnboardingHeroBuilder =
    Widget Function(BuildContext context, double width, double height);

class OnboardingScreenLayout extends StatelessWidget {
  const OnboardingScreenLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.activeStep,
    required this.heroBuilder,
    required this.onContinue,
    this.onSkip,
    this.titleHorizontalPaddingFactor = 63 / 375,
    this.subtitleHorizontalPaddingFactor = 10 / 375,
    this.showSkip = true,
  });

  static const Color primaryBlue = Color(0xFF285F98);
  static const Color softBlue = Color(0xFFB4D1EF);
  static const Color mutedText = Color(0xFF8C8C8C);
  static const Color divider = Color(0xFFF7F7F7);
  static const Color indicatorInactive = Color(0xFFEDEFEE);

  final String title;
  final String subtitle;
  final int activeStep;
  final OnboardingHeroBuilder heroBuilder;
  final VoidCallback onContinue;
  final VoidCallback? onSkip;
  final double titleHorizontalPaddingFactor;
  final double subtitleHorizontalPaddingFactor;
  final bool showSkip;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final topSectionHeight = height * (390 / 812);
          final headingGap = height * (35 / 812);
          final paragraphGap = height * (30 / 812);
          final indicatorGap = height * (18 / 812);
          final dividerTopGap = height * (30 / 812);
          final actionsTopGap = height * (50 / 812);
          final buttonWidth = width * (130 / 375);
          final buttonHeight = height * (43 / 812);
          final bottomPadding = height * (84 / 812);
          final radius = width * (70 / 375);

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: height),
              child: Column(
                children: [
                  SizedBox(
                    height: topSectionHeight,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: primaryBlue,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(radius),
                                bottomRight: Radius.circular(radius),
                              ),
                            ),
                          ),
                        ),
                        heroBuilder(context, width, height),
                      ],
                    ),
                  ),
                  SizedBox(height: headingGap),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * titleHorizontalPaddingFactor,
                    ),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: paragraphGap),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * subtitleHorizontalPaddingFactor,
                    ),
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.67,
                        color: mutedText,
                      ),
                    ),
                  ),
                  SizedBox(height: indicatorGap),
                  _OnboardingIndicator(activeStep: activeStep),
                  SizedBox(height: dividerTopGap),
                  const Divider(height: 1, thickness: 2, color: divider),
                  SizedBox(height: actionsTopGap),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * (43 / 375),
                    ),
                    child: showSkip
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _OnboardingActionButton(
                                label: 'Skip',
                                width: buttonWidth,
                                height: buttonHeight,
                                backgroundColor: softBlue,
                                foregroundColor: primaryBlue,
                                onPressed:
                                    onSkip ??
                                    () {
                                      Navigator.of(
                                        context,
                                      ).pushReplacementNamed(
                                        AppRoutes.bootstrap,
                                      );
                                    },
                              ),
                              _OnboardingActionButton(
                                label: 'Continue',
                                width: buttonWidth,
                                height: buttonHeight,
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                onPressed: onContinue,
                              ),
                            ],
                          )
                        : _OnboardingActionButton(
                            label: 'Continue',
                            width: width * (290 / 375),
                            height: buttonHeight,
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            onPressed: onContinue,
                          ),
                  ),
                  SizedBox(height: bottomPadding),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OnboardingIndicator extends StatelessWidget {
  const _OnboardingIndicator({required this.activeStep});

  final int activeStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(3, (index) {
        final isActive = index == activeStep;

        return Padding(
          padding: EdgeInsetsDirectional.only(start: index == 0 ? 0 : 5),
          child: isActive
              ? const DecoratedBox(
                  decoration: BoxDecoration(
                    color: OnboardingScreenLayout.primaryBlue,
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                  child: SizedBox(width: 28, height: 7),
                )
              : const DecoratedBox(
                  decoration: BoxDecoration(
                    color: OnboardingScreenLayout.indicatorInactive,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(width: 9, height: 9),
                ),
        );
      }),
    );
  }
}

class _OnboardingActionButton extends StatelessWidget {
  const _OnboardingActionButton({
    required this.label,
    required this.width,
    required this.height,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String label;
  final double width;
  final double height;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.zero,
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 2.5,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
