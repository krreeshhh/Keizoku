import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../catalog/exercise_catalog.dart';
import '../l10n/l10n.dart';
import '../services/firebase_service.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/body_rulers.dart';
import '../widgets/entrance.dart';
import '../widgets/restore_account_sheet.dart';
import '../widgets/ui_kit.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  late final TextEditingController _name = TextEditingController();
  late final TextEditingController _handle = TextEditingController();
  bool _handleManuallyEdited = false;
  Timer? _handleDebounce;
  bool _checkingHandle = false;
  bool? _handleAvailable;
  String? _handleError;
  bool _validatingStep1 = false;
  int _index = 0;
  static const _last = 5;
  final Map<String, Set<String>> _places = {};

  @override
  void initState() {
    super.initState();
    _handle.addListener(_onHandleChanged);
  }

  @override
  void dispose() {
    _handleDebounce?.cancel();
    _page.dispose();
    _name.dispose();
    _handle.removeListener(_onHandleChanged);
    _handle.dispose();
    super.dispose();
  }

  void _onNameChanged(String val) {
    if (!_handleManuallyEdited) {
      final auto = val.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
      _handle.text = auto;
    }
  }

  void _onHandleChanged() {
    final raw = _handle.text.trim().toLowerCase().replaceAll('@', '');
    final clean = raw.replaceAll(RegExp(r'[^a-z0-9_]'), '');

    _handleDebounce?.cancel();
    if (clean.isEmpty) {
      setState(() {
        _checkingHandle = false;
        _handleAvailable = null;
        _handleError = null;
      });
      return;
    }
    if (clean.length < 3) {
      setState(() {
        _checkingHandle = false;
        _handleAvailable = false;
        _handleError = 'Must be at least 3 characters';
      });
      return;
    }

    setState(() {
      _checkingHandle = true;
      _handleError = null;
    });

    _handleDebounce = Timer(const Duration(milliseconds: 320), () async {
      final available = await firebaseService.isHandleAvailable(clean);
      if (!mounted) return;
      setState(() {
        _checkingHandle = false;
        _handleAvailable = available;
        _handleError = available ? null : 'Username is already taken';
      });
    });
  }

  Future<void> _tryAdvanceFromName() async {
    final raw = _handle.text.trim().toLowerCase().replaceAll('@', '');
    final clean = raw.replaceAll(RegExp(r'[^a-z0-9_]'), '');
    if (clean.isEmpty) {
      setState(() => _handleError = 'Please choose a username');
      return;
    }
    if (clean.length < 3) {
      setState(() => _handleError = 'Must be at least 3 characters');
      return;
    }

    setState(() => _validatingStep1 = true);
    final available = await firebaseService.isHandleAvailable(clean);
    if (!mounted) return;
    setState(() => _validatingStep1 = false);

    if (!available) {
      setState(() {
        _handleAvailable = false;
        _handleError = 'Username is already taken';
      });
      return;
    }

    _go(2);
  }

  void _go(int i) {
    _page.animateToPage(i, duration: const Duration(milliseconds: 340), curve: Curves.easeOutCubic);
  }

  void _onPage(int i) => setState(() => _index = i);

  Future<void> _finish() async {
    final typed = _name.text.trim();
    if (typed.isNotEmpty) fit.updateProfile(name: typed);
    final cleanHandle = _handle.text.trim().toLowerCase().replaceAll('@', '').replaceAll(RegExp(r'[^a-z0-9_]'), '');
    if (cleanHandle.isNotEmpty) {
      fit.setProfileHandle(cleanHandle);
      await firebaseService.claimHandle(cleanHandle);
      await firebaseService.syncUserProfile();
    }
    String? first;
    for (final preset in kPlacePresets) {
      final gear = _places[preset];
      if (gear == null) continue;
      final id = fit.addPlace(t.placePresetName(preset), equipment: {...gear, 'Bodyweight'});
      if (id.isNotEmpty) first ??= id;
    }
    if (first != null && fit.activePlaceId != first) fit.setActivePlace(first);
    fit.completeOnboarding();
  }

  Future<void> _openRestoreAccount() async {
    final restored = await showRestoreAccountSheet(
      context,
      onRestored: () {
        fit.completeOnboarding();
      },
    );
    if (restored == true && mounted) {
      fit.completeOnboarding();
    }
  }

  Widget _in(int order, Widget child) => Rise(index: order, child: child);

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return Scaffold(
      backgroundColor: gc.bg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(child: _Glow(gc)),
          const Positioned.fill(child: AppBackground(pattern: 'dots')),
          SafeArea(
            child: Column(
              children: [
                _topBar(gc),
                Expanded(
                  child: PageView(
                    controller: _page,
                    onPageChanged: _onPage,
                    children: [
                      _welcome(gc),
                      _nameStep(gc),
                      _unitsStep(gc),
                      _bodyStep(gc),
                      _goalStep(gc),
                      _placeStep(gc),
                    ],
                  ),
                ),
                _bottomBar(gc),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(GymColors gc) {
    if (_index == 0) {
      return const SizedBox(height: 12);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          for (int i = 1; i <= _last; i++)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                margin: EdgeInsets.only(right: i < _last ? 6 : 0),
                height: 3,
                decoration: BoxDecoration(
                  color: i <= _index ? gc.text : gc.bgRaised2,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bottomBar(GymColors gc) {
    if (_index == 0) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              label: 'Create Account',
              onTap: () => _go(1),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openRestoreAccount,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: gc.bgRaised,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: gc.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIconsBold.key, size: 16, color: gc.accent),
                    const SizedBox(width: 8),
                    Text(
                      'I have an account',
                      style: AppTheme.f(14, weight: FontWeight.w700, color: gc.text),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isStep1 = _index == 1;
    final canAdvance = !isStep1 || (!_checkingHandle && _handleError == null && !_validatingStep1);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 22),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _go(_index - 1),
            child: Container(
              width: 56,
              height: 56,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(color: gc.bgRaised, shape: BoxShape.circle),
              child: Icon(PhosphorIconsBold.arrowLeft, size: 18, color: gc.textSecondary),
            ),
          ),
          Expanded(
            child: PrimaryButton(
              label: _validatingStep1
                  ? 'Checking...'
                  : (_index == _last ? t.welcomeStart : t.next),
              onTap: !canAdvance
                  ? null
                  : () {
                      if (_index == _last) {
                        _finish();
                      } else if (isStep1) {
                        _tryAdvanceFromName();
                      } else {
                        _go(_index + 1);
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(
    GymColors gc, {
    required int step,
    required String title,
    required String why,
    required Widget child,
  }) {
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: math.max(0, box.maxHeight - 36)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _in(0, Padding(padding: const EdgeInsets.only(left: 4), child: _label(gc, t.onbStep(step, _last)))),
              const SizedBox(height: 10),
              _in(
                1,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(title,
                      style: AppTheme.f(30, weight: FontWeight.w800, color: gc.text, height: 1.12)),
                ),
              ),
              const SizedBox(height: 10),
              _in(
                2,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(why,
                      style: AppTheme.f(13.5, weight: FontWeight.w500, color: gc.textSecondary, height: 1.45)),
                ),
              ),
              const SizedBox(height: 26),
              _in(3, child),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(GymColors gc, String text) => Text(text.toUpperCase(),
      style: AppTheme.f(10.5, weight: FontWeight.w700, color: gc.textTertiary, letterSpacing: 1.3));

  Widget _group(GymColors gc, List<Widget> rows) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: gc.bgRaised, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, indent: 16, endIndent: 16, color: gc.border.withValues(alpha: 0.6)),
            rows[i],
          ],
        ],
      ),
    );
  }

  Widget _rowIcon(GymColors gc, IconData icon, {Color? color}) => Padding(
        padding: const EdgeInsets.only(right: 14),
        child: SizedBox(width: 22, child: Icon(icon, size: 19, color: color ?? gc.textSecondary)),
      );

  Widget _welcome(GymColors gc) {
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight - 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _in(
                0,
                Center(
                  child: Image.asset('assets/img/runner.png',
                      height: 196, opacity: const AlwaysStoppedAnimation(0.9)),
                ),
              ),
              const SizedBox(height: 26),
              _in(
                1,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(t.welcomeKicker.toUpperCase(),
                      style: AppTheme.f(10.5, weight: FontWeight.w700, color: gc.textTertiary, letterSpacing: 1.6)),
                ),
              ),
              const SizedBox(height: 8),
              _in(
                2,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text('Keizoku',
                      style: AppTheme.f(44, weight: FontWeight.w800, color: gc.text, height: 1)),
                ),
              ),
              const SizedBox(height: 12),
              _in(
                3,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(t.welcomeBlurb,
                      style: AppTheme.f(14.5, weight: FontWeight.w500, color: gc.textSecondary, height: 1.5)),
                ),
              ),
              const SizedBox(height: 22),
              _in(
                4,
                _group(gc, [
                  _promise(gc, PhosphorIconsRegular.gift, t.freeForever, t.freeForeverWhy),
                  _promise(gc, PhosphorIconsRegular.arrowsClockwise, t.yoursToTake, t.yoursToTakeWhy),
                  _promise(gc, PhosphorIconsRegular.shieldCheck, t.fullyOffline, t.fullyOfflineWhy),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _promise(GymColors gc, IconData icon, String title, String why) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 1), child: _rowIcon(gc, icon)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.f(14.5, weight: FontWeight.w600, color: gc.text)),
                  const SizedBox(height: 3),
                  Text(why,
                      style: AppTheme.f(12.5, weight: FontWeight.w500, color: gc.textSecondary, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _nameStep(GymColors gc) {
    return _step(
      gc,
      step: 1,
      title: t.onbNameTitle,
      why: t.onbNameWhy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _group(gc, [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Row(
                children: [
                  _rowIcon(gc, PhosphorIconsRegular.userCircle),
                  Expanded(
                    child: TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      style: AppTheme.f(16, weight: FontWeight.w700, color: gc.text),
                      cursorColor: gc.accent,
                      onChanged: _onNameChanged,
                      decoration: InputDecoration(
                        hintText: t.onbNameHint,
                        hintStyle: AppTheme.f(16, weight: FontWeight.w600, color: gc.textTertiary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Row(
                children: [
                  _rowIcon(gc, PhosphorIconsRegular.at),
                  Expanded(
                    child: TextField(
                      controller: _handle,
                      textInputAction: TextInputAction.done,
                      style: AppTheme.f(16, weight: FontWeight.w700, color: gc.text),
                      cursorColor: gc.accent,
                      onChanged: (_) => _handleManuallyEdited = true,
                      onSubmitted: (_) => _tryAdvanceFromName(),
                      decoration: InputDecoration(
                        hintText: 'username',
                        hintStyle: AppTheme.f(16, weight: FontWeight.w600, color: gc.textTertiary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 18),
                        suffixIcon: _checkingHandle
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: gc.accent),
                                ),
                              )
                            : _handleAvailable != null && _handle.text.trim().isNotEmpty
                                ? Icon(
                                    _handleAvailable!
                                        ? PhosphorIconsBold.checkCircle
                                        : PhosphorIconsBold.warningCircle,
                                    color: _handleAvailable! ? gc.sage : gc.danger,
                                    size: 20,
                                  )
                                : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]),
          if (_handleError != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  Icon(PhosphorIconsFill.warning, size: 14, color: gc.danger),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _handleError!,
                      style: AppTheme.f(12, weight: FontWeight.w600, color: gc.danger),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_handleAvailable == true && _handle.text.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  Icon(PhosphorIconsFill.checkCircle, size: 14, color: gc.sage),
                  const SizedBox(width: 6),
                  Text(
                    'Username is available!',
                    style: AppTheme.f(12, weight: FontWeight.w600, color: gc.sage),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bodyStep(GymColors gc) {
    final p = fit.profile;
    return _step(
      gc,
      step: 3,
      title: t.onbBodyTitle,
      why: t.onbBodyWhy,
      child: _group(gc, [
        _bodyRow(
          gc,
          PhosphorIconsRegular.genderIntersex,
          t.sexLabel,
          SegToggle([
            SegOption(t.male, p.sex == 'male', () => _up(() => fit.updateProfile(sex: 'male'))),
            SegOption(t.female, p.sex == 'female', () => _up(() => fit.updateProfile(sex: 'female'))),
          ]),
        ),
        _valueRow(gc, PhosphorIconsRegular.cake, t.ageLabel, '${p.age}', editAge),
        _valueRow(gc, PhosphorIconsRegular.ruler, t.heightLabel, fit.heightLabel(p.heightCm), editHeight),
        _valueRow(gc, PhosphorIconsRegular.scales, t.weightLabel, fit.weightLabel(p.weightKg), editBodyWeight),
      ]),
    );
  }

  Widget _bodyRow(GymColors gc, IconData icon, String label, Widget control) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 58),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _rowIcon(gc, icon),
              Expanded(
                child: Text(sentenceCase(label),
                    style: AppTheme.f(14.5, weight: FontWeight.w500, color: gc.text)),
              ),
              const SizedBox(width: 12),
              control,
            ],
          ),
        ),
      );

  Widget _valueRow(GymColors gc, IconData icon, String label, String value,
      Future<void> Function(BuildContext) edit) {
    return Semantics(
      button: true,
      label: sentenceCase(label),
      value: value,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => edit(context).then((_) => _up(() {})),
        child: _bodyRow(
          gc,
          icon,
          label,
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(value, style: AppTheme.f(15.5, weight: FontWeight.w700, color: gc.text)),
            const SizedBox(width: 8),
            Icon(PhosphorIconsBold.caretRight, size: 13, color: gc.textTertiary),
          ]),
        ),
      ),
    );
  }

  Widget _goalStep(GymColors gc) {
    final goal = fit.profile.weeklyGoal;
    return _step(
      gc,
      step: 4,
      title: t.onbGoalTitle,
      why: t.onbGoalWhy,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
        decoration: BoxDecoration(color: gc.bgRaised, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label(gc, t.weeklyGoal),
            const SizedBox(height: 8),
            Text(t.perWeek(goal), style: AppTheme.f(22, weight: FontWeight.w800, color: gc.text)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var n = 1; n <= 7; n++)
                  Semantics(
                    button: true,
                    selected: n == goal,
                    label: t.perWeek(n),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _up(() => fit.updateProfile(weeklyGoalDelta: n - goal)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: n <= goal ? gc.ember : gc.bgRaised2,
                          shape: BoxShape.circle,
                        ),
                        child: Text('$n',
                            style: AppTheme.f(13.5,
                                weight: FontWeight.w800, color: n <= goal ? gc.onEmber : gc.textTertiary)),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _unitsStep(GymColors gc) {
    return _step(
      gc,
      step: 2,
      title: t.onbUnitsTitle,
      why: t.autofills,
      child: Row(
        children: [
          for (final u in const ['kg', 'lb']) ...[
            if (u == 'lb') const SizedBox(width: 12),
            Expanded(child: _unitTile(gc, u)),
          ],
        ],
      ),
    );
  }

  Widget _unitTile(GymColors gc, String u) {
    final on = fit.units == u;
    final sample = u == 'kg' ? '60 kg · 175 cm · 5 km' : '135 lb · 5′9″ · 3 mi';
    return Semantics(
      button: true,
      selected: on,
      label: u,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _up(() => fit.setUnits(u)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 118,
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
          decoration: BoxDecoration(
            color: gc.bgRaised,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: on ? gc.ember : Colors.transparent, width: 1.6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Spacer(),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: on ? 1 : 0,
                    child: Icon(PhosphorIconsFill.checkCircle, size: 18, color: gc.ember),
                  ),
                ],
              ),
              const Spacer(),
              Text(u, style: AppTheme.f(30, weight: FontWeight.w800, color: on ? gc.ember : gc.text, height: 1)),
              const SizedBox(height: 6),
              Text(sample, style: AppTheme.f(11.5, weight: FontWeight.w600, color: gc.textTertiary)),
            ],
          ),
        ),
      ),
    );
  }

  static const _placeIcons = {
    'gym': PhosphorIconsRegular.barbell,
    'home': PhosphorIconsRegular.house,
    'outdoors': PhosphorIconsRegular.tree,
  };

  Widget _placeStep(GymColors gc) {
    return _step(
      gc,
      step: 5,
      title: t.onbPlaceTitle,
      why: t.onbPlaceWhy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _group(gc, [for (final preset in kPlacePresets) _placeRow(gc, preset)]),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _places.isEmpty
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final preset in kPlacePresets)
                          if (_places[preset] case final gear?) ...[
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: _label(
                                  gc,
                                  _places.length > 1
                                      ? '${t.placePresetName(preset)} · ${t.onbPlaceGear}'
                                      : t.onbPlaceGear),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final e in kFilterEquipment)
                                  if (e != 'Bodyweight')
                                    Pill(
                                      label: t.equipment(e),
                                      bg: gear.contains(e) ? gc.ember : gc.bgRaised,
                                      fg: gear.contains(e) ? gc.onEmber : gc.textSecondary,
                                      onTap: () => setState(() {
                                        if (!gear.remove(e)) gear.add(e);
                                      }),
                                      hPad: 14,
                                      vPad: 8,
                                      fontSize: 12.5,
                                    ),
                              ],
                            ),
                            const SizedBox(height: 18),
                          ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _placeRow(GymColors gc, String preset) {
    final on = _places.containsKey(preset);
    final gear = {...?(_places[preset] ?? kPlacePresetGear[preset]), 'Bodyweight'};
    final n = fit.allExercises.where((e) => gear.contains(e.equipment)).length;
    return Semantics(
      button: true,
      selected: on,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() {
          if (_places.remove(preset) == null) {
            _places[preset] = {...?kPlacePresetGear[preset]}..remove('Bodyweight');
          }
        }),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _rowIcon(gc, _placeIcons[preset]!, color: on ? gc.ember : null),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.placePresetName(preset),
                        style: AppTheme.f(14.5,
                            weight: on ? FontWeight.w800 : FontWeight.w600, color: on ? gc.ember : gc.text)),
                    const SizedBox(height: 2),
                    Text(t.exerciseCount(n),
                        style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary)),
                  ],
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: on ? 1 : 0,
                child: Icon(PhosphorIconsFill.checkCircle, size: 18, color: gc.ember),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _up(VoidCallback action) {
    action();
    setState(() {});
  }
}

class _Glow extends StatelessWidget {
  const _Glow(this.gc);

  final GymColors gc;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.9, -0.85),
              radius: 1.1,
              colors: [gc.ember.withValues(alpha: 0.12), gc.bg.withValues(alpha: 0)],
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.9, 0.9),
                radius: 1.0,
                colors: [gc.brass.withValues(alpha: 0.07), gc.bg.withValues(alpha: 0)],
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ),
      );
}
