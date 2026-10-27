import 'dart:math' as math;

enum _TokenType {
  number,
  plus,
  minus,
  multiply,
  divide,
  power,
  factorial,
  percent,
  openParen,
  closeParen,
  sqrt,
  sin,
  cos,
  tan,
  log,
  ln,
  pi,
  eConst,
  eof,
}

class _Token {
  final _TokenType type;
  final double? value;

  const _Token(this.type, [this.value]);

  @override
  String toString() => 'Token($type, $value)';
}

/// Evaluates mathematical expressions with standard precedence (PEMDAS/BODMAS),
/// parentheses grouping, power, root, trigonometry, logarithms, factorial, percentages, and constants.
class ExpressionParser {
  /// Evaluates an expression string. Throws an exception if invalid or division by zero.
  static double evaluate(String expression, {bool isRadians = false}) {
    final sanitized = _sanitize(expression);
    if (sanitized.isEmpty) return 0;
    final tokens = _tokenize(sanitized);
    final parser = _Parser(tokens, isRadians: isRadians);
    return parser.parse();
  }

  /// Safely evaluates an expression. Returns null if invalid, NaN, or infinite.
  static double? tryEvaluate(String expression, {bool isRadians = false}) {
    try {
      final res = evaluate(expression, isRadians: isRadians);
      if (res.isNaN || res.isInfinite) return null;
      return res;
    } catch (_) {
      return null;
    }
  }

  /// Evaluates expression for real-time live preview as user types,
  /// automatically handling trailing operators and unclosed parentheses.
  static double? tryEvaluatePreview(String expression, {bool isRadians = false}) {
    var sanitized = _sanitize(expression);
    // Strip trailing incomplete operators
    while (sanitized.isNotEmpty &&
        (sanitized.endsWith('+') ||
            sanitized.endsWith('-') ||
            sanitized.endsWith('*') ||
            sanitized.endsWith('/') ||
            sanitized.endsWith('^') ||
            sanitized.endsWith('.') ||
            sanitized.endsWith('√') ||
            sanitized.endsWith('sin(') ||
            sanitized.endsWith('cos(') ||
            sanitized.endsWith('tan(') ||
            sanitized.endsWith('log(') ||
            sanitized.endsWith('ln('))) {
      if (sanitized.endsWith('sin(') ||
          sanitized.endsWith('cos(') ||
          sanitized.endsWith('tan(') ||
          sanitized.endsWith('log(')) {
        sanitized = sanitized.substring(0, sanitized.length - 4).trim();
      } else if (sanitized.endsWith('ln(')) {
        sanitized = sanitized.substring(0, sanitized.length - 3).trim();
      } else {
        sanitized = sanitized.substring(0, sanitized.length - 1).trim();
      }
    }

    // Auto-balance unclosed parentheses
    int openCount = 0;
    int closeCount = 0;
    for (int i = 0; i < sanitized.length; i++) {
      if (sanitized[i] == '(') openCount++;
      if (sanitized[i] == ')') closeCount++;
    }
    while (openCount > closeCount) {
      sanitized += ')';
      closeCount++;
    }

    return tryEvaluate(sanitized, isRadians: isRadians);
  }

  static String _sanitize(String expr) {
    return expr
        .replaceAll('×', '*')
        .replaceAll('−', '-')
        .replaceAll('÷', '/')
        .replaceAll(',', '')
        .trim();
  }

  static bool _isDigitOrDot(String ch) {
    return (ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57) || ch == '.';
  }

  static List<_Token> _tokenize(String s) {
    final tokens = <_Token>[];
    int i = 0;

    bool needsImplicitMultiply() {
      if (tokens.isEmpty) return false;
      final last = tokens.last.type;
      return last == _TokenType.number ||
          last == _TokenType.closeParen ||
          last == _TokenType.percent ||
          last == _TokenType.factorial ||
          last == _TokenType.pi ||
          last == _TokenType.eConst;
    }

    while (i < s.length) {
      final ch = s[i];
      if (ch == ' ') {
        i++;
        continue;
      }

      if (ch == '+') {
        tokens.add(const _Token(_TokenType.plus));
        i++;
      } else if (ch == '-') {
        tokens.add(const _Token(_TokenType.minus));
        i++;
      } else if (ch == '*') {
        tokens.add(const _Token(_TokenType.multiply));
        i++;
      } else if (ch == '/') {
        tokens.add(const _Token(_TokenType.divide));
        i++;
      } else if (ch == '^') {
        tokens.add(const _Token(_TokenType.power));
        i++;
      } else if (ch == '!') {
        tokens.add(const _Token(_TokenType.factorial));
        i++;
      } else if (ch == '%') {
        tokens.add(const _Token(_TokenType.percent));
        i++;
      } else if (ch == '√') {
        if (needsImplicitMultiply()) {
          tokens.add(const _Token(_TokenType.multiply));
        }
        tokens.add(const _Token(_TokenType.sqrt));
        i++;
      } else if (ch == 'π') {
        if (needsImplicitMultiply()) {
          tokens.add(const _Token(_TokenType.multiply));
        }
        tokens.add(const _Token(_TokenType.pi));
        i++;
      } else if (s.startsWith('sin', i)) {
        if (needsImplicitMultiply()) {
          tokens.add(const _Token(_TokenType.multiply));
        }
        tokens.add(const _Token(_TokenType.sin));
        i += 3;
      } else if (s.startsWith('cos', i)) {
        if (needsImplicitMultiply()) {
          tokens.add(const _Token(_TokenType.multiply));
        }
        tokens.add(const _Token(_TokenType.cos));
        i += 3;
      } else if (s.startsWith('tan', i)) {
        if (needsImplicitMultiply()) {
          tokens.add(const _Token(_TokenType.multiply));
        }
        tokens.add(const _Token(_TokenType.tan));
        i += 3;
      } else if (s.startsWith('log', i)) {
        if (needsImplicitMultiply()) {
          tokens.add(const _Token(_TokenType.multiply));
        }
        tokens.add(const _Token(_TokenType.log));
        i += 3;
      } else if (s.startsWith('ln', i)) {
        if (needsImplicitMultiply()) {
          tokens.add(const _Token(_TokenType.multiply));
        }
        tokens.add(const _Token(_TokenType.ln));
        i += 2;
      } else if (ch == 'e' && (i + 1 == s.length || !_isAlpha(s[i + 1]))) {
        if (needsImplicitMultiply()) {
          tokens.add(const _Token(_TokenType.multiply));
        }
        tokens.add(const _Token(_TokenType.eConst));
        i++;
      } else if (ch == '(') {
        if (needsImplicitMultiply()) {
          tokens.add(const _Token(_TokenType.multiply));
        }
        tokens.add(const _Token(_TokenType.openParen));
        i++;
      } else if (ch == ')') {
        tokens.add(const _Token(_TokenType.closeParen));
        i++;
      } else if (_isDigitOrDot(ch)) {
        if (tokens.isNotEmpty &&
            (tokens.last.type == _TokenType.closeParen ||
                tokens.last.type == _TokenType.percent ||
                tokens.last.type == _TokenType.factorial ||
                tokens.last.type == _TokenType.pi ||
                tokens.last.type == _TokenType.eConst)) {
          tokens.add(const _Token(_TokenType.multiply));
        }
        final start = i;
        while (i < s.length && _isDigitOrDot(s[i])) {
          i++;
        }
        final numStr = s.substring(start, i);
        final val = double.tryParse(numStr) ?? 0.0;
        tokens.add(_Token(_TokenType.number, val));
      } else {
        i++;
      }
    }
    return tokens;
  }

  static bool _isAlpha(String ch) {
    final c = ch.codeUnitAt(0);
    return (c >= 65 && c <= 90) || (c >= 97 && c <= 122);
  }
}

class _Parser {
  final List<_Token> tokens;
  final bool isRadians;
  int _pos = 0;

  _Parser(this.tokens, {required this.isRadians});

  _Token get _current =>
      _pos < tokens.length ? tokens[_pos] : const _Token(_TokenType.eof);

  _Token _consume() {
    final t = _current;
    if (_pos < tokens.length) _pos++;
    return t;
  }

  double parse() {
    if (tokens.isEmpty) return 0;
    final result = _parseExpression();
    return result;
  }

  // expression = term ( ('+' | '-') term )*
  double _parseExpression() {
    double left = _parseTerm();

    while (_current.type == _TokenType.plus ||
        _current.type == _TokenType.minus) {
      final op = _consume().type;
      final right = _parseTerm();
      if (op == _TokenType.plus) {
        left += right;
      } else {
        left -= right;
      }
    }
    return left;
  }

  // term = powerTerm ( ('*' | '/') powerTerm )*
  double _parseTerm() {
    double left = _parsePower();

    while (_current.type == _TokenType.multiply ||
        _current.type == _TokenType.divide) {
      final op = _consume().type;
      final right = _parsePower();
      if (op == _TokenType.multiply) {
        left *= right;
      } else {
        if (right == 0) throw ArgumentError('Division by zero');
        left /= right;
      }
    }
    return left;
  }

  // powerTerm = postfix ( '^' powerTerm )*   (right-associative)
  double _parsePower() {
    double left = _parsePostfix();

    if (_current.type == _TokenType.power) {
      _consume();
      double right = _parsePower();
      left = math.pow(left, right).toDouble();
    }
    return left;
  }

  // postfix = prefix ( '%' | '!' )*
  double _parsePostfix() {
    double val = _parsePrefix();

    while (_current.type == _TokenType.percent ||
        _current.type == _TokenType.factorial) {
      final t = _consume().type;
      if (t == _TokenType.percent) {
        val = val / 100.0;
      } else if (t == _TokenType.factorial) {
        val = _factorial(val);
      }
    }
    return val;
  }

  // prefix = ('+' | '-') prefix | funcCall | primary
  double _parsePrefix() {
    if (_current.type == _TokenType.plus) {
      _consume();
      return _parsePrefix();
    }
    if (_current.type == _TokenType.minus) {
      _consume();
      return -_parsePrefix();
    }
    if (_current.type == _TokenType.sqrt) {
      _consume();
      final arg = _parsePrimary();
      if (arg < 0) throw ArgumentError('Square root of negative number');
      return math.sqrt(arg);
    }
    if (_current.type == _TokenType.sin) {
      _consume();
      final arg = _parsePrimary();
      final rad = isRadians ? arg : arg * (math.pi / 180.0);
      final val = math.sin(rad);
      return val.abs() < 1e-15 ? 0.0 : val;
    }
    if (_current.type == _TokenType.cos) {
      _consume();
      final arg = _parsePrimary();
      final rad = isRadians ? arg : arg * (math.pi / 180.0);
      final val = math.cos(rad);
      return val.abs() < 1e-15 ? 0.0 : val;
    }
    if (_current.type == _TokenType.tan) {
      _consume();
      final arg = _parsePrimary();
      final rad = isRadians ? arg : arg * (math.pi / 180.0);
      final cosVal = math.cos(rad);
      if (cosVal.abs() < 1e-15) throw ArgumentError('Tan undefined');
      final val = math.tan(rad);
      return val.abs() < 1e-15 ? 0.0 : val;
    }
    if (_current.type == _TokenType.log) {
      _consume();
      final arg = _parsePrimary();
      if (arg <= 0) throw ArgumentError('Log of non-positive number');
      return math.log(arg) / math.ln10;
    }
    if (_current.type == _TokenType.ln) {
      _consume();
      final arg = _parsePrimary();
      if (arg <= 0) throw ArgumentError('Ln of non-positive number');
      return math.log(arg);
    }

    return _parsePrimary();
  }

  // primary = number | 'π' | 'e' | '(' expression ')'
  double _parsePrimary() {
    final t = _current;
    if (t.type == _TokenType.number) {
      _consume();
      return t.value ?? 0.0;
    }
    if (t.type == _TokenType.pi) {
      _consume();
      return math.pi;
    }
    if (t.type == _TokenType.eConst) {
      _consume();
      return math.e;
    }

    if (t.type == _TokenType.openParen) {
      _consume();
      final val = _parseExpression();
      if (_current.type == _TokenType.closeParen) {
        _consume();
      }
      return val;
    }

    throw FormatException('Unexpected token: ${t.type}');
  }

  double _factorial(double n) {
    if (n < 0 || n != n.truncateToDouble() || n > 170) {
      throw ArgumentError('Invalid factorial operand');
    }
    final intN = n.toInt();
    if (intN == 0 || intN == 1) return 1.0;
    double res = 1.0;
    for (int i = 2; i <= intN; i++) {
      res *= i;
    }
    return res;
  }
}
