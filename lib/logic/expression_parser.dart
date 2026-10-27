enum _TokenType {
  number,
  plus,
  minus,
  multiply,
  divide,
  percent,
  openParen,
  closeParen,
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
/// parentheses grouping, implicit multiplication, percentages, and unary signs.
class ExpressionParser {
  /// Evaluates an expression string. Throws an exception if invalid or division by zero.
  static double evaluate(String expression) {
    final sanitized = _sanitize(expression);
    if (sanitized.isEmpty) return 0;
    final tokens = _tokenize(sanitized);
    final parser = _Parser(tokens);
    return parser.parse();
  }

  /// Safely evaluates an expression. Returns null if invalid or infinite.
  static double? tryEvaluate(String expression) {
    try {
      final res = evaluate(expression);
      if (res.isNaN || res.isInfinite) return null;
      return res;
    } catch (_) {
      return null;
    }
  }

  /// Evaluates expression for real-time live preview as user types,
  /// automatically handling trailing operators and unclosed parentheses.
  static double? tryEvaluatePreview(String expression) {
    var sanitized = _sanitize(expression);
    // Strip trailing incomplete operators or open paren
    while (sanitized.isNotEmpty &&
        (sanitized.endsWith('+') ||
            sanitized.endsWith('-') ||
            sanitized.endsWith('*') ||
            sanitized.endsWith('/') ||
            sanitized.endsWith('.'))) {
      sanitized = sanitized.substring(0, sanitized.length - 1).trim();
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

    return tryEvaluate(sanitized);
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
      } else if (ch == '%') {
        tokens.add(const _Token(_TokenType.percent));
        i++;
      } else if (ch == '(') {
        // If previous token was a number, close paren, or percent, insert implicit multiply
        if (tokens.isNotEmpty &&
            (tokens.last.type == _TokenType.number ||
                tokens.last.type == _TokenType.closeParen ||
                tokens.last.type == _TokenType.percent)) {
          tokens.add(const _Token(_TokenType.multiply));
        }
        tokens.add(const _Token(_TokenType.openParen));
        i++;
      } else if (ch == ')') {
        tokens.add(const _Token(_TokenType.closeParen));
        i++;
      } else if (_isDigitOrDot(ch)) {
        // If previous token was close paren or percent, insert implicit multiply
        if (tokens.isNotEmpty &&
            (tokens.last.type == _TokenType.closeParen ||
                tokens.last.type == _TokenType.percent)) {
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
}

class _Parser {
  final List<_Token> tokens;
  int _pos = 0;

  _Parser(this.tokens);

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

  // term = factor ( ('*' | '/') factor )*
  double _parseTerm() {
    double left = _parseFactor();

    while (_current.type == _TokenType.multiply ||
        _current.type == _TokenType.divide) {
      final op = _consume().type;
      final right = _parseFactor();
      if (op == _TokenType.multiply) {
        left *= right;
      } else {
        if (right == 0) throw ArgumentError('Division by zero');
        left /= right;
      }
    }
    return left;
  }

  // factor = unary ( '%' )*
  double _parseFactor() {
    double val = _parseUnary();

    while (_current.type == _TokenType.percent) {
      _consume();
      val = val / 100.0;
    }
    return val;
  }

  // unary = ('+' | '-') unary | primary
  double _parseUnary() {
    if (_current.type == _TokenType.plus) {
      _consume();
      return _parseUnary();
    }
    if (_current.type == _TokenType.minus) {
      _consume();
      return -_parseUnary();
    }
    return _parsePrimary();
  }

  // primary = number | '(' expression ')'
  double _parsePrimary() {
    final t = _current;
    if (t.type == _TokenType.number) {
      _consume();
      return t.value ?? 0.0;
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
}
