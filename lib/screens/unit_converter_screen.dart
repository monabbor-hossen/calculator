import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../core/utils/number_formatter.dart';
import '../features/unit_converter/domain/services/unit_converter_service.dart';
import '../widgets/neumorphic_icon_button.dart';

class UnitConverterScreen extends StatefulWidget {
  final String? initialValue;
  const UnitConverterScreen({super.key, this.initialValue});

  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> {
  static const _converterService = UnitConverterService();
  static const Map<String, List<String>> _units = UnitConverterService.categoriesWithUnits;

  String _category = 'Length';
  String _inputValue = '1';
  late String _fromUnit;
  late String _toUnit;

  @override
  void initState() {
    super.initState();
    final init = widget.initialValue != null && double.tryParse(widget.initialValue!) != null
        ? widget.initialValue!
        : '1';
    _inputValue = init;
    _fromUnit = _units[_category]![0];
    _toUnit   = _units[_category]![1];
  }

  void _onCategoryChanged(String cat) {
    setState(() {
      _category = cat;
      _fromUnit = _units[cat]![0];
      _toUnit   = _units[cat]![1];
    });
  }

  void _swapUnits() {
    setState(() {
      final temp = _fromUnit;
      _fromUnit  = _toUnit;
      _toUnit    = temp;
    });
  }

  void _onKeypadTap(String key) {
    HapticFeedback.lightImpact();
    setState(() {
      if (key == 'AC') {
        _inputValue = '0';
      } else if (key == '⌫') {
        if (_inputValue.length > 1) {
          _inputValue = _inputValue.substring(0, _inputValue.length - 1);
          if (_inputValue == '-' || _inputValue == '-0') _inputValue = '0';
        } else {
          _inputValue = '0';
        }
      } else if (key == '+/-') {
        if (_inputValue.startsWith('-')) {
          _inputValue = _inputValue.substring(1);
        } else if (_inputValue != '0') {
          _inputValue = '-$_inputValue';
        }
      } else if (key == '.') {
        if (!_inputValue.contains('.')) {
          _inputValue = '$_inputValue.';
        }
      } else {
        // Digits
        if (_inputValue == '0') {
          _inputValue = key;
        } else if (_inputValue.replaceAll('-', '').replaceAll('.', '').length < 9) {
          _inputValue += key;
        }
      }
    });
  }

  String _calculateResult() {
    final raw = double.tryParse(_inputValue.trim());
    if (raw == null) return '0';

    final converted = _converterService.convert(
      category: _category,
      value: raw,
      fromUnit: _fromUnit,
      toUnit: _toUnit,
    );

    return NumberFormatter.format(converted, 4);
  }

  @override
  Widget build(BuildContext context) {
    final resultStr = _calculateResult();

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
                      NeumorphicIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Unit Converter',
                        style: TextStyle(
                          color: kTextPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      // Use in calculator top button
                      GestureDetector(
                        onTap: () => Navigator.pop(context, resultStr),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: kOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: kOrange.withValues(alpha: 0.5)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_rounded, color: kOrange, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Done',
                                style: TextStyle(color: kOrange, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Category Selector Pills (Scrollable) ──────────────────
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _units.keys.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final cat = _units.keys.elementAt(idx);
                        final isSelected = _category == cat;
                        return GestureDetector(
                          onTap: () => _onCategoryChanged(cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? kOrange : kBtnBase,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: kOrange.withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : const [
                                      BoxShadow(color: kShadowLight, offset: Offset(-1.5, -1.5), blurRadius: 3),
                                      BoxShadow(color: kShadowDark, offset: Offset(1.5, 1.5), blurRadius: 3),
                                    ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: isSelected ? Colors.white : kTextSecondary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Conversion Cards Area ─────────────────────────────────
                  Expanded(
                    flex: 4,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          children: [
                            // FROM Card
                            Expanded(
                              child: _buildValueCard(
                                label: 'FROM',
                                selectedUnit: _fromUnit,
                                value: NumberFormatter.addCommas(_inputValue),
                                unitList: _units[_category]!,
                                onUnitChanged: (val) => setState(() => _fromUnit = val!),
                                isHighlighted: false,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // TO Card
                            Expanded(
                              child: _buildValueCard(
                                label: 'TO',
                                selectedUnit: _toUnit,
                                value: NumberFormatter.addCommas(resultStr),
                                unitList: _units[_category]!,
                                onUnitChanged: (val) => setState(() => _toUnit = val!),
                                isHighlighted: true,
                              ),
                            ),
                          ],
                        ),
                        // Swap Button floating between cards
                        _buildSwapButton(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Integrated Keypad (Fills the bottom half!) ─────────────
                  Expanded(
                    flex: 5,
                    child: _buildKeypad(resultStr),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildValueCard({
    required String label,
    required String selectedUnit,
    required String value,
    required List<String> unitList,
    required ValueChanged<String?> onUnitChanged,
    required bool isHighlighted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: kBtnBase,
        borderRadius: BorderRadius.circular(20),
        border: isHighlighted ? Border.all(color: kOrange.withValues(alpha: 0.35), width: 1) : null,
        boxShadow: const [
          BoxShadow(color: kShadowLight, offset: Offset(-2.5, -2.5), blurRadius: 5),
          BoxShadow(color: kShadowDark, offset: Offset(2.5, 2.5), blurRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Unit Dropdown Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: kTextSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              DropdownButton<String>(
                value: selectedUnit,
                dropdownColor: const Color(0xFF242424),
                underline: const SizedBox(),
                isDense: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: kOrange, size: 18),
                items: unitList.map((u) {
                  return DropdownMenuItem(
                    value: u,
                    child: Text(
                      u,
                      style: const TextStyle(color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.w400),
                    ),
                  );
                }).toList(),
                onChanged: onUnitChanged,
              ),
            ],
          ),
          // Value text
          Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: TextStyle(
                  color: isHighlighted ? kOrange : kTextPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwapButton() {
    return GestureDetector(
      onTap: _swapUnits,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: kBtnBase,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF333333)),
          boxShadow: const [
            BoxShadow(color: kShadowLight, offset: Offset(-2, -2), blurRadius: 4),
            BoxShadow(color: kShadowDark, offset: Offset(2, 2), blurRadius: 4),
          ],
        ),
        child: const Icon(Icons.swap_vert_rounded, color: kOrange, size: 22),
      ),
    );
  }

  Widget _buildKeypad(String resultStr) {
    return Column(
      children: [
        Expanded(child: _buildKeypadRow(['7', '8', '9', 'AC'])),
        const SizedBox(height: 8),
        Expanded(child: _buildKeypadRow(['4', '5', '6', '⌫'])),
        const SizedBox(height: 8),
        Expanded(child: _buildKeypadRow(['1', '2', '3', '+/-'])),
        const SizedBox(height: 8),
        Expanded(child: _buildBottomKeypadRow(resultStr)),
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

  Widget _buildBottomKeypadRow(String resultStr) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 1, child: _buildKeypadButton('0')),
        const SizedBox(width: 8),
        Expanded(flex: 1, child: _buildKeypadButton('.')),
        const SizedBox(width: 8),
        // Large action button: Use in Calculator
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: () => Navigator.pop(context, resultStr),
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
                    'Use in Calc',
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
    );
  }

  Widget _buildKeypadButton(String label) {
    final isAction = label == 'AC' || label == '⌫' || label == '+/-';
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
}
