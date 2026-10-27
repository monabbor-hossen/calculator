/// All layout dimensions derived from the available screen size.
/// Clamps keep values sane on tiny phones and large tablets/desktops.
class AppSizes {
  final double width;
  final double height;

  const AppSizes({required this.width, required this.height});

  // ── Spacing ───────────────────────────────────────────────────────────────
  /// Horizontal padding on both sides of the screen.
  double get screenPadding => (width * 0.06).clamp(16.0, 36.0);

  /// Uniform gap between buttons (horizontal & vertical).
  double get gap => (width * 0.035).clamp(10.0, 20.0);

  // ── Button ────────────────────────────────────────────────────────────────
  /// Label font size inside each button.
  double get btnFontSize => (width * 0.062).clamp(16.0, 30.0);

  /// Border radius for the wide "0" pill button.
  double get wideBtnRadius => (width * 0.12).clamp(28.0, 60.0);

  // ── Display ───────────────────────────────────────────────────────────────
  /// Large result font — shrinks as the number grows longer.
  double displayFontSize(int charLen) {
    final base = width * 0.18;
    if (charLen <= 6) return base.clamp(40.0, 80.0);
    if (charLen <= 9) return (base * 0.72).clamp(30.0, 58.0);
    return (base * 0.53).clamp(22.0, 44.0);
  }

  /// Smaller preview expression font.
  double get previewFontSize => (width * 0.054).clamp(14.0, 26.0);
}
