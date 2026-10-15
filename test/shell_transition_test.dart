import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keizoku/app/keizoku_app.dart';
import 'package:keizoku/l10n/l10n.dart';
import 'package:keizoku/screens/home_screen.dart';
import 'package:keizoku/services/local_store.dart';
import 'package:keizoku/services/progress_reminder.dart';
import 'package:keizoku/state/fit_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.instance.init();
    ProgressReminder.instance.enabled = false;
    setAppLanguage('es');
    fit.onboarded = true;
    fit.session = null;
    fit.sessions.clear();
    fit.resetRoute('home');
  });

  double homeOpacity(WidgetTester tester) {
    final fade = tester.widget<Opacity>(
      find.ancestor(of: find.byType(HomeScreen), matching: find.byType(Opacity)).first,
    );
    return fade.opacity;
  }

  testWidgets('the screen being left is gone before the new one shows up', (tester) async {
    await tester.pumpWidget(const KeizokuApp());
    await tester.pump();

    fit.goProgress();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(homeOpacity(tester), 0, reason: 'la pantalla anterior se quedaba de fondo');

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('holding a tab lets the pill slide to another one', (tester) async {
    await tester.pumpWidget(const KeizokuApp());
    await tester.pump();

    final home = tester.getCenter(find.text(t.home));
    final profile = tester.getCenter(find.text(t.profile.toUpperCase()));
    final gesture = await tester.startGesture(home);
    await tester.pump(const Duration(milliseconds: 700));
    for (var i = 1; i <= 10; i++) {
      await gesture.moveTo(Offset.lerp(home, profile, i / 10)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(fit.route, 'home');
    await gesture.up();
    await tester.pump();
    expect(fit.route, 'settings');
    await tester.pump(const Duration(seconds: 1));
  });
}
