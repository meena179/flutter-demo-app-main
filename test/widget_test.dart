import 'package:flutter_test/flutter_test.dart';
import 'package:weather/main.dart';

void main() {
  testWidgets('My Weather app opens successfully',
      (WidgetTester tester) async {
    await tester.pumpWidget(const WeatherApp());

    expect(find.text('My Weather'), findsOneWidget);
    expect(find.text('Your weather, at a glance.'), findsOneWidget);
    expect(find.text('Discover the weather'), findsOneWidget);
  });
}