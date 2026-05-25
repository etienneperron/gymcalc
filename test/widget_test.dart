import 'package:flutter_test/flutter_test.dart';

import 'package:gymcalc/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('calculateRep rounds to the nearest 2.5 lb per side', () {
    final RepCalculation calculation = calculateRep(
      rep: 1,
      maxWeight: 315,
      barWeight: 45,
      percentage: 85,
    );

    expect(calculation.targetWeight, 270);
    expect(calculation.perSideWeight, 112.5);
    expect(calculation.plates, <double>[45, 45, 10, 10, 2.5]);
  });

  testWidgets('calculator screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Plate Calculator'), findsOneWidget);
    expect(find.text('Max weight (lb)'), findsOneWidget);
    expect(find.text('Bar weight (lb)'), findsOneWidget);
    expect(find.text('Rep 1'), findsOneWidget);
  });
}
