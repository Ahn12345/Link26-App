import 'package:flutter_test/flutter_test.dart';
import 'package:link_app/app.dart';

void main() {
  testWidgets('LinkApp builds smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LinkApp());
    expect(find.byType(LinkApp), findsOneWidget);
  });
}
