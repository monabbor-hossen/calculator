import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// A neumorphic calculator button.
/// Sizes are driven by [AppSizes] so the button scales with the screen.
class CalcButton extends StatefulWidget {
  final String   label;
  final AppSizes sizes;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool wide;
  final bool isActive;

  const CalcButton({
    super.key,
    required this.label,
    required this.sizes,
    required this.onTap,
    this.onLongPress,
    this.wide     = false,
    this.isActive = false,
  });

  @override
  State<CalcButton> createState() => _CalcButtonState();
}

class _CalcButtonState extends State<CalcButton> {
  bool _pressed = false;

  static const _operatorLabels = {'÷', '×', '−', '+', '='};
  static const _accentLabels   = {'+/-', '%', '(', ')'};

  Color get _labelColor {
    if (widget.isActive) return Colors.white;
    if (_operatorLabels.contains(widget.label)) return kOrange;
    if (_accentLabels.contains(widget.label) || widget.label == '⌫') return kOrange;
    if (widget.label == 'AC' || widget.label == 'C') return kTextSecondary;
    return kTextPrimary;
  }

  Color get _btnColor => widget.isActive ? kOrange : kBtnBase;

  List<BoxShadow> get _shadows {
    if (widget.isActive) {
      return [
        BoxShadow(
          color: kOrange.withValues(alpha: 0.4),
          offset: const Offset(0, 4),
          blurRadius: 12,
        ),
      ];
    }
    if (_pressed) {
      return const [
        BoxShadow(
          color: kShadowDark,
          offset: Offset(2, 2),
          blurRadius: 5,
        ),
      ];
    }
    return const [
      BoxShadow(
        color: kShadowDark,
        offset: Offset(3, 3),
        blurRadius: 6,
      ),
      BoxShadow(
        color: kShadowLight,
        offset: Offset(-3, -3),
        blurRadius: 6,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final double leftPad = widget.wide
        ? widget.sizes.screenPadding * 0.75
        : 0;

    return SizedBox.expand(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) {
            HapticFeedback.lightImpact();
            setState(() => _pressed = true);
          },
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          onLongPress: widget.onLongPress != null
              ? () {
                  setState(() => _pressed = false);
                  HapticFeedback.mediumImpact();
                  widget.onLongPress!();
                }
              : null,
          child: AnimatedScale(
            scale: _pressed ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: _btnColor,
                borderRadius: BorderRadius.circular(
                  widget.wide ? widget.sizes.wideBtnRadius : 999,
                ),
                boxShadow: _shadows,
              ),
              alignment: widget.wide ? Alignment.centerLeft : Alignment.center,
              padding: EdgeInsets.only(left: leftPad),
              child: widget.label == '⌫'
                  ? Icon(
                      Icons.backspace_rounded,
                      color: _labelColor,
                      size: widget.sizes.btnFontSize * 0.95,
                    )
                  : Text(
                      widget.label,
                      style: TextStyle(
                        color: _labelColor,
                        fontSize: widget.sizes.btnFontSize,
                        fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
