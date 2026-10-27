import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class TipCalculatorScreen extends StatefulWidget {
  final String? initialBill;
  const TipCalculatorScreen({super.key, this.initialBill});

  @override
  State<TipCalculatorScreen> createState() => _TipCalculatorScreenState();
}

class _TipCalculatorScreenState extends State<TipCalculatorScreen> {
  String _billInput = '100';
  double _tipPercent = 15.0;
  int _splitPeople = 1;

  final List<double> _tipOptions = [10.0, 15.0, 18.0, 20.0, 25.0];

  @override
  void initState() {
    super.initState();
    final init = widget.initialBill != null && double.tryParse(widget.initialBill!) != null
        ? widget.initialBill!
        : '100';
    _billInput = init;
  }

  double get _bill => double.tryParse(_billInput.trim()) ?? 0;
  double get _tipAmount => _bill * (_tipPercent / 100);
  double get _totalBill => _bill + _tipAmount;
  double get _perPerson => _splitPeople > 0 ? _totalBill / _splitPeople : _totalBill;

  String _fmt(double v) => v.toStringAsFixed(2);

  void _onKeypadTap(String key) {
    HapticFeedback.lightImpact();
    setState(() {
      if (key == 'AC') {
        _billInput = '0';
      } else if (key == '⌫') {
        if (_billInput.length > 1) {
          _billInput = _billInput.substring(0, _billInput.length - 1);
        } else {
          _billInput = '0';
        }
      } else if (key == '.') {
        if (!_billInput.contains('.')) {
          _billInput = '$_billInput.';
        }
      } else {
        // Digits
        if (_billInput == '0') {
          _billInput = key;
        } else if (_billInput.replaceAll('.', '').length < 8) {
          _billInput += key;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              child: Column(
                children: [
                  // ── Top Header ──────────────────────────────────────────
                  Row(
                    children: [
                      _buildHeaderButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Tip & Split Bill',
                        style: TextStyle(
                          color: kTextPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      // Copy summary button
                      GestureDetector(
                        onTap: () {
                          final text = 'Bill: \$${_fmt(_bill)}\nTip (${_tipPercent.toInt()}%): \$${_fmt(_tipAmount)}\nTotal: \$${_fmt(_totalBill)}\nPer Person (${_splitPeople}x): \$${_fmt(_perPerson)}';
                          Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: kBtnBase,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              content: const Text('Breakdown copied to clipboard', style: TextStyle(color: kTextPrimary)),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: kBtnBase,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(color: kShadowLight, offset: Offset(-1.5, -1.5), blurRadius: 3),
                              BoxShadow(color: kShadowDark, offset: Offset(1.5, 1.5), blurRadius: 3),
                            ],
                          ),
                          child: const Icon(Icons.copy_rounded, color: kTextSecondary, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── Bill & Split Summary Card ───────────────────────────
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kBtnBase,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(color: kShadowLight, offset: Offset(-2.5, -2.5), blurRadius: 5),
                          BoxShadow(color: kShadowDark, offset: Offset(2.5, 2.5), blurRadius: 5),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Bill Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('BILL AMOUNT', style: TextStyle(color: kTextSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.1)),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '\$ $_billInput',
                                  style: const TextStyle(color: kTextPrimary, fontSize: 26, fontWeight: FontWeight.w300),
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Color(0xFF2C2C2C), height: 10),

                          // Tip Percentage selector
                          Row(
                            children: _tipOptions.map((tip) {
                              final isSelected = _tipPercent == tip;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _tipPercent = tip),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected ? kOrange : const Color(0xFF202020),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${tip.toInt()}%',
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : kTextSecondary,
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const Divider(color: Color(0xFF2C2C2C), height: 10),

                          // Split between people row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Split: $_splitPeople ${_splitPeople == 1 ? "Person" : "People"}',
                                style: const TextStyle(color: kTextSecondary, fontSize: 13),
                              ),
                              Row(
                                children: [
                                  _buildMiniButton(
                                    icon: Icons.remove,
                                    onTap: () {
                                      if (_splitPeople > 1) setState(() => _splitPeople--);
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _buildMiniButton(
                                    icon: Icons.add,
                                    color: kOrange,
                                    onTap: () => setState(() => _splitPeople++),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(color: Color(0xFF2C2C2C), height: 10),

                          // Per person result
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('EACH PAYS', style: TextStyle(color: kTextSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.1)),
                                  Text('Total: \$${_fmt(_totalBill)}', style: const TextStyle(color: kTextSecondary, fontSize: 11)),
                                ],
                              ),
                              Text(
                                '\$${_fmt(_perPerson)}',
                                style: const TextStyle(
                                  color: kOrange,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Integrated Keypad ───────────────────────────────────
                  Expanded(
                    flex: 5,
                    child: _buildKeypad(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Expanded(child: _buildKeypadRow(['7', '8', '9', 'AC'])),
        const SizedBox(height: 8),
        Expanded(child: _buildKeypadRow(['4', '5', '6', '⌫'])),
        const SizedBox(height: 8),
        Expanded(child: _buildKeypadRow(['1', '2', '3', '0'])),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildKeypadButton('.')),
              const SizedBox(width: 8),
              // Use in calculator
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context, _fmt(_perPerson)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: kOrange,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: kOrange.withValues(alpha: 0.35),
                          offset: const Offset(0, 3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Use in Calculator',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < keys.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _buildKeypadButton(keys[i])),
        ],
      ],
    );
  }

  Widget _buildKeypadButton(String label) {
    final isAction = label == 'AC' || label == '⌫';
    final labelColor = isAction ? kOrange : kTextPrimary;

    return GestureDetector(
      onTap: () => _onKeypadTap(label),
      child: Container(
        decoration: BoxDecoration(
          color: kBtnBase,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: kShadowLight, offset: Offset(-2, -2), blurRadius: 4),
            BoxShadow(color: kShadowDark, offset: Offset(2, 2), blurRadius: 4),
          ],
        ),
        alignment: Alignment.center,
        child: label == '⌫'
            ? Icon(
                Icons.backspace_rounded,
                color: labelColor,
                size: 20,
              )
            : Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: isAction ? 18 : 22,
                  fontWeight: FontWeight.w400,
                ),
              ),
      ),
    );
  }

  Widget _buildMiniButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = kTextPrimary,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: kBtnBase,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: kShadowLight, offset: Offset(-2, -2), blurRadius: 4),
            BoxShadow(color: kShadowDark, offset: Offset(2, 2), blurRadius: 4),
          ],
        ),
        child: Icon(icon, color: kTextPrimary, size: 18),
      ),
    );
  }
}
