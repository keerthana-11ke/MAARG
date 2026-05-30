import 'package:flutter/material.dart';

extension ResponsiveExtension on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  // Responsive padding/margin helper using screenWidth (scaled from 390px baseline)
  double rw(double base) {
    final scale = screenWidth / 390.0;
    // Keep it within reasonable bounds so it scales gracefully on all phone screen widths
    return (base * scale).clamp(base * 0.8, base * 1.5);
  }

  EdgeInsets paddingAll(double val) => EdgeInsets.all(rw(val));

  EdgeInsets paddingSymmetric({double horizontal = 0, double vertical = 0}) =>
      EdgeInsets.symmetric(
        horizontal: rw(horizontal),
        vertical: rw(vertical),
      );

  EdgeInsets paddingOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) =>
      EdgeInsets.only(
        left: rw(left),
        top: rw(top),
        right: rw(right),
        bottom: rw(bottom),
      );
}
