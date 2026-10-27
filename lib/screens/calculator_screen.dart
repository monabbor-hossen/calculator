import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../data/history_db.dart';
import '../logic/calculator_logic.dart';
import '../widgets/app_drawer.dart';
import '../widgets/calc_button.dart';
import '../widgets/display_section.dart';
import 'history_screen.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final CalculatorLogic _logic = CalculatorLogic();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Auto-focus so physical keyboard works immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onTap(String label) {
    final hadOperator = _logic.activeOperator.isNotEmpty;
    setState(() => _logic.input(label));
    if (label == '=' && hadOperator && _logic.display != 'Error') {
      HistoryDb.instance.insertCalculation(_logic.preview, _logic.display);
    }
  }

  void _onBackspace() {
    setState(() => _logic.backspace());
  }

  Future<void> _openHistory() async {
    final selectedResult = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
    if (selectedResult != null && mounted) {
      setState(() {
        _logic.loadValue(selectedResult);
      });
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final isControlOrCmd = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    // Handle Ctrl+C (Copy current display)
    if (isControlOrCmd && key == LogicalKeyboardKey.keyC) {
      Clipboard.setData(ClipboardData(text: _logic.display));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: kBtnBase,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            'Copied ${_logic.display} to clipboard',
            style: const TextStyle(color: kTextPrimary),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
      return KeyEventResult.handled;
    }

    // Handle Ctrl+V (Paste into calculator)
    if (isControlOrCmd && key == LogicalKeyboardKey.keyV) {
      Clipboard.getData('text/plain').then((data) {
        if (data?.text != null && mounted) {
          setState(() {
            _logic.paste(data!.text!);
          });
        }
      });
      return KeyEventResult.handled;
    }

    // Numbers 0-9
    if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
      _onTap('0');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
      _onTap('1');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
      _onTap('2');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
      _onTap('3');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
      _onTap('4');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) {
      _onTap('5');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) {
      _onTap('6');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) {
      _onTap('7');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) {
      _onTap('8');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) {
      _onTap('9');
      return KeyEventResult.handled;
    }

    // Operations
    if (key == LogicalKeyboardKey.add || key == LogicalKeyboardKey.numpadAdd) {
      _onTap('+');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.minus || key == LogicalKeyboardKey.numpadSubtract) {
      _onTap('−');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.asterisk || key == LogicalKeyboardKey.numpadMultiply) {
      _onTap('×');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.slash || key == LogicalKeyboardKey.numpadDivide) {
      _onTap('÷');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.period || key == LogicalKeyboardKey.numpadDecimal || key == LogicalKeyboardKey.comma) {
      _onTap('.');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter || key == LogicalKeyboardKey.equal) {
      _onTap('=');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace) {
      _onBackspace();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.delete) {
      _onTap(_logic.canClearEntry ? 'C' : 'AC');
      return KeyEventResult.handled;
    }

    // Check character for shift keys like + and * and %
    if (event.character != null) {
      switch (event.character) {
        case '+':
          _onTap('+');
          return KeyEventResult.handled;
        case '-':
          _onTap('−');
          return KeyEventResult.handled;
        case '*':
          _onTap('×');
          return KeyEventResult.handled;
        case '/':
          _onTap('÷');
          return KeyEventResult.handled;
        case '=':
          _onTap('=');
          return KeyEventResult.handled;
        case '%':
          _onTap('%');
          return KeyEventResult.handled;
        case 'c':
        case 'C':
          _onTap(_logic.canClearEntry ? 'C' : 'AC');
          return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: kBg,
      drawer: AppDrawer(
        currentDisplay: _logic.display,
        onValueSelected: (val) {
          setState(() {
            _logic.loadValue(val);
          });
        },
      ),
      body: SafeArea(
        child: Center(
          // Constrain maximum width for desktop & web ergonomics
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Focus(
              focusNode: _focusNode,
              autofocus: true,
              onKeyEvent: _handleKeyEvent,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final sizes = AppSizes(
                    width:  constraints.maxWidth,
                    height: constraints.maxHeight,
                  );
                  final pad = sizes.screenPadding;

                  return Padding(
                    padding: EdgeInsets.fromLTRB(pad, pad * 0.5, pad, pad),
                    child: Column(
                      children: [
                        // Top bar with Menu on left, History on right
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMenuButton(sizes),
                            _buildHistoryButton(sizes),
                          ],
                        ),
                        // Display
                        Expanded(
                          flex: 3,
                          child: DisplaySection(
                            display: _logic.display,
                            preview: _logic.preview,
                            sizes:   sizes,
                            onBackspace: _onBackspace,
                          ),
                        ),
                        SizedBox(height: sizes.gap * 1.5),
                        // Button grid
                        Expanded(
                          flex: 7,
                          child: _buildGrid(sizes),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(AppSizes sizes) {
    final btnSize = (sizes.width * 0.11).clamp(38.0, 48.0);
    return Tooltip(
      message: 'Menu & More Features',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(btnSize / 2),
          onTap: () {
            HapticFeedback.lightImpact();
            _scaffoldKey.currentState?.openDrawer();
          },
          child: Container(
            width: btnSize,
            height: btnSize,
            decoration: const BoxDecoration(
              color: kBtnBase,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kShadowLight,
                  offset: Offset(-2.5, -2.5),
                  blurRadius: 5,
                ),
                BoxShadow(
                  color: kShadowDark,
                  offset: Offset(2.5, 2.5),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.menu_rounded,
              color: kTextPrimary,
              size: btnSize * 0.50,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryButton(AppSizes sizes) {
    final btnSize = (sizes.width * 0.11).clamp(38.0, 48.0);
    return Tooltip(
      message: 'History',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(btnSize / 2),
          onTap: _openHistory,
          child: Container(
            width: btnSize,
            height: btnSize,
            decoration: const BoxDecoration(
              color: kBtnBase,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kShadowLight,
                  offset: Offset(-2.5, -2.5),
                  blurRadius: 5,
                ),
                BoxShadow(
                  color: kShadowDark,
                  offset: Offset(2.5, 2.5),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.history_rounded,
              color: kOrange,
              size: btnSize * 0.52,
            ),
          ),
        ),
      ),
    );
  }

  // ── Grid ──────────────────────────────────────────────────────────────────
  Widget _buildGrid(AppSizes sizes) {
    final gap = sizes.gap;
    final clearLabel = _logic.canClearEntry ? 'C' : 'AC';
    return Column(
      children: [
        _buttonRow([clearLabel, '+/-', '%', '÷'], sizes),
        SizedBox(height: gap),
        _buttonRow(['7', '8', '9', '×'], sizes),
        SizedBox(height: gap),
        _buttonRow(['4', '5', '6', '−'], sizes),
        SizedBox(height: gap),
        _buttonRow(['1', '2', '3', '+'], sizes),
        SizedBox(height: gap),
        _buttonRow(['0', '.', '⌫', '='], sizes),
      ],
    );
  }

  /// Standard 4-column row — buttons separated by [sizes.gap], no edge padding.
  Widget _buttonRow(List<String> labels, AppSizes sizes) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < labels.length; i++) ...[
            if (i > 0) SizedBox(width: sizes.gap),
            Expanded(
              child: CalcButton(
                label:       labels[i],
                sizes:       sizes,
                isActive:    _logic.activeOperator == labels[i],
                onTap:       () => _onTap(labels[i]),
                onLongPress: labels[i] == '⌫'
                    ? () {
                        HapticFeedback.mediumImpact();
                        _onTap('AC');
                      }
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
