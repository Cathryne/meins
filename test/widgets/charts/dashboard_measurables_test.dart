import 'package:beamer/beamer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotti/classes/entity_definitions.dart';
import 'package:lotti/classes/journal_entities.dart';
import 'package:lotti/database/database.dart';
import 'package:lotti/get_it.dart';
import 'package:lotti/services/nav_service.dart';
import 'package:lotti/sync/secure_storage.dart';
import 'package:lotti/themes/themes_service.dart';
import 'package:lotti/widgets/charts/dashboard_measurables_chart.dart';
import 'package:mocktail/mocktail.dart';

import '../../journal_test_data/test_data.dart';
import '../../mocks/mocks.dart';
import '../../widget_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var mockJournalDb = MockJournalDb();
  final mockSecureStorage = MockSecureStorage();

  group('DashboardMeasurablesChart Widget Tests - ', () {
    setUp(() {
      mockJournalDb = MockJournalDb();

      getIt
        ..registerSingleton<ThemesService>(ThemesService(watch: false))
        ..registerSingleton<JournalDb>(mockJournalDb)
        ..registerSingleton<NavService>(MockNavService())
        ..registerSingleton<SecureStorage>(mockSecureStorage);

      when(() => mockJournalDb.getConfigFlag(any()))
          .thenAnswer((_) async => false);
    });
    tearDown(getIt.reset);

    testWidgets(
        'chart is rendered with measurement entry, aggregation sum by day',
        (tester) async {
      when(
        () => mockJournalDb.watchMeasurementsByType(
          rangeStart: any(named: 'rangeStart'),
          rangeEnd: any(named: 'rangeEnd'),
          type: measurableChocolate.id,
        ),
      ).thenAnswer(
        (_) => Stream<List<JournalEntity>>.fromIterable([
          [testMeasurementChocolateEntry]
        ]),
      );

      when(
        () => mockJournalDb.watchMeasurableDataTypeById(
          measurableChocolate.id,
        ),
      ).thenAnswer(
        (_) => Stream<MeasurableDataType>.fromIterable([
          measurableChocolate,
        ]),
      );

      await tester.pumpWidget(
        makeTestableWidgetWithScaffold(
          DashboardMeasurablesChart(
            dashboardId: 'dashboardId',
            rangeStart: DateTime(2022),
            rangeEnd: DateTime(2023),
            measurableDataTypeId: measurableChocolate.id,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // measurement entry displays expected date
      expect(
        find.text('${measurableChocolate.displayName} [dailySum]'),
        findsOneWidget,
      );
    });

    testWidgets('chart is rendered with measurement entry, aggregation none',
        (tester) async {
      when(
        () => mockJournalDb.watchMeasurementsByType(
          rangeStart: any(named: 'rangeStart'),
          rangeEnd: any(named: 'rangeEnd'),
          type: measurableCoverage.id,
        ),
      ).thenAnswer(
        (_) => Stream<List<JournalEntity>>.fromIterable([
          [testMeasuredCoverageEntry]
        ]),
      );

      when(
        () => mockJournalDb.watchMeasurableDataTypeById(
          measurableCoverage.id,
        ),
      ).thenAnswer(
        (_) => Stream<MeasurableDataType>.fromIterable([
          measurableCoverage,
        ]),
      );

      await tester.pumpWidget(
        makeTestableWidgetWithScaffold(
          DashboardMeasurablesChart(
            dashboardId: 'dashboardId',
            rangeStart: DateTime(2022),
            rangeEnd: DateTime(2023),
            measurableDataTypeId: measurableCoverage.id,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // measurement entry displays expected date
      expect(
        find.text(measurableCoverage.displayName),
        findsOneWidget,
      );
    });

    testWidgets(
        'chart is rendered with measurement entry, aggregation daily max',
        (tester) async {
      when(
        () => mockJournalDb.watchMeasurementsByType(
          rangeStart: any(named: 'rangeStart'),
          rangeEnd: any(named: 'rangeEnd'),
          type: measurablePullUps.id,
        ),
      ).thenAnswer(
        (_) => Stream<List<JournalEntity>>.fromIterable([
          [testMeasuredPullUpsEntry]
        ]),
      );

      when(
        () => mockJournalDb.watchMeasurableDataTypeById(
          measurablePullUps.id,
        ),
      ).thenAnswer(
        (_) => Stream<MeasurableDataType>.fromIterable([
          measurablePullUps,
        ]),
      );

      final delegate = BeamerDelegate(
        locationBuilder: RoutesLocationBuilder(
          routes: {
            '/': (context, state, data) => Container(),
          },
        ),
      );

      await tester.pumpWidget(
        makeTestableWidgetWithScaffold(
          BeamerProvider(
            routerDelegate: delegate,
            child: DashboardMeasurablesChart(
              dashboardId: 'dashboardId',
              rangeStart: DateTime(2022),
              rangeEnd: DateTime(2023),
              measurableDataTypeId: measurablePullUps.id,
              enableCreate: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // measurement entry displays expected date
      expect(
        find.text('${measurablePullUps.displayName} [dailyMax]'),
        findsOneWidget,
      );

      final chartTappableFinder = find.byType(GestureDetector).first;
      await tester.tap(chartTappableFinder);
      await tester.pump(kDoubleTapMinTime);
      await tester.tap(chartTappableFinder);

      await tester.pumpAndSettle();
    });
  });
}
