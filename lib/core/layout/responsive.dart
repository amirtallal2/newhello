import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class ResponsiveMetrics {
  ResponsiveMetrics._(this._mediaQuery);

  final MediaQueryData _mediaQuery;

  static ResponsiveMetrics of(BuildContext context) {
    return ResponsiveMetrics._(MediaQuery.of(context));
  }

  Size get screenSize => _mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  bool get isTablet => screenWidth >= 600;
  bool get isCompactWidth => screenWidth < 360;
  bool get isCompactHeight => screenHeight < 700;

  double get _widthBasis => math.min(screenWidth, 430);
  double get scale => (_widthBasis / 375).clamp(0.88, 1.16).toDouble();
  double get textScale => (_widthBasis / 375).clamp(0.92, 1.14).toDouble();
  double get maxContentWidth => isTablet ? 460 : double.infinity;

  double size(double value) => value * scale;

  double font(double value, {double? min, double? max}) {
    final scaled = value * textScale;
    if (min == null && max == null) {
      return scaled;
    }

    final lowerBound = min ?? double.negativeInfinity;
    final upperBound = max ?? double.infinity;
    return scaled.clamp(lowerBound, upperBound).toDouble();
  }

  double spacing(double value, {double? min, double? max}) {
    final scaled = value * scale;
    if (min == null && max == null) {
      return scaled;
    }

    final lowerBound = min ?? double.negativeInfinity;
    final upperBound = max ?? double.infinity;
    return scaled.clamp(lowerBound, upperBound).toDouble();
  }

  double pageHorizontalPadding({double compact = 14, double regular = 18}) {
    return isCompactWidth ? compact : regular;
  }

  double bottomBarHeight({double base = 77}) {
    return math.max(68, size(base));
  }

  double sheetMaxHeight(double fraction, {double minHeight = 280}) {
    return math.max(minHeight, screenHeight * fraction);
  }
}

class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 460,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final childWidget = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: metrics.isTablet ? maxWidth : double.infinity,
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );

    return Align(alignment: alignment, child: childWidget);
  }
}
