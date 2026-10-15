import 'package:flutter_test/flutter_test.dart';
import 'package:keizoku/app/keizoku_app.dart';
import 'package:keizoku/catalog/exercise_catalog.dart';
import 'package:keizoku/l10n/l10n.dart';
import 'package:keizoku/models/workout.dart';
import 'package:keizoku/services/local_store.dart';
import 'package:keizoku/state/fit_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final bench = kExercises.firstWhere((e) => e.name == 'Barbell Bench Press');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.instance.init();
    fit.resetAllData();
    fit.completeOnboarding();
  });

  testWidgets('PRs click opens strength tracker popup with weight done, not 1RM', (tester) async {
    // Log two sessions of bench press with different weights
    fit.sessions.add(LoggedSession(
      DateTime.now().subtract(const Duration(days: 7)),
      1800,
      [
        LoggedExercise(bench.id, bench.name, bench.primary, [LoggedSet(10, 60)]),
      ],
    ));
    fit.sessions.add(LoggedSession(
      DateTime.now(),
      1800,
      [
        LoggedExercise(bench.id, bench.name, bench.primary, [LoggedSet(8, 70)]),
      ],
    ));

    expect(fit.weightSeries(bench.id), [60.0, 70.0]);
    final pr = fit.personalRecords.firstWhere((p) => p.id == bench.id);
    expect(pr.best, 70.0);
    expect(fit.recordDetail(pr), t.prBestSet);

    fit.route = 'progress';
    await tester.pumpWidget(const KeizokuApp());
    await tester.pumpAndSettle();

    // Verify 1RM strength card header is NOT on the Progress page
    expect(find.text(t.strength1rm), findsNothing);

    // Verify PR is listed
    expect(find.text(t.catalogName(bench.id, bench.name)), findsOneWidget);
    expect(find.text('70 kg'), findsOneWidget);
    expect(find.text(t.prBestSet), findsWidgets);
    // Scroll to the PR row
    await tester.scrollUntilVisible(find.text(t.catalogName(bench.id, bench.name)), 300);
    await tester.pumpAndSettle();

    // Tap the PR row to open strength tracker popup
    await tester.tap(find.text(t.catalogName(bench.id, bench.name)));
    await tester.pumpAndSettle();

    // Verify popup opened with STRENGTH TRACKER · WEIGHT DONE
    expect(find.text('STRENGTH TRACKER · WEIGHT DONE'), findsOneWidget);
    expect(find.text('LOGGED SESSIONS'), findsOneWidget);
    expect(find.text('+10 kg'), findsOneWidget); // 70 - 60
  });
}
