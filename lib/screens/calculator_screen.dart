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
  bool _showScientific = false;

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
    final prevDisplay = _logic.display;
    setState(() => _logic.input(label));
    if (label == '=' && _logic.display != 'Error' && _logic.preview.isNotEmpty) {
      final expr = _logic.preview.endsWith('=')
          ? _logic.preview.substring(0, _logic.preview.length - 1).trim()
          : prevDisplay;
      HistoryDb.instance.insertCalculation(expr, _logic.display);
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
        case '^':
          _onTap('^');
          return KeyEventResult.handled;
        case '!':
          _onTap('!');
          return KeyEventResult.handled;
        case '(':
          _onTap('(');
          return KeyEventResult.handled;
        case ')':
          _onTap(')');
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
                          flex: _showScientific ? 2 : 3,
                          child: DisplaySection(
                            display: _logic.display,
                            preview: _logic.preview,
                            sizes:   sizes,
                            onBackspace: _onBackspace,
                            angleMode: _showScientific ? (_logic.isRadians ? 'RAD' : 'DEG') : null,
                          ),
                        ),
                        SizedBox(height: sizes.gap),
                        // Calculation Options Toolbar (%, √, x², +/-, π, fx)
                        _buildCalculationToolbar(sizes),
                        // Expanded Scientific Panel (if _showScientific)
                        if (_showScientific) ...[
                          SizedBox(height: sizes.gap * 0.7),
                          _buildScientificPanel(sizes),
                        ],
                        SizedBox(height: sizes.gap),
                        // Button grid
                        Expanded(
                          flex: _showScientific ? 6 : 7,
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

  // ── Calculation Options Toolbar & Scientific Panel ───────────────────────
  Widget _buildCalculationToolbar(AppSizes sizes) {
    final height = (sizes.height * 0.052).clamp(36.0, 44.0);
    final gap = sizes.gap * 0.8;
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildToolBtn(label: '%', onTap: () => _onTap('%'), isAccent: true)),
          SizedBox(width: gap),
          Expanded(child: _buildToolBtn(label: '√', onTap: () => _onTap('√'), isAccent: true)),
          SizedBox(width: gap),
          Expanded(child: _buildToolBtn(label: 'x²', onTap: () => _onTap('x²'), isAccent: true)),
          SizedBox(width: gap),
          Expanded(child: _buildToolBtn(label: '+/-', onTap: () => _onTap('+/-'), isAccent: true)),
          SizedBox(width: gap),
          Expanded(child: _buildToolBtn(label: 'π', onTap: () => _onTap('π'), isAccent: true)),
          SizedBox(width: gap),
          Expanded(
            child: _buildToolBtn(
              label: 'fx',
              isActive: _showScientific,
              onTap: () => setState(() => _showScientific = !_showScientific),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScientificPanel(AppSizes sizes) {
    final height = (sizes.height * 0.046).clamp(32.0, 40.0);
    final gap = sizes.gap * 0.7;
    return Column(
      children: [
        // Row 1: DEG/RAD, sin, cos, tan, ^ (xʸ)
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildToolBtn(
                  label: _logic.isRadians ? 'RAD' : 'DEG',
                  isActive: _logic.isRadians,
                  fontSize: 11,
                  onTap: () => setState(() => _logic.toggleAngleMode()),
                ),
              ),
              SizedBox(width: gap),
              Expanded(child: _buildToolBtn(label: 'sin', fontSize: 13, onTap: () => _onTap('sin'))),
              SizedBox(width: gap),
              Expanded(child: _buildToolBtn(label: 'cos', fontSize: 13, onTap: () => _onTap('cos'))),
              SizedBox(width: gap),
              Expanded(child: _buildToolBtn(label: 'tan', fontSize: 13, onTap: () => _onTap('tan'))),
              SizedBox(width: gap),
              Expanded(child: _buildToolBtn(label: '^', fontSize: 14, isAccent: true, onTap: () => _onTap('^'))),
            ],
          ),
        ),
        SizedBox(height: gap),
        // Row 2: log, ln, x!, 1/x, e
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildToolBtn(label: 'log', fontSize: 13, onTap: () => _onTap('log'))),
              SizedBox(width: gap),
              Expanded(child: _buildToolBtn(label: 'ln', fontSize: 13, onTap: () => _onTap('ln'))),
              SizedBox(width: gap),
              Expanded(child: _buildToolBtn(label: 'x!', fontSize: 13, onTap: () => _onTap('!'))),
              SizedBox(width: gap),
              Expanded(child: _buildToolBtn(label: '1/x', fontSize: 12, onTap: () => _onTap('1/x'))),
              SizedBox(width: gap),
              Expanded(child: _buildToolBtn(label: 'e', fontSize: 14, isAccent: true, onTap: () => _onTap('e'))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolBtn({
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    bool isAccent = false,
    double? fontSize,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? kOrange : kBtnBase,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isActive ? kOrange.withValues(alpha: 0.35) : kShadowLight,
              offset: const Offset(-1.5, -1.5),
              blurRadius: 3,
            ),
            BoxShadow(
              color: kShadowDark,
              offset: const Offset(1.5, 1.5),
              blurRadius: 3,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isActive
                ? Colors.white
                : (isAccent ? kOrange : kTextPrimary),
            fontSize: fontSize ?? 14,
            fontWeight: isActive || isAccent ? FontWeight.w600 : FontWeight.w400,
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
        _buttonRow([clearLabel, '(', ')', '÷'], sizes),
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
                    : labels[i] == '('
                        ? () {
                            HapticFeedback.lightImpact();
                            _onTap('+/-');
                          }
                        : labels[i] == ')'
                            ? () {
                                HapticFeedback.lightImpact();
                                _onTap('%');
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
