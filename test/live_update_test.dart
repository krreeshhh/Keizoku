import 'package:flutter_test/flutter_test.dart';
import 'package:keizoku/app/keizoku_app.dart';
import 'package:keizoku/state/fit_state.dart';

void main() {
  testWidgets('selecting a muscle updates the Train screen immediately', (tester) async {

    fit.onboarded = true;
    fit.route = 'train';
    fit.trainStep = 'select';
    fit.selectedMuscles.clear();

    await tester.pumpWidget(const KeizokuApp());
    await tester.pumpAndSettle();

    expect(find.text('Chest'), findsNothing);

    fit.toggleMuscle('chest');
    await tester.pump();

    expect(find.text('Chest'), findsOneWidget);

    fit.toggleMuscle('chest');
    await tester.pump();
    expect(find.text('Chest'), findsNothing);

    fit.route = 'home';
  });
}
