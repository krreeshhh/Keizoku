import 'package:flutter_test/flutter_test.dart';
import 'package:keizoku/models/workout.dart';
import 'package:keizoku/services/local_store.dart';
import 'package:keizoku/state/fit_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.instance.init();
    fit.sessions.clear();
    fit.profile.badge = '';
    fit.profile.handle = '';
    fit.profile.since = null;
  });

  test('the handle falls back to the name until you set your own', () {
    fit.profile.name = 'Inlitx Lifts';
    expect(fit.profileHandle, 'inlitxlifts');

    fit.setProfileHandle(' my.handle! ');
    expect(fit.profileHandle, 'my.handle');
  });

  test('the badge is a toggle, not a one-way door', () {
    fit.setProfileBadge('blue');
    expect(fit.profile.badge, 'blue');

    fit.setProfileBadge('green');
    expect(fit.profile.badge, 'green');

    fit.setProfileBadge('green');
    expect(fit.profile.badge, '', reason: 'tocar la que tienes la quita');
  });

  test('the join date comes from the first workout, not from today', () {
    final old = DateTime.now().subtract(const Duration(days: 400));
    fit.sessions.add(LoggedSession(old, 1800, const []));
    fit.persistNow();
    fit.profile.since = null;
    fit.loadFromStore();

    expect(fit.memberSince.year, old.year);
    expect(fit.memberSince.month, old.month);
  });
}
