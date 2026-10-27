import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Reusable Neumorphic UI design system and decoration tokens.
class NeumorphicTheme {
  NeumorphicTheme._();

  /// Standard elevated box shadow pair (light highlight top-left, dark shadow bottom-right).
  static const List<BoxShadow> elevatedShadows = [
    BoxShadow(color: kShadowLight, offset: Offset(-2, -2), blurRadius: 4),
    BoxShadow(color: kShadowDark, offset: Offset(2, 2), blurRadius: 4),
  ];

  /// Subtle shadow for smaller widgets / chips.
  static const List<BoxShadow> subtleShadows = [
    BoxShadow(color: kShadowLight, offset: Offset(-1.5, -1.5), blurRadius: 3),
    BoxShadow(color: kShadowDark, offset: Offset(1.5, 1.5), blurRadius: 3),
  ];

  /// Deep shadow for larger cards (3D canvas, displays).
  static const List<BoxShadow> deepShadows = [
    BoxShadow(color: kShadowLight, offset: Offset(-2.5, -2.5), blurRadius: 5),
    BoxShadow(color: kShadowDark, offset: Offset(2.5, 2.5), blurRadius: 5),
  ];

  /// Standard rounded card decoration.
  static BoxDecoration cardDecoration({
    double radius = 18,
    Color color = kBtnBase,
    Border? border,
    List<BoxShadow> shadows = elevatedShadows,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: border,
      boxShadow: shadows,
    );
  }

  /// Circular neumorphic button decoration.
  static BoxDecoration circleDecoration({
    Color color = kBtnBase,
    List<BoxShadow> shadows = elevatedShadows,
  }) {
    return BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: shadows,
    );
  }

  /// Inset input container decoration.
  static BoxDecoration inputDecoration({
    double radius = 12,
    Color color = const Color(0xFF1E1E1E),
    Border? border,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: border ?? Border.all(color: const Color(0xFF333333)),
    );
  }
}
