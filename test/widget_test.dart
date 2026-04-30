import 'package:flutter_test/flutter_test.dart';
import 'package:link26_app/app.dart';

void main() {
  testWidgets('Link26App builds smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const Link26App());
    expect(find.byType(Link26App), findsOneWidget);
  });
}
