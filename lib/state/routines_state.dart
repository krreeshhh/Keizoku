part of 'fit_state.dart';

const int kDefaultRoutineSets = 3;

mixin RoutinesState on FitCore, LibraryState, StatsState {
  String? activeRoutineId;
  int _routineSeq = 0;
  bool _editFromExercise = false;

  void goRoutines() => pushRoute('routines');

  void goSocial() => pushRoute('social');

  void backFromSocial() => popRoute();

  void goAiPlan() => pushRoute('ai-plan');

  void backFromAiPlan() => popRoute(fallback: 'routines');

  void backFromRoutines() => popRoute();

  Routine? _routine(String id) {
    for (final r in routines) {
      if (r.id == id) return r;
    }
    return null;
  }

  int? activeRoutineEditWeekday;

  Routine? get activeRoutine => activeRoutineId == null ? null : _routine(activeRoutineId!);

  List<Exercise> routineExercises(Routine r, [int? weekday]) {
    final day = weekday ?? activeRoutineEditWeekday ?? DateTime.now().weekday;
    final ids = r.exercisesOn(day);
    final out = <Exercise>[];
    for (final id in ids) {
      final e = exerciseById(id);
      if (e != null) out.add(e);
    }
    return out;
  }

  Routine? get todayRoutine => routineOn(DateTime.now());

  List<String> planIdsOn(int weekday) {
    if (weeklyPlan.containsKey(weekday)) {
      return [?weeklyPlan[weekday], if (multiPlan) ...?planExtras[weekday]];
    }
    // If weeklyPlan doesn't have an explicit entry, check routines having workouts on this weekday
    for (final r in routines) {
      if (r.dayExercises[weekday]?.isNotEmpty ?? false) return [r.id];
    }
    return const [];
  }

  List<Routine> routinesOn(DateTime day) => [for (final id in planIdsOn(day.weekday)) ?_routine(id)];

  bool plannedOn(int weekday, String routineId) => planIdsOn(weekday).contains(routineId);

  Routine? routineOn(DateTime day) {
    final list = routinesOn(day);
    if (list.isEmpty) {
      for (final r in routines) {
        if (r.dayExercises[day.weekday]?.isNotEmpty ?? false) return r;
      }
      return null;
    }
    final key = _dayKey(day);
    final done = sessions.where((s) => _dayKey(s.date) == key).length;
    return list[math.min(done, list.length - 1)];
  }

  int? weekdayForRoutine(String routineId) {
    for (final entry in weeklyPlan.entries) {
      if (entry.value == routineId) return entry.key;
    }
    return null;
  }

  int get firstAvailableWeekday {
    for (int i = 0; i < 7; i++) {
      final w = weekdayAt(i);
      if (weeklyPlan[w] == null) return w;
    }
    return DateTime.now().weekday;
  }

  void toggleMultiPlan() {
    multiPlan = !multiPlan;
    _persist();
    _refreshWidgets();
    syncTrainReminder();
    notifyListeners();
  }

  void togglePlanDay(int weekday, String routineId) {
    if (!multiPlan) return assignRoutineToDay(weekday, routineId);
    final extras = planExtras.putIfAbsent(weekday, () => []);
    if (weeklyPlan[weekday] == routineId) {
      if (extras.isEmpty) {
        weeklyPlan.remove(weekday);
      } else {
        weeklyPlan[weekday] = extras.removeAt(0);
      }
    } else if (!extras.remove(routineId)) {
      if (weeklyPlan[weekday] == null) {
        weeklyPlan[weekday] = routineId;
      } else {
        extras.add(routineId);
      }
    }
    if (extras.isEmpty) planExtras.remove(weekday);
    _persist();
    _refreshWidgets();
    syncTrainReminder();
    notifyListeners();
  }

  String createRoutine([String name = '']) {
    final id = 'r${DateTime.now().microsecondsSinceEpoch}-${_routineSeq++}';
    final r = Routine(id, name.trim(), []);
    routines.add(r);
    _persist();
    notifyListeners();
    return id;
  }

  void addRoutine(Routine r) {
    routines.add(r);
    _persist();
    notifyListeners();
  }

  void renameRoutine(String id, String name) {
    final r = _routine(id);
    if (r == null) return;
    r.name = name.trim();
    _persist();
    notifyListeners();
  }

  void setRoutineColor(String id, int color) {
    final r = _routine(id);
    if (r == null) return;
    r.color = color;
    _persist();
    notifyListeners();
  }

  String duplicateRoutine(String id) {
    final source = _routine(id);
    if (source == null) return '';
    final copy = createRoutine(t.copySuffix(routineTitle(source)));
    final made = _routine(copy)!;
    made.exerciseIds.addAll(source.exerciseIds);
    made.sets.addAll(source.sets);
    made.chained.addAll(source.chained);
    made.plan.addAll({for (final e in source.plan.entries) e.key: [...e.value]});
    made.rest.addAll(source.rest);
    made.dayExercises.addAll({for (final e in source.dayExercises.entries) e.key: [...e.value]});
    made.daySets.addAll({for (final e in source.daySets.entries) e.key: {...e.value}});
    made.dayChained.addAll({for (final e in source.dayChained.entries) e.key: {...e.value}});
    made.dayPlan.addAll({for (final e in source.dayPlan.entries) e.key: {for (final p in e.value.entries) p.key: [...p.value]}});
    made.dayRest.addAll({for (final e in source.dayRest.entries) e.key: {...e.value}});
    made.color = source.color;
    _persist();
    notifyListeners();
    return copy;
  }

  void deleteRoutine(String id) {
    _dropRoutine(id);
    _persist();
    notifyListeners();
  }

  void _dropRoutine(String id) {
    routines.removeWhere((r) => r.id == id);
    weeklyPlan.removeWhere((_, v) => v == id);
    for (final extras in planExtras.values) {
      extras.remove(id);
    }
    planExtras.removeWhere((_, v) => v.isEmpty);
    for (final day in [...planExtras.keys]) {
      if (weeklyPlan[day] != null) continue;
      final extras = planExtras[day]!;
      weeklyPlan[day] = extras.removeAt(0);
      if (extras.isEmpty) planExtras.remove(day);
    }
    if (activeRoutineId == id) activeRoutineId = null;
  }

  void toggleRoutineExercise(String routineId, String exId, [int? weekday]) {
    final r = _routine(routineId);
    if (r == null) return;
    final day = weekday ?? activeRoutineEditWeekday ?? DateTime.now().weekday;
    final list = r.dayExercises.putIfAbsent(day, () => []);
    final sets = r.daySets.putIfAbsent(day, () => {});
    final plan = r.dayPlan.putIfAbsent(day, () => {});
    final rest = r.dayRest.putIfAbsent(day, () => {});
    final chained = r.dayChained.putIfAbsent(day, () => {});

    if (list.remove(exId)) {
      sets.remove(exId);
      plan.remove(exId);
      rest.remove(exId);
      chained.remove(exId);
    } else {
      list.add(exId);
    }
    r.exerciseIds.clear();
    for (final l in r.dayExercises.values) {
      for (final id in l) {
        if (!r.exerciseIds.contains(id)) r.exerciseIds.add(id);
      }
    }
    _persist();
    notifyListeners();
  }

  void replaceRoutineExercise(String routineId, String from, String to, [int? weekday]) {
    final r = _routine(routineId);
    if (r == null) return;
    final day = weekday ?? activeRoutineEditWeekday ?? DateTime.now().weekday;
    final ids = r.dayExercises.putIfAbsent(day, () => [...r.exercisesOn(day)]);
    final at = ids.indexOf(from);
    if (at < 0 || ids.contains(to)) return;
    ids[at] = to;
    final atBase = r.exerciseIds.indexOf(from);
    if (atBase >= 0) r.exerciseIds[atBase] = to;
    final sets = r.daySets.putIfAbsent(day, () => {});
    final s = sets.remove(from);
    if (s != null) sets[to] = s;
    final plan = r.dayPlan.putIfAbsent(day, () => {});
    final p = plan.remove(from);
    if (p != null) plan[to] = [for (final x in p) PlannedSet(kind: x.kind)];
    final rest = r.dayRest.putIfAbsent(day, () => {});
    final re = rest.remove(from);
    if (re != null) rest[to] = re;
    final chained = r.dayChained.putIfAbsent(day, () => {});
    if (chained.remove(from)) chained.add(to);
    _persist();
    notifyListeners();
  }

  VoidCallback? removeRoutineExercise(String routineId, String exId, [int? weekday]) {
    final r = _routine(routineId);
    if (r == null) return null;
    final day = weekday ?? activeRoutineEditWeekday ?? DateTime.now().weekday;
    final list = r.dayExercises[day] ?? r.exerciseIds;
    final at = list.indexOf(exId);
    if (at < 0) return null;
    final sets = (r.daySets[day] ?? r.sets)[exId];
    final plan = (r.dayPlan[day] ?? r.plan)[exId];
    final rest = (r.dayRest[day] ?? r.rest)[exId];
    final chained = (r.dayChained[day] ?? r.chained).contains(exId);
    toggleRoutineExercise(routineId, exId, day);
    return () {
      final back = _routine(routineId);
      if (back == null) return;
      final backList = back.dayExercises.putIfAbsent(day, () => []);
      if (backList.contains(exId)) return;
      backList.insert(at.clamp(0, backList.length), exId);
      if (sets != null) (back.daySets.putIfAbsent(day, () => {}))[exId] = sets;
      if (plan != null) (back.dayPlan.putIfAbsent(day, () => {}))[exId] = plan;
      if (rest != null) (back.dayRest.putIfAbsent(day, () => {}))[exId] = rest;
      if (chained) (back.dayChained.putIfAbsent(day, () => {})).add(exId);
      _persist();
      notifyListeners();
    };
  }

  int routineSets(Routine r, String exId, [int? weekday]) {
    final day = weekday ?? activeRoutineEditWeekday ?? DateTime.now().weekday;
    final planned = (r.dayPlan[day] ?? r.plan)[exId];
    if (planned != null && planned.isNotEmpty) {
      final working = planned.where((p) => p.kind != SetKind.warmup).length;
      return working == 0 ? planned.length : working;
    }
    return (r.daySets[day] ?? r.sets)[exId] ?? (modeOf(exId) == 'cardio' ? 1 : kDefaultRoutineSets);
  }

  List<PlannedSet> plannedSets(Routine r, String exId, [int? weekday]) {
    final day = weekday ?? activeRoutineEditWeekday ?? DateTime.now().weekday;
    return (r.dayPlan[day] ?? r.plan)[exId] ?? const [];
  }

  int? routineRest(String? routineId, String exId, [int? weekday]) {
    if (routineId == null) return null;
    final r = _routine(routineId);
    if (r == null) return null;
    final day = weekday ?? activeRoutineEditWeekday ?? DateTime.now().weekday;
    return (r.dayRest[day] ?? r.rest)[exId];
  }

  void setRoutineRest(String routineId, String exId, int? seconds, [int? weekday]) {
    final r = _routine(routineId);
    if (r == null) return;
    final day = weekday ?? activeRoutineEditWeekday ?? DateTime.now().weekday;
    final restMap = r.dayRest.putIfAbsent(day, () => {});
    if (seconds == null) {
      restMap.remove(exId);
    } else {
      restMap[exId] = seconds <= 0 ? 0 : seconds.clamp(15, 600);
    }
    _persist();
    notifyListeners();
  }

  void setRoutineSetCount(String routineId, String exId, int n, [int? weekday]) {
    final r = _routine(routineId);
    if (r == null) return;
    final day = weekday ?? activeRoutineEditWeekday ?? DateTime.now().weekday;
    r.daySets.putIfAbsent(day, () => {})[exId] = n.clamp(1, 12);
    _persist();
    notifyListeners();
  }

  bool hasPlan(Routine r, String exId, [int? weekday]) {
    final day = weekday ?? activeRoutineEditWeekday ?? DateTime.now().weekday;
    return (r.dayPlan[day] ?? r.plan)[exId]?.isNotEmpty ?? false;
  }

  void setPlannedSets(String routineId, String exId, List<PlannedSet> sets, [int? weekday]) {
    final r = _routine(routineId);
    if (r == null) return;
    final day = weekday ?? activeRoutineEditWeekday ?? DateTime.now().weekday;
    final planMap = r.dayPlan.putIfAbsent(day, () => {});
    final setsMap = r.daySets.putIfAbsent(day, () => {});
    if (sets.isEmpty) {
      planMap.remove(exId);
    } else {
      planMap[exId] = List.unmodifiable(sets.take(20));
      setsMap[exId] = sets.where((p) => p.kind != SetKind.warmup).length.clamp(1, 20);
    }
    _persist();
    notifyListeners();
  }

  bool chainsToNext(Routine r, String exId, [int? weekday]) {
    final day = weekday ?? activeRoutineEditWeekday ?? DateTime.now().weekday;
    final ids = r.exercisesOn(day);
    final i = ids.indexOf(exId);
    final chained = r.dayChained[day] ?? r.chained;
    return i >= 0 && i < ids.length - 1 && chained.contains(exId);
  }

  void toggleChain(String routineId, String exId, [int? weekday]) {
    final r = _routine(routineId);
    if (r == null) return;
    final day = weekday ?? activeRoutineEditWeekday ?? DateTime.now().weekday;
    final chained = r.dayChained.putIfAbsent(day, () => {});
    if (!chained.remove(exId)) chained.add(exId);
    _persist();
    notifyListeners();
  }

  void bumpRoutineSets(String routineId, String exId, int delta, [int? weekday]) {
    final r = _routine(routineId);
    if (r == null) return;
    final day = weekday ?? activeRoutineEditWeekday ?? DateTime.now().weekday;
    final planned = (r.dayPlan[day] ?? r.plan)[exId];
    if (planned != null && planned.isNotEmpty) {
      final next = [...planned];
      if (delta > 0) {
        for (var i = 0; i < delta && next.length < 20; i++) {
          next.add(next
              .lastWhere((s) => s.kind != SetKind.warmup, orElse: () => const PlannedSet())
              .copyWith(kind: SetKind.normal));
        }
      } else {
        for (var i = 0; i < -delta; i++) {
          final last = next.lastIndexWhere((s) => s.kind != SetKind.warmup);
          if (last < 0 || next.where((s) => s.kind != SetKind.warmup).length <= 1) break;
          next.removeAt(last);
        }
      }
      setPlannedSets(routineId, exId, next, day);
      return;
    }
    final setsMap = r.daySets.putIfAbsent(day, () => {});
    setsMap[exId] = (routineSets(r, exId, day) + delta).clamp(1, 12);
    _persist();
    notifyListeners();
  }

  bool routineHas(String routineId, String exId, [int? weekday]) {
    final r = _routine(routineId);
    if (r == null) return false;
    final day = weekday ?? activeRoutineEditWeekday ?? DateTime.now().weekday;
    return r.exercisesOn(day).contains(exId);
  }

  void reorderRoutineExercise(String routineId, int from, int to, [int? weekday]) {
    final r = _routine(routineId);
    if (r == null) return;
    final day = weekday ?? activeRoutineEditWeekday ?? DateTime.now().weekday;
    final ids = r.dayExercises.putIfAbsent(day, () => [...r.exercisesOn(day)]);
    if (from < 0 || from >= ids.length) return;
    if (to > from) to -= 1;
    ids.insert(to.clamp(0, ids.length), ids.removeAt(from));
    r.exerciseIds.clear();
    for (final id in ids) {
      if (!r.exerciseIds.contains(id)) r.exerciseIds.add(id);
    }
    for (final l in r.dayExercises.values) {
      for (final id in l) {
        if (!r.exerciseIds.contains(id)) r.exerciseIds.add(id);
      }
    }
    persistNow();
    notifyListeners();
  }

  void assignRoutineToDay(int weekday, String? routineId) {
    planExtras.remove(weekday);
    if (routineId == null) {
      weeklyPlan.remove(weekday);
    } else {
      weeklyPlan[weekday] = routineId;
    }
    _persist();
    syncTrainReminder();
    notifyListeners();
  }

  void switchToDayRoutine(int weekday, {String? currentRoutineId}) {
    activeRoutineEditWeekday = weekday;
    notifyListeners();
  }

  void openRoutine(String id) {
    if (route != 'routine-edit') _editFromExercise = false;
    activeRoutineId = id;
    route = 'routine-edit';
    notifyListeners();
  }

  void addToRoutineAndEdit(String? routineId, String exId) {
    final id = routineId ?? createRoutine();
    if (!routineHas(id, exId)) toggleRoutineExercise(id, exId);
    activeRoutineId = id;
    _editFromExercise = true;
    pushRoute('routine-edit');
  }

  int routinesWith(String exId) => routines.where((r) => r.exerciseIds.contains(exId)).length;

  String routineTitle(Routine r) => r.name.isEmpty ? t.newRoutineName : r.name;

  void closeRoutineEdit() {
    if (_editFromExercise) {
      _editFromExercise = false;
      return popRoute(fallback: 'routines');
    }
    route = 'routines';
    notifyListeners();
  }
}
