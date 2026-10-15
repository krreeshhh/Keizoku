enum SetKind { normal, warmup, drop, failure, restPause }

SetKind setKindFrom(Object? raw) {
  final i = (raw as num?)?.toInt() ?? 0;
  return SetKind.values[i.clamp(0, SetKind.values.length - 1)];
}

const _rpeTable = [
  1.0, .978, .955, .939, .922, .907, .892, .878, .863, .85, .837, .824, .811, .799, .786, .774,
  .762, .751, .739, .723, .707, .694, .68, .667, .653, .64, .626, .613, .599, .586, .574,
];

double? rpePercent(int reps, double? rpe) {
  if (rpe == null || rpe < 6 || rpe > 10 || reps < 1 || reps > 12) return null;
  final i = (reps - 1) * 2 + ((10 - rpe) * 2).round();
  return i < _rpeTable.length ? _rpeTable[i] : null;
}

class LoggedSet {
  LoggedSet(this.reps, this.weight, {this.kind = SetKind.normal, this.rpe, this.sec, this.km});
  final int reps;
  final double weight;
  final SetKind kind;
  final double? rpe;
  final int? sec;
  final double? km;

  bool get counts => kind != SetKind.warmup;
  double get volume => reps * weight;

  double get oneRm {
    if (reps <= 0) return 0;
    final pct = rpePercent(reps, rpe);
    return pct == null ? weight * (1 + reps / 30) : weight / pct;
  }

  Map<String, dynamic> toJson() => {
        'r': reps,
        'w': weight,
        if (kind != SetKind.normal) 'k': kind.index,
        if (rpe != null) 'e': rpe,
        if (sec != null) 't': sec,
        if (km != null) 'km': km,
      };
  factory LoggedSet.fromJson(Map<String, dynamic> j) => LoggedSet(
        (j['r'] as num).toInt(),
        (j['w'] as num).toDouble(),
        kind: setKindFrom(j['k']),
        rpe: (j['e'] as num?)?.toDouble(),
        sec: (j['t'] as num?)?.toInt(),
        km: (j['km'] as num?)?.toDouble(),
      );
}

enum PrKind {
  weight,
  distance,
  time,
  reps;

  double score(LoggedSet s) => switch (this) {
        PrKind.weight => s.weight,
        PrKind.distance => s.km ?? 0,
        PrKind.time => (s.sec ?? 0).toDouble(),
        PrKind.reps => s.reps.toDouble(),
      };
}

typedef PersonalRecord = ({String id, String name, PrKind kind, double best, double oneRm});

class LoggedExercise {
  LoggedExercise(this.id, this.name, this.primary, this.sets);
  final String id;
  final String name;
  final String primary;
  final List<LoggedSet> sets;

  List<LoggedSet> get workingSets => sets.where((s) => s.counts).toList();

  double get volume => workingSets.fold(0.0, (s, x) => s + x.volume);
  double get topWeight {
    final w = workingSets;
    return w.isEmpty ? 0 : w.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
  }

  double get bestOneRm {
    final w = workingSets;
    return w.isEmpty ? 0 : w.map((s) => s.oneRm).reduce((a, b) => a > b ? a : b);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'n': name,
        'p': primary,
        's': sets.map((s) => s.toJson()).toList(),
      };
  factory LoggedExercise.fromJson(Map<String, dynamic> j) => LoggedExercise(
        j['id'] as String,
        j['n'] as String,
        j['p'] as String,
        (j['s'] as List).map((e) => LoggedSet.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class LoggedSession {
  LoggedSession(this.date, this.durationSec, this.exercises);
  final DateTime date;
  final int durationSec;
  final List<LoggedExercise> exercises;

  double get volume => exercises.fold(0.0, (s, e) => s + e.volume);
  int get setCount => exercises.fold(0, (s, e) => s + e.workingSets.length);

  Map<String, dynamic> toJson() => {
        'd': date.toIso8601String(),
        'dur': durationSec,
        'ex': exercises.map((e) => e.toJson()).toList(),
      };
  factory LoggedSession.fromJson(Map<String, dynamic> j) => LoggedSession(
        DateTime.parse(j['d'] as String),
        (j['dur'] as num?)?.toInt() ?? 0,
        (j['ex'] as List).map((e) => LoggedExercise.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class BodyweightEntry {
  BodyweightEntry(this.date, this.kg);
  final DateTime date;
  final double kg;

  Map<String, dynamic> toJson() => {'d': date.toIso8601String(), 'kg': kg};
  factory BodyweightEntry.fromJson(Map<String, dynamic> j) =>
      BodyweightEntry(DateTime.parse(j['d'] as String), (j['kg'] as num).toDouble());
}

class PlannedSet {
  const PlannedSet({this.reps, this.weightKg, this.kind = SetKind.normal, this.sec, this.km});
  final int? reps;
  final double? weightKg;
  final SetKind kind;
  final int? sec;
  final double? km;

  PlannedSet copyWith({
    int? reps,
    double? weightKg,
    SetKind? kind,
    int? sec,
    double? km,
    bool autoWeight = false,
  }) =>
      PlannedSet(
        reps: reps ?? this.reps,
        weightKg: autoWeight ? null : (weightKg ?? this.weightKg),
        kind: kind ?? this.kind,
        sec: sec ?? this.sec,
        km: km ?? this.km,
      );

  Map<String, dynamic> toJson() => {
        if (reps != null) 'r': reps,
        if (weightKg != null) 'w': weightKg,
        if (kind != SetKind.normal) 'k': kind.index,
        if (sec != null) 't': sec,
        if (km != null) 'km': km,
      };
  factory PlannedSet.fromJson(Map<String, dynamic> j) => PlannedSet(
        reps: (j['r'] as num?)?.toInt(),
        weightKg: (j['w'] as num?)?.toDouble(),
        kind: setKindFrom(j['k']),
        sec: (j['t'] as num?)?.toInt(),
        km: (j['km'] as num?)?.toDouble(),
      );
}

class Routine {
  Routine(
    this.id,
    this.name,
    this.exerciseIds, {
    Map<String, int>? sets,
    Set<String>? chained,
    Map<String, List<PlannedSet>>? plan,
    Map<String, int>? rest,
    Map<int, List<String>>? dayExercises,
    Map<int, Map<String, int>>? daySets,
    Map<int, Set<String>>? dayChained,
    Map<int, Map<String, List<PlannedSet>>>? dayPlan,
    Map<int, Map<String, int>>? dayRest,
    this.group = '',
    this.color = -1,
  })  : sets = sets ?? {},
        chained = chained ?? {},
        plan = plan ?? {},
        rest = rest ?? {},
        dayExercises = dayExercises ?? {},
        daySets = daySets ?? {},
        dayChained = dayChained ?? {},
        dayPlan = dayPlan ?? {},
        dayRest = dayRest ?? {};

  final String id;
  String name;
  String group;
  int color;
  final List<String> exerciseIds;
  final Map<String, int> sets;
  final Set<String> chained;
  final Map<String, List<PlannedSet>> plan;
  final Map<String, int> rest;

  // Day specific workouts (1 = Monday ... 7 = Sunday)
  final Map<int, List<String>> dayExercises;
  final Map<int, Map<String, int>> daySets;
  final Map<int, Set<String>> dayChained;
  final Map<int, Map<String, List<PlannedSet>>> dayPlan;
  final Map<int, Map<String, int>> dayRest;

  List<String> exercisesOn(int weekday) {
    if (dayExercises.containsKey(weekday)) {
      return dayExercises[weekday] ?? const [];
    }
    return dayExercises.isEmpty ? exerciseIds : const [];
  }

  int get totalExerciseCount {
    final ids = <String>{};
    for (final l in dayExercises.values) {
      ids.addAll(l);
    }
    if (ids.isEmpty) ids.addAll(exerciseIds);
    return ids.length;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'n': name,
        'ex': exerciseIds,
        if (rest.isNotEmpty) 'r': rest,
        if (sets.isNotEmpty) 's': sets,
        if (chained.isNotEmpty) 'c': chained.toList(),
        if (group.isNotEmpty) 'g': group,
        if (color >= 0) 'k': color,
        if (plan.isNotEmpty)
          'p': plan.map((k, v) => MapEntry(k, v.map((s) => s.toJson()).toList())),
        if (dayExercises.isNotEmpty)
          'dex': dayExercises.map((k, v) => MapEntry(k.toString(), v)),
        if (daySets.isNotEmpty)
          'ds': daySets.map((k, v) => MapEntry(k.toString(), v)),
        if (dayChained.isNotEmpty)
          'dc': dayChained.map((k, v) => MapEntry(k.toString(), v.toList())),
        if (dayPlan.isNotEmpty)
          'dp': dayPlan.map((k, v) => MapEntry(
                k.toString(),
                v.map((exId, sets) => MapEntry(exId, sets.map((s) => s.toJson()).toList())),
              )),
        if (dayRest.isNotEmpty)
          'dr': dayRest.map((k, v) => MapEntry(k.toString(), v)),
      };

  factory Routine.fromJson(Map<String, dynamic> j) {
    final dex = ((j['dex'] as Map?) ?? const {}).map((k, v) => MapEntry(int.parse(k as String), (v as List).cast<String>()));
    final ds = ((j['ds'] as Map?) ?? const {}).map((k, v) => MapEntry(
          int.parse(k as String),
          ((v as Map?) ?? const {}).map((exId, s) => MapEntry(exId as String, (s as num).toInt())),
        ));
    final dc = ((j['dc'] as Map?) ?? const {}).map((k, v) => MapEntry(
          int.parse(k as String),
          ((v as List?) ?? const []).cast<String>().toSet(),
        ));
    final dp = ((j['dp'] as Map?) ?? const {}).map((k, v) => MapEntry(
          int.parse(k as String),
          ((v as Map?) ?? const {}).map((exId, sets) => MapEntry(
                exId as String,
                ((sets as List?) ?? const []).map((s) => PlannedSet.fromJson((s as Map).cast<String, dynamic>())).toList(),
              )),
        ));
    final dr = ((j['dr'] as Map?) ?? const {}).map((k, v) => MapEntry(
          int.parse(k as String),
          ((v as Map?) ?? const {}).map((exId, r) => MapEntry(exId as String, ((r as num).toInt()).clamp(0, 600))),
        ));

    final exList = ((j['ex'] as List?) ?? []).cast<String>();
    if (dex.isEmpty && exList.isNotEmpty) {
      dex[1] = [...exList];
    }

    return Routine(
      j['id'] as String,
      j['n'] as String,
      exList,
      sets: ((j['s'] as Map?) ?? const {}).map((k, v) => MapEntry(k as String, (v as num).toInt())),
      chained: ((j['c'] as List?) ?? const []).cast<String>().toSet(),
      plan: ((j['p'] as Map?) ?? const {}).map((k, v) => MapEntry(
            k as String,
            (v as List).map((s) => PlannedSet.fromJson((s as Map).cast<String, dynamic>())).toList(),
          )),
      rest: ((j['r'] as Map?) ?? const {}).map((k, v) => MapEntry(k as String, ((v as num).toInt()).clamp(0, 600))),
      dayExercises: dex,
      daySets: ds,
      dayChained: dc,
      dayPlan: dp,
      dayRest: dr,
      group: (j['g'] as String?) ?? '',
      color: (j['k'] as num?)?.toInt() ?? -1,
    );
  }
}
