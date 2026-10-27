import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../core/theme/neumorphic_theme.dart';

/// Reusable circular Neumorphic Icon Button with haptics and tooltip.
class NeumorphicIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? color;
  final double size;
  final double iconSize;

  const NeumorphicIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.color,
    this.size = 42,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final btn = GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: size,
        height: size,
        decoration: NeumorphicTheme.circleDecoration(),
        alignment: Alignment.center,
        child: Icon(icon, color: color ?? kTextPrimary, size: iconSize),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}
