import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class UnitConverterScreen extends StatefulWidget {
  final String? initialValue;
  const UnitConverterScreen({super.key, this.initialValue});

  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> {
  String _category = 'Length';
  String _inputValue = '1';
  late String _fromUnit;
  late String _toUnit;

  final Map<String, List<String>> _units = {
    'Length': ['Meter (m)', 'Kilometer (km)', 'Centimeter (cm)', 'Millimeter (mm)', 'Foot (ft)', 'Inch (in)', 'Mile (mi)', 'Yard (yd)'],
    'Weight': ['Kilogram (kg)', 'Gram (g)', 'Pound (lb)', 'Ounce (oz)', 'Ton (t)'],
    'Temperature': ['Celsius (°C)', 'Fahrenheit (°F)', 'Kelvin (K)'],
    'Speed': ['km/h', 'mph', 'm/s', 'Knot (kn)'],
    'Area': ['Sq Meter (m²)', 'Sq Km (km²)', 'Sq Foot (ft²)', 'Acre (ac)', 'Hectare (ha)'],
  };

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

  double _convertLength(double val, String from, String to) {
    final toMeters = {
      'Meter (m)': 1.0,
      'Kilometer (km)': 1000.0,
      'Centimeter (cm)': 0.01,
      'Millimeter (mm)': 0.001,
      'Foot (ft)': 0.3048,
      'Inch (in)': 0.0254,
      'Mile (mi)': 1609.344,
      'Yard (yd)': 0.9144,
    };
    final meters = val * (toMeters[from] ?? 1.0);
    return meters / (toMeters[to] ?? 1.0);
  }

  double _convertWeight(double val, String from, String to) {
    final toKg = {
      'Kilogram (kg)': 1.0,
      'Gram (g)': 0.001,
      'Pound (lb)': 0.45359237,
      'Ounce (oz)': 0.0283495,
      'Ton (t)': 1000.0,
    };
    final kg = val * (toKg[from] ?? 1.0);
    return kg / (toKg[to] ?? 1.0);
  }

  double _convertTemperature(double val, String from, String to) {
    double celsius;
    if (from.contains('Celsius')) {
      celsius = val;
    } else if (from.contains('Fahrenheit')) {
      celsius = (val - 32) * 5 / 9;
    } else {
      celsius = val - 273.15;
    }

    if (to.contains('Celsius')) return celsius;
    if (to.contains('Fahrenheit')) return (celsius * 9 / 5) + 32;
    return celsius + 273.15;
  }

  double _convertSpeed(double val, String from, String to) {
    final toMs = {
      'm/s': 1.0,
      'km/h': 0.277778,
      'mph': 0.44704,
      'Knot (kn)': 0.514444,
    };
    final ms = val * (toMs[from] ?? 1.0);
    return ms / (toMs[to] ?? 1.0);
  }

  double _convertArea(double val, String from, String to) {
    final toSqMeters = {
      'Sq Meter (m²)': 1.0,
      'Sq Km (km²)': 1000000.0,
      'Sq Foot (ft²)': 0.092903,
      'Acre (ac)': 4046.86,
      'Hectare (ha)': 10000.0,
    };
    final sqM = val * (toSqMeters[from] ?? 1.0);
    return sqM / (toSqMeters[to] ?? 1.0);
  }

  String _calculateResult() {
    final raw = double.tryParse(_inputValue.trim());
    if (raw == null) return '0';

    double converted;
    if (_category == 'Length') {
      converted = _convertLength(raw, _fromUnit, _toUnit);
    } else if (_category == 'Weight') {
      converted = _convertWeight(raw, _fromUnit, _toUnit);
    } else if (_category == 'Temperature') {
      converted = _convertTemperature(raw, _fromUnit, _toUnit);
    } else if (_category == 'Speed') {
      converted = _convertSpeed(raw, _fromUnit, _toUnit);
    } else {
      converted = _convertArea(raw, _fromUnit, _toUnit);
    }

    if (converted == converted.truncateToDouble() && converted.abs() < 1e9) {
      return converted.toInt().toString();
    }
    return converted.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  String _addCommas(String raw) {
    if (raw == 'Error' || raw.isEmpty) return raw;
    final negative = raw.startsWith('-');
    final abs      = negative ? raw.substring(1) : raw;
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
                      _buildHeaderButton(
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
                                value: _addCommas(_inputValue),
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
                                value: _addCommas(resultStr),
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
