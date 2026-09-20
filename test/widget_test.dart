import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/main.dart';

void main() {
  testWidgets('NexusApp smoke test', (WidgetTester tester) async {
    // Carrega o aplicativo NexusApp
    await tester.pumpWidget(const NexusApp());

    // Verifica se a estrutura básica é renderizada sem erros
    expect(find.byType(NexusApp), findsOneWidget);
  });
}