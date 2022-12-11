import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lotti/blocs/habits/habits_cubit.dart';
import 'package:lotti/blocs/habits/habits_state.dart';
import 'package:lotti/themes/theme.dart';
import 'package:lotti/widgets/app_bar/title_app_bar.dart';
import 'package:lotti/widgets/charts/habits/dashboard_habits_chart.dart';
import 'package:lotti/widgets/charts/habits/habit_completion_rate_chart.dart';
import 'package:lotti/widgets/charts/utils.dart';
import 'package:lotti/widgets/misc/timespan_segmented_control.dart';

class HabitsTabPage extends StatelessWidget {
  const HabitsTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<HabitsCubit, HabitsState>(
      builder: (context, HabitsState state) {
        final cubit = context.read<HabitsCubit>();
        final timeSpanDays = state.timeSpanDays;

        final rangeStart = getStartOfDay(
          DateTime.now().subtract(Duration(days: timeSpanDays - 1)),
        );

        final rangeEnd = getEndOfToday();
        final showGaps = timeSpanDays < 180;

        return Scaffold(
          appBar: HabitsPageAppBar(),
          backgroundColor: styleConfig().negspace,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 10,
                top: 5,
              ),
              child: Column(
                children: [
                  Center(
                    child: TimeSpanSegmentedControl(
                      timeSpanDays: timeSpanDays,
                      onValueChanged: cubit.setTimeSpan,
                    ),
                  ),
                  if (state.openNow.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        localizations.habitsOpenHeader,
                        style: chartTitleStyle(),
                      ),
                    ),
                  const SizedBox(height: 15),
                  ...state.openNow.map((habitDefinition) {
                    return HabitChartLine(
                      habitDefinition: habitDefinition,
                      rangeStart: rangeStart,
                      rangeEnd: rangeEnd,
                      showGaps: showGaps,
                    );
                  }),
                  if (state.completed.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        localizations.habitsCompletedHeader,
                        style: chartTitleStyle(),
                      ),
                    ),
                  const SizedBox(height: 15),
                  ...state.completed.map((habitDefinition) {
                    return HabitChartLine(
                      habitDefinition: habitDefinition,
                      rangeStart: rangeStart,
                      rangeEnd: rangeEnd,
                      showGaps: showGaps,
                    );
                  }),
                  if (state.pendingLater.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        localizations.habitsPendingLaterHeader,
                        style: chartTitleStyle(),
                      ),
                    ),
                  const SizedBox(height: 15),
                  ...state.pendingLater.map((habitDefinition) {
                    return HabitChartLine(
                      habitDefinition: habitDefinition,
                      rangeStart: rangeStart,
                      rangeEnd: rangeEnd,
                      showGaps: showGaps,
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      localizations.habitsShortStreaksHeader,
                      style: chartTitleStyle(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  ...state.habitDefinitions.map((habitDefinition) {
                    return HabitChartLine(
                      habitDefinition: habitDefinition,
                      rangeStart: rangeStart,
                      rangeEnd: rangeEnd,
                      streakDuration: 2,
                      showGaps: showGaps,
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      localizations.habitsLongerStreaksHeader,
                      style: chartTitleStyle(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  ...state.habitDefinitions.map((habitDefinition) {
                    return HabitChartLine(
                      habitDefinition: habitDefinition,
                      rangeStart: rangeStart,
                      rangeEnd: rangeEnd,
                      streakDuration: 6,
                      showGaps: days < 180,
                    );
                  }),
                  const HabitStreaksCounter(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class HabitsPageAppBar extends StatelessWidget with PreferredSizeWidget {
  HabitsPageAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 110);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final title = localizations.settingsHabitsTitle;

    return Column(
      children: [
        TitleAppBar(title: title, showBackButton: false),
        //const HabitsPageProgressBar(),
        const HabitCompletionRateChart(),
      ],
    );
  }
}

class HabitStreaksCounter extends StatelessWidget {
  const HabitStreaksCounter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HabitsCubit, HabitsState>(
      builder: (context, HabitsState state) {
        final total = state.habitDefinitions.length;
        final todayCount = state.completedToday.length;

        return Column(
          children: [
            Text(
              '$total habits total',
              style: chartTitleStyle(),
            ),
            Text(
              '$todayCount completed today',
              style: chartTitleStyle(),
            ),
            Text(
              '${state.shortStreakCount} short streaks of 3+ days',
              style: chartTitleStyle(),
            ),
            Text(
              '${state.longStreakCount} long streaks of 7+ days',
              style: chartTitleStyle(),
            ),
          ],
        );
      },
    );
  }
}
