import 'package:flutter_test/flutter_test.dart';
import 'package:keizoku/models/profile.dart';
import 'package:keizoku/services/local_store.dart';
import 'package:keizoku/state/fit_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.instance.init();
    fit.saveAndExit();
    fit.routines.clear();
    fit.weeklyPlan.clear();
    fit.customExercises.clear();
    fit.profile = Profile();
  });

  test('backup code is automatically generated in GYM-XXXX-XXXX format', () {
    final code = fit.backupCode;
    expect(code, startsWith('GYM-'));
    expect(code.length, 13); // GYM-XXXX-XXXX
    expect(RegExp(r'^GYM-[A-Z0-9]{4}-[A-Z0-9]{4}$').hasMatch(code), isTrue);
  });

  test('backup code survives json serialization and loading from store', () {
    final originalCode = fit.backupCode;
    fit.profile.name = 'Champion';
    fit.setProfileHandle('champion_user');
    fit.persistNow();

    final json = fit.toJson();
    expect(json['backupCode'], originalCode);

    // Simulate reload
    fit.loadFromStore();
    expect(fit.backupCode, originalCode);
  });

  test('setting a custom backup code persists correctly', () {
    fit.backupCode = 'GYM-TEST-1234';
    fit.persistNow();

    fit.loadFromStore();
    expect(fit.backupCode, 'GYM-TEST-1234');
  });
}
