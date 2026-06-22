import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prm_project/viewmodels/auth_viewmodel.dart';
import 'package:prm_project/views/auth/login_screen.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    // Mock Firebase Core Channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_core'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'initializeApp') {
          return {
            'name': methodCall.arguments['name'] ?? '[DEFAULT]',
            'options': methodCall.arguments['options'] ?? {},
            'pluginConstants': {},
          };
        }
        return null;
      },
    );

    // Mock Firebase Auth Channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_auth'),
      (MethodCall methodCall) async {
        return null;
      },
    );
  });

  Widget createLoginScreenWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: LoginScreen(),
        ),
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('Renders Login Screen form widgets correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreenWidget());
      await tester.pumpAndSettle();

      // Check existence of fields and buttons
      expect(find.byKey(const Key('emailField')), findsOneWidget);
      expect(find.byKey(const Key('passwordField')), findsOneWidget);
      expect(find.byKey(const Key('loginButton')), findsOneWidget);
      expect(find.text('L U X U R A'), findsOneWidget);
    });

    testWidgets('Triggers validation error messages on empty submission', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreenWidget());
      await tester.pumpAndSettle();

      // Tap login without filling out form
      final loginBtn = find.byKey(const Key('loginButton'));
      await tester.tap(loginBtn);
      await tester.pump();

      // Verify that validation warning messages are shown
      expect(find.text('Vui lòng nhập email'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    });

    testWidgets('Triggers invalid email error message on malformed email input', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreenWidget());
      await tester.pumpAndSettle();

      // Enter invalid email
      final emailField = find.byKey(const Key('emailField'));
      await tester.enterText(emailField, 'bademailinput');
      
      // Enter password
      final passwordField = find.byKey(const Key('passwordField'));
      await tester.enterText(passwordField, '123456');

      // Tap Login
      final loginBtn = find.byKey(const Key('loginButton'));
      await tester.tap(loginBtn);
      await tester.pump();

      // Verify validation warning
      expect(find.text('Vui lòng nhập địa chỉ email hợp lệ'), findsOneWidget);
      expect(find.text('Vui lòng nhập email'), findsNothing);
    });
  });
}
