import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../l10n/l10n.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/charts.dart';
import '../widgets/home_folder.dart';
import '../widgets/svg_icon.dart';
import '../widgets/ui_kit.dart';
import 'progress_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    _selectedDayIndex = fit.todayIndex;
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final selectedDate = fit.dateForWeekday(_selectedDayIndex);
    final routines = fit.routinesOn(selectedDate);
    final routine = fit.routineOn(selectedDate);
    final isSelectedToday = _selectedDayIndex == fit.todayIndex;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        key: const PageStorageKey('home'),
        clipBehavior: Clip.none,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 116),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _topBar(gc, selectedDate, isSelectedToday),
            const SizedBox(height: 20),
            _hero(context, gc, selectedDate, routine, routines, isSelectedToday),
            const SizedBox(height: 14),
            _weekCard(context, gc),
            if (fit.photoDue) ...[
              const SizedBox(height: 14),
              _photoNudge(gc),
            ],
            const SizedBox(height: 30),
            _heading(gc, t.activityLabel, onMore: fit.goProgress),
            const SizedBox(height: 14),
            SoftCard(
              radius: 22,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Heatmap(
                levels: fit.heatmapWeeks,
                firstDay: fit.heatmapWeekDate(0),
                labels: fit.heatmapLabels,
                onTapDay: (i) => showDaySheet(context, fit.heatmapWeekDate(i)),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: HomeFolder(
                    title: _tc(t.routines),
                    detail: t.routineCount(fit.routines.length),
                    peek: const RoutinesPeek(),
                    onTap: fit.goRoutines,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: HomeFolder(
                    title: _tc(t.tools),
                    detail: t.calculatorsInside,
                    peek: const ToolsPeek(),
                    onTap: fit.goTools,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: HomeFolder(
                    title: _tc(t.journal),
                    detail: t.noteCount(fit.notes.length),
                    peek: const NotesPeek(),
                    onTap: fit.goNotes,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(GymColors gc, DateTime selectedDate, bool isSelectedToday) {
    final weekday = fit.weekdayAt(_selectedDayIndex);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (isSelectedToday ? t.today : t.weekday(weekday)).toUpperCase(),
                style: AppTheme.f(10.5,
                    weight: FontWeight.w700,
                    color: gc.textTertiary,
                    letterSpacing: 1.4),
              ),
              const SizedBox(height: 3),
              Text(
                t.longDate(selectedDate),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.f(21, color: gc.text),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: fit.goProgress,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: gc.accentSoft,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: gc.accent.withValues(alpha: 0.35), width: 1.2),
            ),
            child: Row(
              children: [
                SvgPathIcon(Ic.flame, size: 16, color: gc.accent),
                const SizedBox(width: 6),
                Text('${fit.currentStreak}d',
                    style: AppTheme.f(14, weight: FontWeight.w800, color: gc.accent)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _tc(String s) => titleCase(s);

  Widget _heading(GymColors gc, String title, {VoidCallback? onMore}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onMore,
      child: Row(
        children: [
          Text(_tc(title), style: AppTheme.f(20, weight: FontWeight.w800, color: gc.text)),
          const Spacer(),
          if (onMore != null)
            Icon(PhosphorIconsBold.caretRight, size: 15, color: gc.accent),
        ],
      ),
    );
  }

  String _topMuscleGroup(List<Exercise> exercises) {
    if (exercises.isEmpty) return 'Pick a Muscle Group';
    final counts = <String, int>{};
    for (final ex in exercises) {
      if (ex.primary.isNotEmpty) {
        final g = muscleGroup(ex.primary);
        counts[g] = (counts[g] ?? 0) + 2;
      }
      for (final s in ex.secondary) {
        if (s.isNotEmpty) {
          final g = muscleGroup(s);
          counts[g] = (counts[g] ?? 0) + 1;
        }
      }
    }
    if (counts.isEmpty) return 'Pick a Muscle Group';
    var topGroup = '';
    var maxCount = -1;
    for (final entry in counts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        topGroup = entry.key;
      }
    }
    return t.muscleGroupName(topGroup);
  }

  Widget _hero(
    BuildContext context,
    GymColors gc,
    DateTime selectedDate,
    Routine? routine,
    List<Routine> routines,
    bool isSelectedToday,
  ) {
    final exercises = routine != null ? fit.routineExercises(routine, selectedDate.weekday) : const <Exercise>[];
    final isRoutine = routine != null && exercises.isNotEmpty;
    final weekday = fit.weekdayAt(_selectedDayIndex);
    final label = isSelectedToday
        ? (isRoutine ? t.todaysRoutine : t.todaysFocus)
        : (isRoutine
            ? '${t.weekday(weekday)} · ${t.routines}'
            : '${t.weekday(weekday)} · ${t.todaysFocus}');
    final title = isRoutine
        ? _topMuscleGroup(exercises)
        : (isSelectedToday ? 'Pick a Muscle Group' : t.restDay);
    final subtitle = isRoutine
        ? [
            fit.routineTitle(routine),
            t.exerciseCount(exercises.length),
            if (routines.length > 1) t.routineOfDay(routines.indexOf(routine) + 1, routines.length),
          ].join(' · ')
        : (isSelectedToday
            ? 'Choose your target muscles and start training'
            : t.restDayShort);

    return SoftCard(
      radius: 26,
      borderColor: gc.accent.withValues(alpha: 0.18),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTheme.f(10.5,
                weight: FontWeight.w700, color: gc.textTertiary, letterSpacing: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.f(28,
                weight: FontWeight.w800, color: gc.text, height: 1.15),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.f(13, weight: FontWeight.w500, color: gc.textSecondary),
          ),
          const SizedBox(height: 20),
          if (isRoutine)
            PrimaryButton(
              label: t.startWorkout,
              icon: Ic.play,
              height: 50,
              onTap: () => fit.startRoutine(routine, on: selectedDate, weekday: selectedDate.weekday),
            )
          else if (isSelectedToday)
            PrimaryButton(
              label: t.startWorkout,
              icon: Ic.play,
              height: 50,
              onTap: () => fit.startWorkout(null),
            )
          else
            PrimaryButton(
              label: t.routines,
              icon: Ic.play,
              height: 50,
              onTap: fit.goRoutines,
            ),
        ],
      ),
    );
  }

  Widget _weekCard(BuildContext context, GymColors gc) {
    return Container(
      decoration: BoxDecoration(
        color: gc.bgRaised,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: gc.border.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [for (int i = 0; i < 7; i++) _weekDay(context, gc, i)],
      ),
    );
  }

  Widget _weekDay(BuildContext context, GymColors gc, int i) {
    final done = fit.isDayDone(i);
    final isToday = i == fit.todayIndex;
    final isSelected = i == _selectedDayIndex;
    final hasPlanned = fit.routinesOn(fit.dateForWeekday(i)).isNotEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedDayIndex = i;
        });
      },
      onLongPress: fit.isSessionDay(i)
          ? () => showDaySheet(context, fit.dateForWeekday(i))
          : (i <= fit.todayIndex ? () => fit.toggleCheckin(i) : null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? gc.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: gc.accent.withValues(alpha: 0.45), width: 1.2)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.weekdayInitial(fit.weekdayAt(i)),
              style: AppTheme.f(
                12,
                weight: isSelected || isToday ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? gc.accent
                    : (isToday ? gc.text : gc.textTertiary),
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: done
                    ? gc.accent
                    : (isSelected ? gc.bgRaised : gc.bgRaised2),
                shape: BoxShape.circle,
                border: isToday && !done
                    ? Border.all(color: gc.accent, width: 2)
                    : (isSelected && !done
                        ? Border.all(color: gc.border.withValues(alpha: 0.5), width: 1)
                        : null),
                boxShadow: done
                    ? [
                        BoxShadow(
                          color: gc.accent.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: done
                  ? Center(child: SvgPathIcon(Ic.checkBold, size: 13, color: gc.onEmber))
                  : (hasPlanned
                      ? Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isSelected ? gc.accent : gc.textTertiary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoNudge(GymColors gc) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: fit.goMoments,
      child: SoftCard(
        radius: 22,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Row(
          children: [
            Icon(PhosphorIconsRegular.camera, size: 19, color: gc.accent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.photoDueNow, style: AppTheme.f(14.5, color: gc.text)),
                  const SizedBox(height: 2),
                  Text(t.photoInterval(fit.photoIntervalDays),
                      style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary)),
                ],
              ),
            ),
            Icon(PhosphorIconsBold.caretRight, size: 14, color: gc.textTertiary),
          ],
        ),
      ),
    );
  }
}

