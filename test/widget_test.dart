import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ssh_remote/main.dart';
import 'package:ssh_remote/providers/server_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SshRemoteApp renders dashboard successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ServerProvider()),
        ],
        child: const SshRemoteApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify server name and connection action are rendered
    expect(find.text('Demo Ubuntu VPS'), findsWidgets);
    expect(find.text('Connect'), findsOneWidget);
  });
}
