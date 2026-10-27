/// Pure calculator logic — no Flutter/UI dependencies.
class CalculatorLogic {
  String display = '0';
  String preview = '';

  double _operand1 = 0;
  String _operator = '';
  bool _newInput = true;
  bool _hasDecimal = false;
  bool _justCalculated = false;

  // ── Public entry point ────────────────────────────────────────────────────
  void input(String value) {
    switch (value) {
      case 'AC':
        _reset();
      case 'C':
        _clearEntry();
      case '⌫':
        backspace();
      case '+/-':
        _negate();
      case '%':
        _percent();
      case '÷':
      case '×':
      case '−':
      case '+':
        _setOperator(value);
      case '=':
        _calculate();
      case '.':
        _addDecimal();
      default:
        _addDigit(value);
    }
  }

  String get activeOperator => _operator;

  bool get canClearEntry => display != '0' && !_justCalculated;

  void backspace() {
    if (_justCalculated) {
      _justCalculated = false;
      _newInput = false;
      preview = '';
      if (display.length > 1) {
        display = display.substring(0, display.length - 1);
      } else {
        display = '0';
        _newInput = true;
      }
      return;
    }

    if (_operator.isNotEmpty && _newInput) {
      _operator = '';
      preview = '';
      _newInput = false;
      return;
    }

    if (display == '0') return;

    if (_newInput) {
      _newInput = false;
    }

    if (display.length > 1) {
      if (display.endsWith('.')) {
        _hasDecimal = false;
      }
      display = display.substring(0, display.length - 1);
      if (display == '-' || display == '-0') {
        display = '0';
        _newInput = true;
      }
    } else {
      display = '0';
      _newInput = true;
    }
    _updateLivePreview();
  }

  void paste(String text) {
    final clean = text.trim().replaceAll(',', '');
    final val = double.tryParse(clean);
    if (val != null) {
      display = _fmt(val);
      _newInput = true;
      _hasDecimal = display.contains('.');
      _justCalculated = false;
      _updateLivePreview();
    }
  }

  void loadValue(String val) {
    display = val;
    preview = '';
    _operand1 = double.tryParse(val) ?? 0;
    _operator = '';
    _newInput = true;
    _hasDecimal = val.contains('.');
    _justCalculated = false;
  }

  // ── Private helpers ───────────────────────────────────────────────────────
  void _reset() {
    display = '0';
    preview = '';
    _operand1 = 0;
    _operator = '';
    _newInput = true;
    _hasDecimal = false;
    _justCalculated = false;
  }

  void _clearEntry() {
    display = '0';
    _newInput = true;
    _hasDecimal = false;
    _updateLivePreview();
  }

  void _negate() {
    final val = (double.tryParse(display) ?? 0) * -1;
    display = _fmt(val);
  }

  void _percent() {
    final val = (double.tryParse(display) ?? 0) / 100;
    display = _fmt(val);
    _newInput = true;
    _hasDecimal = display.contains('.');
  }

  void _addDigit(String digit) {
    if (_newInput || _justCalculated) {
      display = digit;
      _newInput = false;
      _hasDecimal = false;
      _justCalculated = false;
    } else {
      final clean = display.replaceAll('-', '').replaceAll('.', '');
      if (display == '0') {
        display = digit;
      } else if (clean.length < 9) {
        display += digit;
      }
    }
    _updateLivePreview();
  }

  void _addDecimal() {
    if (_newInput || _justCalculated) {
      display = '0.';
      _newInput = false;
      _hasDecimal = true;
      _justCalculated = false;
    } else if (!_hasDecimal) {
      display += '.';
      _hasDecimal = true;
    }
    _updateLivePreview();
  }

  void _setOperator(String op) {
    if (_operator.isNotEmpty && !_newInput) {
      _calculate(keepOperator: true);
    }
    _operand1 = double.tryParse(display) ?? 0;
    _operator = op;
    preview = '${_fmt(_operand1)} $op';
    _newInput = true;
    _hasDecimal = false;
    _justCalculated = false;
  }

  void _calculate({bool keepOperator = false}) {
    if (_operator.isEmpty) return;

    final operand2 = double.tryParse(display) ?? 0;
    final double result;

    switch (_operator) {
      case '+':
        result = _operand1 + operand2;
      case '−':
        result = _operand1 - operand2;
      case '×':
        result = _operand1 * operand2;
      case '÷':
        if (operand2 == 0) {
          display = 'Error';
          preview = '';
          _operator = '';
          _newInput = true;
          return;
        }
        result = _operand1 / operand2;
      default:
        return;
    }

    if (!keepOperator) {
      preview = '${_fmt(_operand1)} $_operator ${_fmt(operand2)} =';
      _operator = '';
    }

    display = _fmt(result);
    _operand1 = result;
    _newInput = true;
    _hasDecimal = display.contains('.');
    _justCalculated = true;
  }

  void _updateLivePreview() {
    if (_operator.isNotEmpty) {
      preview = '${_fmt(_operand1)} $_operator $display';
    } else {
      preview = '';
    }
  }

  /// Format a double: prefer integer string, otherwise trim trailing zeros.
  String _fmt(double value) {
    if (value == value.truncateToDouble() && value.abs() < 1e9) {
      return value.toInt().toString();
    }
    return value
        .toStringAsFixed(8)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}
