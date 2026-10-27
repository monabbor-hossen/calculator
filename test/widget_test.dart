import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:calulator/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('CalculatorApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CalculatorApp());
    expect(find.text('0'), findsWidgets);
    expect(find.text('AC'), findsOneWidget);
    expect(find.text('='), findsOneWidget);
  });
}
