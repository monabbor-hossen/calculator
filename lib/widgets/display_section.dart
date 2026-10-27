import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// Shows the expression preview (small, gray) and the current result (large, white).
/// All font sizes are driven by [AppSizes].
class DisplaySection extends StatelessWidget {
  final String display;
  final String preview;
  final AppSizes sizes;
  final VoidCallback? onBackspace;
  final String? angleMode;

  const DisplaySection({
    super.key,
    required this.display,
    required this.preview,
    required this.sizes,
    this.onBackspace,
    this.angleMode,
  });

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _addCommasToNumber(String numStr) {
    if (numStr == 'Error' || numStr.isEmpty) return numStr;
    final negative = numStr.startsWith('-');
    final abs      = negative ? numStr.substring(1) : numStr;
    final parts    = abs.split('.');
    final intPart  = parts[0];
    final buf      = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    if (parts.length > 1) buf.write('.${parts[1]}');
    return negative ? '-${buf.toString()}' : buf.toString();
  }

  String _formatText(String raw) {
    if (raw.isEmpty || raw == 'Error') return raw;
    return raw.split(' ').map((token) {
      if (token == '+' || token == '−' || token == '×' || token == '÷' || token == '=') {
        return token;
      }
      var prefix = '';
      var suffix = '';
      var core = token;
      while (core.startsWith('(')) {
        prefix += '(';
        core = core.substring(1);
      }
      while (core.endsWith(')')) {
        suffix = ')$suffix';
        core = core.substring(0, core.length - 1);
      }
      if (core.endsWith('%')) {
        suffix = '%$suffix';
        core = core.substring(0, core.length - 1);
      }
      if (double.tryParse(core) != null) {
        return '$prefix${_addCommasToNumber(core)}$suffix';
      }
      return token;
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        if (onBackspace != null && (details.primaryVelocity ?? 0).abs() > 30) {
          HapticFeedback.lightImpact();
          onBackspace!();
        }
      },
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: display));
        HapticFeedback.selectionClick();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: kBtnBase,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(
              'Copied $display to clipboard',
              style: const TextStyle(color: kTextPrimary),
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment:  MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (angleMode != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF333333)),
                  ),
                  child: Text(
                    angleMode!,
                    style: const TextStyle(
                      color: kOrange,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
            // ── Preview expression ────────────────────────────────────────────
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity:  preview.isEmpty ? 0.0 : 1.0,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  _formatText(preview),
                  maxLines:  1,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color:         kTextSecondary,
                    fontSize:      sizes.previewFontSize,
                    fontWeight:    FontWeight.w300,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            SizedBox(height: sizes.gap * 0.4),
            // ── Main result ───────────────────────────────────────────────────
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: TextStyle(
                  color:         kTextPrimary,
                  fontSize:      sizes.displayFontSize(display.length),
                  fontWeight:    FontWeight.w300,
                  letterSpacing: -2,
                ),
                child: Text(
                  _formatText(display),
                  maxLines:  1,
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
