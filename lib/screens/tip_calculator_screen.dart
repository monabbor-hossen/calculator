import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../data/history_db.dart';
import '../data/tip_calculation_model.dart';
import 'tip_history_screen.dart';

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
  String _currency = '৳'; // Default to Bangladeshi Taka (৳)

  // 0% option included as requested
  final List<double> _tipOptions = [0.0, 10.0, 15.0, 18.0, 20.0, 25.0];

  final List<Map<String, String>> _currencyOptions = const [
    {'symbol': '৳', 'code': 'BDT', 'name': 'Bangladeshi Taka'},
    {'symbol': '\$', 'code': 'USD', 'name': 'US Dollar'},
    {'symbol': '€', 'code': 'EUR', 'name': 'Euro'},
    {'symbol': '£', 'code': 'GBP', 'name': 'British Pound'},
    {'symbol': '₹', 'code': 'INR', 'name': 'Indian Rupee'},
    {'symbol': '¥', 'code': 'JPY', 'name': 'Japanese Yen'},
    {'symbol': 'AED', 'code': 'AED', 'name': 'UAE Dirham'},
    {'symbol': 'SAR', 'code': 'SAR', 'name': 'Saudi Riyal'},
  ];

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

  Future<void> _saveCurrentCalculation({bool showToast = true}) async {
    if (_bill <= 0) {
      if (showToast && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: kBtnBase,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Text('Please enter a bill amount first', style: TextStyle(color: kTextPrimary)),
            duration: const Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    final calc = TipCalculation(
      bill: _bill,
      tipPercent: _tipPercent,
      tipAmount: _tipAmount,
      total: _totalBill,
      people: _splitPeople,
      perPerson: _perPerson,
      currency: _currency,
    );

    await HistoryDb.instance.insertTipCalculation(calc);
    HapticFeedback.mediumImpact();

    if (showToast && mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: kBtnBase,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            'Saved to history: $_currency${_fmt(_perPerson)} / person',
            style: const TextStyle(color: kTextPrimary),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openHistory() async {
    final restored = await Navigator.push<TipCalculation>(
      context,
      MaterialPageRoute(builder: (_) => const TipHistoryScreen()),
    );

    if (restored != null && mounted) {
      setState(() {
        _currency = restored.currency;
        _billInput = restored.bill.toStringAsFixed(
          restored.bill.truncateToDouble() == restored.bill ? 0 : 2,
        );
        _tipPercent = restored.tipPercent;
        _splitPeople = restored.people;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: kBtnBase,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            'Loaded split: $_currency${_fmt(_perPerson)} / person',
            style: const TextStyle(color: kTextPrimary),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _copyBreakdown() {
    final text = 'Bill: $_currency${_fmt(_bill)}\n'
        'Tip (${_tipPercent.toInt()}%): $_currency${_fmt(_tipAmount)}\n'
        'Total: $_currency${_fmt(_totalBill)}\n'
        'Split: $_splitPeople ${_splitPeople == 1 ? "Person" : "People"}\n'
        'Each Pays: $_currency${_fmt(_perPerson)}';

    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kBtnBase,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Text('Breakdown copied to clipboard', style: TextStyle(color: kTextPrimary)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showCurrencySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kBtnBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Currency',
                      style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: kTextSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 320,
                  child: ListView.builder(
                    itemCount: _currencyOptions.length,
                    itemBuilder: (context, i) {
                      final opt = _currencyOptions[i];
                      final isSelected = _currency == opt['symbol'];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        tileColor: isSelected ? const Color(0xFF333333) : Colors.transparent,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected ? kOrange : const Color(0xFF222222),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            opt['symbol']!,
                            style: TextStyle(
                              color: isSelected ? Colors.white : kOrange,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          opt['name']!,
                          style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          opt['code']!,
                          style: const TextStyle(color: kTextSecondary, fontSize: 12),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: kOrange)
                            : null,
                        onTap: () {
                          setState(() {
                            _currency = opt['symbol']!;
                          });
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
                        tooltip: 'Back',
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Tip & Split Bill',
                        style: TextStyle(
                          color: kTextPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      // Save to history button
                      _buildHeaderButton(
                        icon: Icons.bookmark_add_outlined,
                        color: kOrange,
                        tooltip: 'Save to History',
                        onTap: () => _saveCurrentCalculation(showToast: true),
                      ),
                      const SizedBox(width: 8),
                      // Copy summary button
                      _buildHeaderButton(
                        icon: Icons.copy_rounded,
                        tooltip: 'Copy Breakdown',
                        onTap: _copyBreakdown,
                      ),
                      const SizedBox(width: 8),
                      // History button
                      _buildHeaderButton(
                        icon: Icons.history_rounded,
                        color: kOrange,
                        tooltip: 'Split History',
                        onTap: _openHistory,
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
                          // Bill Row with Currency selector
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'BILL AMOUNT',
                                    style: TextStyle(
                                      color: kTextSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildCurrencySelector(),
                                ],
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '$_currency $_billInput',
                                  style: const TextStyle(
                                    color: kTextPrimary,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Color(0xFF2C2C2C), height: 10),

                          // Tip Percentage selector (0% included!)
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
                                        fontSize: 11.5,
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
                                  const Text(
                                    'EACH PAYS',
                                    style: TextStyle(
                                      color: kTextSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  Text(
                                    'Total: $_currency${_fmt(_totalBill)}',
                                    style: const TextStyle(color: kTextSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                              Text(
                                '$_currency${_fmt(_perPerson)}',
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

  Widget _buildCurrencySelector() {
    return GestureDetector(
      onTap: _showCurrencySelector,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF202020),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kOrange.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _currency,
              style: const TextStyle(
                color: kOrange,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, color: kOrange, size: 14),
          ],
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
                  onTap: () async {
                    await _saveCurrentCalculation(showToast: false);
                    if (mounted) {
                      Navigator.pop(context, _fmt(_perPerson));
                    }
                  },
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
    Color color = kTextPrimary,
    String? tooltip,
  }) {
    Widget button = GestureDetector(
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
        child: Icon(icon, color: color, size: 18),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: button);
    }
    return button;
  }
}
