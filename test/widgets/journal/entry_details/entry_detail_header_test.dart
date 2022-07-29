import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotti/blocs/journal/entry_cubit.dart';
import 'package:lotti/blocs/journal/entry_state.dart';
import 'package:lotti/database/database.dart';
import 'package:lotti/get_it.dart';
import 'package:lotti/routes/router.gr.dart';
import 'package:lotti/services/tags_service.dart';
import 'package:lotti/themes/themes_service.dart';
import 'package:lotti/widgets/journal/entry_details/entry_detail_header.dart';
import 'package:lotti/widgets/journal/entry_tools.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:mocktail/mocktail.dart';

import '../../../journal_test_data/test_data.dart';
import '../../../mocks/mocks.dart';
import '../../../widget_test_utils.dart';

class MockEntryCubit extends MockBloc<EntryCubit, EntryState>
    implements EntryCubit {}

void main() {
  group('EntryDetailHeader', () {
    final entryCubit = MockEntryCubit();
    final mockAppRouter = MockAppRouter();

    setUpAll(() {
      getIt
        ..registerSingleton<ThemesService>(ThemesService(watch: false))
        ..registerSingleton<JournalDb>(JournalDb(inMemoryDatabase: true))
        ..registerSingleton<TagsService>(TagsService())
        ..registerSingleton<AppRouter>(mockAppRouter);

      when(mockAppRouter.pop).thenAnswer((_) async => true);

      when(() => entryCubit.state).thenAnswer(
        (_) => EntryState.dirty(
          entryId: testTextEntry.meta.id,
          entry: testTextEntry,
        ),
      );
    });

    testWidgets('tap star icon', (WidgetTester tester) async {
      when(entryCubit.toggleStarred).thenAnswer((_) async => true);

      await tester.pumpWidget(
        makeTestableWidgetWithScaffold(
          BlocProvider<EntryCubit>.value(
            value: entryCubit,
            child: EntryDetailHeader(itemId: testTextEntry.meta.id),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final starIconFinder = find.byIcon(MdiIcons.star);
      expect(starIconFinder, findsOneWidget);

      await tester.tap(starIconFinder);
      await tester.pumpAndSettle();

      verify(entryCubit.toggleStarred).called(1);
    });

    testWidgets('tap flagged icon', (WidgetTester tester) async {
      when(entryCubit.toggleFlagged).thenAnswer((_) async => true);

      await tester.pumpWidget(
        makeTestableWidgetWithScaffold(
          BlocProvider<EntryCubit>.value(
            value: entryCubit,
            child: EntryDetailHeader(itemId: testTextEntry.meta.id),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final starIconFinder = find.byIcon(MdiIcons.flag);
      expect(starIconFinder, findsOneWidget);

      await tester.tap(starIconFinder);
      await tester.pumpAndSettle();

      verify(entryCubit.toggleFlagged).called(1);
    });

    testWidgets('tap private icon', (WidgetTester tester) async {
      when(entryCubit.togglePrivate).thenAnswer((_) async => true);

      await tester.pumpWidget(
        makeTestableWidgetWithScaffold(
          BlocProvider<EntryCubit>.value(
            value: entryCubit,
            child: EntryDetailHeader(itemId: testTextEntry.meta.id),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final starIconFinder = find.byIcon(MdiIcons.security);
      expect(starIconFinder, findsOneWidget);

      await tester.tap(starIconFinder);
      await tester.pumpAndSettle();

      verify(entryCubit.togglePrivate).called(1);
    });

    testWidgets('tap entry date', (WidgetTester tester) async {
      when(entryCubit.togglePrivate).thenAnswer((_) async => true);

      DateTime? modifiedDateTo;

      when(
        () => entryCubit.updateFromTo(
          dateFrom: testTextEntry.meta.dateFrom,
          dateTo: any(named: 'dateTo'),
        ),
      ).thenAnswer((Invocation i) async {
        const dateTo = Symbol('dateTo');
        modifiedDateTo = i.namedArguments[dateTo] as DateTime;
        return true;
      });

      await tester.pumpWidget(
        makeTestableWidgetWithScaffold(
          BlocProvider<EntryCubit>.value(
            value: entryCubit,
            child: EntryDetailHeader(itemId: testTextEntry.meta.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final entryDateFromFinder =
          find.text(df.format(testTextEntry.meta.dateFrom));
      expect(entryDateFromFinder, findsOneWidget);

      await tester.tap(entryDateFromFinder);
      await tester.pumpAndSettle();

      // entry date displayed in modal, too
      expect(entryDateFromFinder, findsNWidgets(2));

      // open and close dateTo selection
      final entryDateToFinder = find.text(df.format(testTextEntry.meta.dateTo));
      expect(entryDateToFinder, findsOneWidget);

      await tester.tap(entryDateToFinder);
      await tester.pumpAndSettle();

      final doneButtonFinder = find.text('Done');
      expect(doneButtonFinder, findsOneWidget);

      await tester.tap(doneButtonFinder);
      await tester.pumpAndSettle();

      // open and close dateFrom selection
      await tester.tap(entryDateFromFinder.last);
      await tester.pumpAndSettle();

      expect(doneButtonFinder, findsOneWidget);

      await tester.tap(doneButtonFinder);
      await tester.pumpAndSettle();

      // set dateTo to now() and save
      final nowButtonFinder = find.text('now');
      expect(nowButtonFinder, findsOneWidget);

      await tester.tap(nowButtonFinder);
      await tester.pumpAndSettle();

      final saveButtonFinder = find.text('SAVE');
      expect(saveButtonFinder, findsOneWidget);

      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();

      verify(mockAppRouter.pop).called(1);

      // updateFromTo called with recent dateTo after tapping now()
      expect(modifiedDateTo?.difference(DateTime.now()).inSeconds, lessThan(2));
    });

    testWidgets('save button invisible when saved/clean',
        (WidgetTester tester) async {
      when(() => entryCubit.state).thenAnswer(
        (_) => EntryState.saved(
          entryId: testTextEntry.meta.id,
          entry: testTextEntry,
        ),
      );

      await tester.pumpWidget(
        makeTestableWidgetWithScaffold(
          BlocProvider<EntryCubit>.value(
            value: entryCubit,
            child: EntryDetailHeader(itemId: testTextEntry.meta.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final saveButtonFinder = find.text('SAVE');
      expect(saveButtonFinder, findsNothing);
    });

    testWidgets('save button tappable when unsaved/dirty',
        (WidgetTester tester) async {
      when(() => entryCubit.state).thenAnswer(
        (_) => EntryState.dirty(
          entryId: testTextEntry.meta.id,
          entry: testTextEntry,
        ),
      );

      when(entryCubit.save).thenAnswer((_) async => true);

      await tester.pumpWidget(
        makeTestableWidgetWithScaffold(
          BlocProvider<EntryCubit>.value(
            value: entryCubit,
            child: EntryDetailHeader(itemId: testTextEntry.meta.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final saveButtonFinder = find.text('Save');
      expect(saveButtonFinder, findsOneWidget);

      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();

      verify(entryCubit.save).called(1);
    });
  });
}
