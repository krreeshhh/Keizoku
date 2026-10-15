import 'package:flutter_test/flutter_test.dart';
import 'package:keizoku/app/keizoku_app.dart';
import 'package:keizoku/catalog/exercise_catalog.dart';
import 'package:keizoku/l10n/l10n.dart';
import 'package:keizoku/models/workout.dart';
import 'package:keizoku/services/local_store.dart';
import 'package:keizoku/services/progress_reminder.dart';
import 'package:keizoku/services/train_reminder.dart';
import 'package:keizoku/state/fit_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final bench = kExercises.firstWhere((e) => e.name == 'Barbell Bench Press');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.instance.init();
    ProgressReminder.instance.enabled = false;
    TrainReminder.instance.enabled = false;
    fit.resetAllData();
    fit.completeOnboarding();
  });

  void logSessions() {
    for (var i = 1; i <= 6; i++) {
      fit.sessions.add(LoggedSession(
        DateTime.now().subtract(Duration(days: i * 3)),
        3600,
        [
          LoggedExercise(bench.id, bench.name, bench.primary, [LoggedSet(8, 70)]),
        ],
      ));
    }
  }

  Future<double> yOf(WidgetTester tester, String text) async {
    final finder = find.text(text);
    expect(finder, findsWidgets, reason: 'no se encontró "$text"');
    return tester.getTopLeft(finder.first).dy;
  }

  testWidgets('the grid comes first, then the body', (tester) async {
    logSessions();
    fit.route = 'progress';
    await tester.pumpWidget(const KeizokuApp());
    await tester.pumpAndSettle();

    final heat = await yOf(tester, t.consistency.toUpperCase());
    final body = await yOf(tester, t.muscleMap);

    expect(heat, lessThan(body));
  });
}
