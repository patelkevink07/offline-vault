import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:offline_vault/app/theme/app_theme.dart';
import 'package:offline_vault/features/auth/presentation/onboarding_screen.dart';
import 'package:offline_vault/features/auth/presentation/sign_in_screen.dart';
import 'package:offline_vault/features/upload/presentation/upload_screen.dart';
import 'package:offline_vault/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createTestApp(Widget child) {
  final router = GoRouter(
    initialLocation: '/test',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Text('Home Screen')),
      ),
      GoRoute(
        path: '/test',
        builder: (context, state) => child,
      ),
    ],
  );

  return ProviderScope(
    child: MaterialApp.router(
      theme: AppTheme.darkTheme,
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('OnboardingScreen renders slides and Next button without layout crash', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestApp(const OnboardingScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(PageView), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Sync once'), findsOneWidget);
  });

  testWidgets('SignInScreen renders Google, Email, and Offline Mode buttons and tapping offline mode works', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestApp(const SignInScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Offline Vault'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Send code'), findsOneWidget);

    final offlineBtn = find.text('Continue in Offline Vault Mode');
    expect(offlineBtn, findsOneWidget);

    await tester.tap(offlineBtn);
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('offline_guest_mode'), isTrue);
    expect(find.text('Home Screen'), findsOneWidget);
  });

  testWidgets('UploadScreen renders Add Images and Add Document buttons', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      createTestApp(
        const UploadScreen(groupId: 'test-group-id'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add Files & Documents'), findsOneWidget);
    expect(find.text('Add Images'), findsOneWidget);
    expect(find.text('Add Document'), findsOneWidget);
    expect(find.text('Upload Quality'), findsOneWidget);
  });
}
