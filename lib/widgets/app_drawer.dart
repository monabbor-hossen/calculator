import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../data/history_db.dart';
import '../data/tip_calculation_model.dart';
import '../screens/box_measurement_screen.dart';
import '../screens/history_screen.dart';
import '../screens/tip_calculator_screen.dart';
import '../screens/tip_history_screen.dart';
import '../screens/unit_converter_screen.dart';

class AppDrawer extends StatelessWidget {
  final String currentDisplay;
  final ValueChanged<String> onValueSelected;

  const AppDrawer({
    super.key,
    required this.currentDisplay,
    required this.onValueSelected,
  });

  void _showShortcutsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBtnBase,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.keyboard_outlined, color: kOrange, size: 24),
            SizedBox(width: 10),
            Text(
              'Keyboard Shortcuts',
              style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildShortcutRow('0 – 9', 'Enter numbers'),
              _buildShortcutRow('+  −  *  /', 'Math operators'),
              _buildShortcutRow('Enter / =', 'Calculate result'),
              _buildShortcutRow('Backspace', 'Delete last digit'),
              _buildShortcutRow('Esc / C', 'Clear display'),
              _buildShortcutRow('Ctrl + C', 'Copy result'),
              _buildShortcutRow('Ctrl + V', 'Paste number'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it', style: TextStyle(color: kOrange)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBtnBase,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'About Calculator',
          style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Neumorphic Calculator App',
              style: TextStyle(color: kOrange, fontWeight: FontWeight.w600, fontSize: 15),
            ),
            SizedBox(height: 8),
            Text(
              '• Cross-platform SQLite offline history\n'
              '• Unit converter & Tip calculator\n'
              '• 3D Box visualizer & measurements\n'
              '• Full keyboard & numpad support\n'
              '• Gesture backspace & tactile interactions',
              style: TextStyle(color: kTextSecondary, height: 1.5, fontSize: 13),
            ),
            SizedBox(height: 12),
            Text(
              'Version 1.1.0',
              style: TextStyle(color: kTextSecondary, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: kOrange)),
          ),
        ],
      ),
    );
  }

  static Widget _buildShortcutRow(String keyStr, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1B1B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF333333)),
            ),
            child: Text(
              keyStr,
              style: const TextStyle(color: kOrange, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          Text(desc, style: const TextStyle(color: kTextSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: kBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: kBtnBase,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: kShadowLight, offset: Offset(-2, -2), blurRadius: 4),
                        BoxShadow(color: kShadowDark, offset: Offset(2, 2), blurRadius: 4),
                      ],
                    ),
                    child: const Icon(Icons.calculate_rounded, color: kOrange, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CALCULATOR',
                        style: TextStyle(
                          color: kTextPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Features & Tools',
                        style: TextStyle(color: kTextSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF2A2A2A), height: 1),

            // Scrollable Menu Options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 12, bottom: 8, top: 4),
                    child: Text(
                      'MODES & TOOLS',
                      style: TextStyle(color: kTextSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                    ),
                  ),
                  _buildDrawerItem(
                    icon: Icons.calculate_outlined,
                    title: 'Standard Calculator',
                    subtitle: 'Active mode',
                    isSelected: true,
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildDrawerItem(
                    icon: Icons.swap_horiz_rounded,
                    title: 'Unit Converter',
                    subtitle: 'Length, Weight, Temperature',
                    onTap: () async {
                      Navigator.pop(context);
                      final res = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UnitConverterScreen(initialValue: currentDisplay),
                        ),
                      );
                      if (res != null) onValueSelected(res);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.receipt_long_rounded,
                    title: 'Tip & Split Bill',
                    subtitle: 'Calculate tips & group splits',
                    onTap: () async {
                      Navigator.pop(context);
                      final res = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TipCalculatorScreen(initialBill: currentDisplay),
                        ),
                      );
                      if (res != null) onValueSelected(res);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.view_in_ar_rounded,
                    title: '3D Box Measurement',
                    subtitle: 'Dimensions, volume & 3D visualizer',
                    onTap: () async {
                      Navigator.pop(context);
                      final res = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BoxMeasurementScreen(initialValue: currentDisplay),
                        ),
                      );
                      if (res != null) onValueSelected(res);
                    },
                  ),
                  const SizedBox(height: 14),
                  const Padding(
                    padding: EdgeInsets.only(left: 12, bottom: 8),
                    child: Text(
                      'DATA & HISTORY',
                      style: TextStyle(color: kTextSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                    ),
                  ),
                  _buildDrawerItem(
                    icon: Icons.history_rounded,
                    title: 'Calculation History',
                    subtitle: 'View saved SQLite records',
                    onTap: () async {
                      Navigator.pop(context);
                      final res = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(builder: (_) => const HistoryScreen()),
                      );
                      if (res != null) onValueSelected(res);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.receipt_long_outlined,
                    title: 'Tip & Split History',
                    subtitle: 'View saved group bills',
                    onTap: () async {
                      Navigator.pop(context);
                      final res = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TipHistoryScreen()),
                      );
                      if (res is TipCalculation) {
                        onValueSelected(res.perPerson.toStringAsFixed(2));
                      }
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.delete_sweep_rounded,
                    title: 'Clear History',
                    subtitle: 'Delete all saved records',
                    onTap: () async {
                      Navigator.pop(context);
                      await HistoryDb.instance.clearAllHistory();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: kBtnBase,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            content: const Text('History cleared', style: TextStyle(color: kTextPrimary)),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  const Padding(
                    padding: EdgeInsets.only(left: 12, bottom: 8),
                    child: Text(
                      'PREFERENCES & HELP',
                      style: TextStyle(color: kTextSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                    ),
                  ),
                  _buildDrawerItem(
                    icon: Icons.keyboard_outlined,
                    title: 'Keyboard Shortcuts',
                    subtitle: 'Quick reference guide',
                    onTap: () {
                      Navigator.pop(context);
                      _showShortcutsDialog(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.info_outline_rounded,
                    title: 'About Calculator',
                    subtitle: 'v1.1.0 • Neumorphic UI',
                    onTap: () {
                      Navigator.pop(context);
                      _showAboutDialog(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2C251C) : kBtnBase,
        borderRadius: BorderRadius.circular(16),
        border: isSelected ? Border.all(color: kOrange.withValues(alpha: 0.5), width: 1) : null,
        boxShadow: const [
          BoxShadow(color: kShadowLight, offset: Offset(-1.5, -1.5), blurRadius: 3),
          BoxShadow(color: kShadowDark, offset: Offset(1.5, 1.5), blurRadius: 3),
        ],
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon, color: isSelected ? kOrange : kTextSecondary, size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? kOrange : kTextPrimary,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(color: kTextSecondary.withValues(alpha: 0.8), fontSize: 11),
              )
            : null,
        trailing: isSelected ? const Icon(Icons.check_rounded, color: kOrange, size: 18) : null,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
      ),
    );
  }
}
