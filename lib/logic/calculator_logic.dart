import 'expression_parser.dart';

/// Expression-based calculator logic supporting standard BODMAS/PEMDAS precedence,
/// parentheses grouping `(` and `)`, live preview calculation, and error handling.
class CalculatorLogic {
  String display = '0';
  String preview = '';

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
      case '(':
        _addOpenParen();
      case ')':
        _addCloseParen();
      case '+/-':
        _negate();
      case '%':
        _percent();
      case '÷':
      case '×':
      case '−':
      case '+':
        _addOperator(value);
      case '=':
        _calculate();
      case '.':
        _addDecimal();
      default:
        _addDigit(value);
    }
  }

  String get activeOperator {
    final trimmed = display.trim();
    if (trimmed.endsWith('+')) return '+';
    if (trimmed.endsWith('−') || trimmed.endsWith('-')) return '−';
    if (trimmed.endsWith('×') || trimmed.endsWith('*')) return '×';
    if (trimmed.endsWith('÷') || trimmed.endsWith('/')) return '÷';
    return '';
  }

  bool get canClearEntry => display != '0';

  void backspace() {
    if (_justCalculated) {
      _justCalculated = false;
      display = '0';
      preview = '';
      return;
    }

    if (display == '0') return;

    if (display.endsWith(' + ') ||
        display.endsWith(' − ') ||
        display.endsWith(' × ') ||
        display.endsWith(' ÷ ')) {
      display = display.substring(0, display.length - 3);
    } else if (display.length > 1) {
      display = display.substring(0, display.length - 1);
    } else {
      display = '0';
    }

    if (display.isEmpty) {
      display = '0';
    }

    _updateLivePreview();
  }

  void paste(String text) {
    final clean = text.trim().replaceAll(',', '');
    final val = double.tryParse(clean);
    if (val != null) {
      display = _fmt(val);
      _justCalculated = false;
      _updateLivePreview();
    }
  }

  void loadValue(String val) {
    display = val;
    preview = '';
    _justCalculated = false;
  }

  // ── Private helpers ───────────────────────────────────────────────────────
  void _reset() {
    display = '0';
    preview = '';
    _justCalculated = false;
  }

  void _clearEntry() {
    display = '0';
    preview = '';
    _justCalculated = false;
  }

  void _addOpenParen() {
    if (_justCalculated || display == '0' || display == 'Error') {
      display = '(';
      _justCalculated = false;
    } else {
      final trimmed = display.trim();
      final last = trimmed.isNotEmpty ? trimmed[trimmed.length - 1] : '';
      // If after digit, close paren, or percent, add implicit multiplication: ' × ('
      if (_isDigit(last) || last == ')' || last == '%') {
        display += ' × (';
      } else {
        display += '(';
      }
    }
    _updateLivePreview();
  }

  void _addCloseParen() {
    if (display == '0' || display == 'Error' || _justCalculated) return;

    final openCount = '('.allMatches(display).length;
    final closeCount = ')'.allMatches(display).length;
    final trimmed = display.trim();
    final last = trimmed.isNotEmpty ? trimmed[trimmed.length - 1] : '';

    // Can only close if there is an unclosed '(' and not immediately after an operator or '('
    if (openCount > closeCount && !_isOperator(last) && last != '(') {
      display += ')';
      _updateLivePreview();
    }
  }

  void _addOperator(String op) {
    if (display == 'Error') {
      display = '0';
      _justCalculated = false;
    }

    if (_justCalculated) {
      _justCalculated = false;
      display = '$display $op ';
      _updateLivePreview();
      return;
    }

    if (display.endsWith(' + ') ||
        display.endsWith(' − ') ||
        display.endsWith(' × ') ||
        display.endsWith(' ÷ ')) {
      // Replace the trailing operator
      display = '${display.substring(0, display.length - 3)} $op ';
    } else if (display.endsWith('(')) {
      if (op == '−') {
        display += '-';
      }
    } else if (display == '0') {
      if (op == '−') {
        display = '-';
      }
    } else {
      display += ' $op ';
    }
    _updateLivePreview();
  }

  void _addDigit(String digit) {
    if (_justCalculated || display == '0' || display == 'Error') {
      display = digit;
      _justCalculated = false;
    } else if (display.endsWith(')')) {
      display += ' × $digit';
    } else {
      display += digit;
    }
    _updateLivePreview();
  }

  void _addDecimal() {
    if (_justCalculated || display == '0' || display == 'Error') {
      display = '0.';
      _justCalculated = false;
    } else if (display.endsWith(' ') || display.endsWith('(')) {
      display += '0.';
    } else {
      // Check if current number chunk already contains a dot
      final lastChunk = display.split(RegExp(r'[ +−×÷()]')).last;
      if (!lastChunk.contains('.')) {
        display += '.';
      }
    }
    _updateLivePreview();
  }

  void _negate() {
    if (display == '0' || display == 'Error') return;

    if (_justCalculated) {
      final val = double.tryParse(display);
      if (val != null) {
        display = _fmt(-val);
        _justCalculated = false;
        _updateLivePreview();
      }
      return;
    }

    if (display.startsWith('-(') && display.endsWith(')')) {
      display = display.substring(2, display.length - 1);
    } else if (display.startsWith('-')) {
      display = display.substring(1);
    } else {
      display = '-($display)';
    }
    _updateLivePreview();
  }

  void _percent() {
    if (display == '0' || display == 'Error') return;
    final trimmed = display.trim();
    final last = trimmed.isNotEmpty ? trimmed[trimmed.length - 1] : '';
    if (_isDigit(last) || last == ')') {
      display += '%';
      _updateLivePreview();
    }
  }

  void _calculate() {
    if (display == 'Error') return;

    final result = ExpressionParser.tryEvaluate(display);
    if (result != null) {
      preview = '$display =';
      display = _fmt(result);
      _justCalculated = true;
    } else {
      preview = '$display =';
      display = 'Error';
      _justCalculated = true;
    }
  }

  void _updateLivePreview() {
    if (display == '0' || display == 'Error' || _justCalculated) {
      preview = '';
      return;
    }

    // Only show live preview if there's an operation or grouping in display
    final hasMath = display.contains('+') ||
        display.contains('−') ||
        display.contains('×') ||
        display.contains('÷') ||
        display.contains('(') ||
        display.contains('%');

    if (hasMath) {
      final result = ExpressionParser.tryEvaluatePreview(display);
      if (result != null) {
        preview = '= ${_fmt(result)}';
      } else {
        preview = '';
      }
    } else {
      preview = '';
    }
  }

  bool _isDigit(String ch) {
    if (ch.isEmpty) return false;
    final code = ch.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }

  bool _isOperator(String ch) {
    return ch == '+' || ch == '−' || ch == '-' || ch == '×' || ch == '*' || ch == '÷' || ch == '/';
  }

  /// Format a double: prefer integer string, otherwise trim trailing zeros.
  String _fmt(double value) {
    if (value == value.truncateToDouble() && value.abs() < 1e12) {
      return value.toInt().toString();
    }
    return value
        .toStringAsFixed(8)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}
