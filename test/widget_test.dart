import 'package:flutter_test/flutter_test.dart';

import 'package:weather_app/main.dart';

void main() {
  testWidgets('weather app renders search field', (WidgetTester tester) async {
    await tester.pumpWidget(const WeatherApp());

    expect(find.text('Search any city'), findsOneWidget);
    expect(find.text('Current location'), findsOneWidget);
  });
}
