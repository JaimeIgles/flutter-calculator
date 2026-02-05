import 'package:flutter/material.dart';
import 'package:expressions/expressions.dart'; // External package for expression evaluationer

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Calculator App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _accumulator = ''; // shows ongoing calculation and result (history line)
  String _expression = ''; // current expression being built (no trailing '=')
  String _result = ''; // latest result for display

  bool _justEvaluated = false; // if last press was '=', next digit starts fresh
String _squareValue(String value) {
  final double? x = double.tryParse(value);
  if (x == null) return 'Error';

  final double squared = x * x;

  if (squared == squared.roundToDouble()) {
    return squared.toInt().toString();
  }

  return squared
      .toStringAsFixed(6)
      .replaceFirst(RegExp(r'\.?0+$'), '');
}

  bool _isOperator(String s) {
    return s == '+' || s == '-' || s == '*' || s == '/';
  }

  void _clearAll() {
    setState(() {
      _accumulator = '';
      _expression = '';
      _result = '';
      _justEvaluated = false;
    });
  }

  String _sanitizeExpression(String expr) {
    // Prevent invalid endings like "2+"
    String e = expr.trim();
    while (e.isNotEmpty && _isOperator(e[e.length - 1])) {
      e = e.substring(0, e.length - 1).trimRight();
    }
    return e;
  }

  String _evalExpression(String expr) {
    final String cleaned = _sanitizeExpression(expr);
    if (cleaned.isEmpty) return '';

    // Simple protection: disallow "divide by zero" obvious patterns like "/0"
    // (Still also handle via try/catch below)
    if (cleaned.contains('/0') || cleaned.contains('/ 0')) {
      return 'Error: ÷0';
    }

    try {
      final Expression parsed = Expression.parse(cleaned);
      final evaluator = const ExpressionEvaluator();

      final dynamic value = evaluator.eval(parsed, {});

      if (value is num) {
        // Keep it readable: show int if whole number
        if (value.isInfinite || value.isNaN) return 'Error';
        final double d = value.toDouble();
        if (d == d.roundToDouble()) return d.toInt().toString();
        return d.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
      }

      return value.toString();
    } catch (e) {
      return 'Error';
    }
  }

  void _appendToken(String token) {
    setState(() {
      // If we just evaluated and user starts typing a number, start new calc
      if (_justEvaluated && !_isOperator(token) && token != '=') {
        _accumulator = '';
        _expression = '';
        _result = '';
        _justEvaluated = false;
      }

      if (token == 'C') {
        _clearAll();
        return;
      }
      if (token == 'x²') {
  final String base = _result.isNotEmpty ? _result : _expression;

  final String squared = _squareValue(base);

  _accumulator = '$base² = $squared';
  _expression = squared;
  _result = squared;
  _justEvaluated = true;
  return;
}


      if (token == '=') {
        final String r = _evalExpression(_expression);
        setState(() {
          _result = r;

          // accumulator example: "2 + 3 * 4 = 14"
          if (_expression.trim().isNotEmpty) {
            _accumulator = '${_expression.trim()} = $r';
          } else {
            _accumulator = '';
          }

          _justEvaluated = true;

          // Option: allow continuing calculations from the result
          if (r.isNotEmpty && !r.startsWith('Error')) {
            _expression = r;
          } else {
            // keep expression as-is so user can fix it
          }
        });
        return;
      }

      // Operators: avoid double operators like "2++"
      if (_isOperator(token)) {
        if (_expression.trim().isEmpty) {
          // Allow starting with "-" for negative numbers; otherwise ignore
          if (token == '-') {
            _expression = '-';
          }
        } else {
          final String trimmed = _expression.trimRight();
          if (trimmed.isNotEmpty && _isOperator(trimmed[trimmed.length - 1])) {
            // replace last operator
            _expression =
                trimmed.substring(0, trimmed.length - 1) + token + ' ';
          } else {
            _expression = '${_expression.trimRight()} $token ';
          }
        }
      } else {
        // Digits
        _expression = '$_expression$token';
      }

      // Live result preview while typing (optional but helps usability)
      final String preview = _evalExpression(_expression);
      _result = preview;
      _accumulator = _expression.trim().isEmpty ? '' : _expression.trim();
      _justEvaluated = false;
    });
  }

  Widget _calcButton(String text,
      {Color? background, Color? foreground, bool expanded = false}) {
    return Expanded(
      flex: expanded ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: ElevatedButton(
          onPressed: () => _appendToken(text),
          style: ElevatedButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Display / accumulator area
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _accumulator,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _result.isEmpty ? '0' : _result,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Buttons
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      _calcButton('C', background: Colors.red, foreground: Colors.white),
                      _calcButton('x²', background: Colors.blueGrey, foreground: Colors.white),                      
                      _calcButton('/', background: Colors.blueGrey, foreground: Colors.white),
                      _calcButton('*', background: Colors.blueGrey, foreground: Colors.white),
                      _calcButton('-', background: Colors.blueGrey, foreground: Colors.white),
                    ],
                  ),
                  Row(
                    children: [
                      _calcButton('7'),
                      _calcButton('8'),
                      _calcButton('9'),
                      _calcButton('+', background: Colors.blueGrey, foreground: Colors.white),
                    ],
                  ),
                  Row(
                    children: [
                      _calcButton('4'),
                      _calcButton('5'),
                      _calcButton('6'),
                      _calcButton('=', background: Colors.green, foreground: Colors.white, expanded: false),
                    ],
                  ),
                  Row(
                    children: [
                      _calcButton('1'),
                      _calcButton('2'),
                      _calcButton('3'),
                      _calcButton('0', expanded: false),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
