import 'package:flutter_test/flutter_test.dart';
import 'package:link26_app/app.dart';

void main() {
  testWidgets('Link26App builds smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LinkApp());
    expect(find.byType(LinkApp), findsOneWidget);
  });
}
