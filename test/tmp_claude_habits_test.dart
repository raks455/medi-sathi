// Temporary checks for the water and fasting trackers and the text size.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:medisathi/core/di/injection_container.dart';
import 'package:medisathi/core/l10n/l10n.dart';
import 'package:medisathi/core/theme/app_theme.dart';
import 'package:medisathi/core/theme/text_size_cubit.dart';
import 'package:medisathi/features/auth/data/datasources/auth_token_storage.dart';
import 'package:medisathi/features/auth/data/models/auth_session_model.dart';
import 'package:medisathi/features/habits/habit_pages.dart';
import 'package:medisathi/features/habits/habits.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> loadFonts() async {
  Future<ByteData> file(String path) async =>
      ByteData.view(File(path).readAsBytesSync().buffer);
  final flutterRoot = Platform.environment['FLUTTER_ROOT']!;
  await (FontLoader('Latin')..addFont(file(r'C:\Windows\Fonts\segoeui.ttf')))
      .load();
  await (FontLoader('Deva')..addFont(file(r'C:\Windows\Fonts\Nirmala.ttc')))
      .load();
  await (FontLoader('MaterialIcons')
        ..addFont(file(
            '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')))
      .load();
}

Future<HabitStore> store(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  final session = AuthTokenStorageImpl(prefs);
  await session.saveSession(AuthSessionModel(
      accessToken: 'a',
      refreshToken: 'r',
      userId: userId,
      email: 'e@x.y',
      fullName: 'N'));
  return HabitStore(prefs, session);
}

Widget app(Widget home, AppLang lang, AppTextSize size) => MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: lang.locale,
      supportedLocales: [for (final l in AppLang.values) l.locale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light.copyWith(
        textTheme: AppTheme.light.textTheme
            .apply(fontFamily: 'Latin', fontFamilyFallback: const ['Deva']),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: size.scaler(context)),
        child: DefaultTextStyle.merge(
          style: const TextStyle(
              fontFamily: 'Latin', fontFamilyFallback: ['Deva']),
          child: child!,
        ),
      ),
      home: home,
    );

void main() {
  setUpAll(() => initializeDateFormatting());
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('water cubit', () async {
    final s = await store('u1');
    final water = WaterCubit(s);
    await water.load();
    expect(water.state.todayMl, 0);
    await water.drink();
    await water.drink(500);
    expect(water.state.todayMl, 750);
    expect(water.state.glassesLeft, 5);
    await water.undo();
    expect(water.state.todayMl, 250);
    await water.setGoal(1500);
    await water.setGlass(300);
    // Survives a restart, and is separate per account.
    final again = WaterCubit(s);
    await again.load();
    expect(again.state.todayMl, 250);
    expect(again.state.goalMl, 1500);
    expect(again.state.glassMl, 300);
    expect(again.state.todayAdds, [250]);
    final other = WaterCubit(await store('u2'));
    await other.load();
    expect(other.state.todayMl, 0);
    for (var i = 0; i < 6; i++) {
      await again.drink();
    }
    expect(again.state.goalReached, true);
    expect(again.state.glassesLeft, 0);
    expect(formatWater(1250), '1.25 L');
    expect(formatWater(2000), '2 L');
    expect(formatWater(250), '250 ml');
  });

  test('fasting cubit', () async {
    final s = await store('u1');
    final fasting = FastingCubit(s);
    await fasting.load();
    expect(fasting.state.isFasting, false);
    await fasting.setGoal(16);
    final began = DateTime.now().subtract(const Duration(hours: 17));
    await fasting.start(began);
    expect(fasting.state.reachedGoal(DateTime.now()), true);
    expect(fasting.state.progress(DateTime.now()), 1);
    final again = FastingCubit(s);
    await again.load();
    expect(again.state.startedAt, began);
    expect(again.state.goalHours, 16);
    await again.end();
    expect(again.state.isFasting, false);
    expect(again.state.history.single.reachedGoal, true);
    // A fast started by mistake is not kept; a future start becomes "now".
    await again.start(DateTime.now().add(const Duration(hours: 3)));
    expect(again.state.elapsed(DateTime.now()).inMinutes, 0);
    await again.end();
    expect(again.state.history.length, 1);
    await again.deleteFast(again.state.history.single);
    expect(again.state.history, isEmpty);
  });

  for (final lang in AppLang.values) {
    for (final size in [AppTextSize.medium, AppTextSize.extraLarge]) {
      testWidgets('tracker pages ${lang.code} ${size.name}', (tester) async {
        await tester.runAsync(loadFonts);
        tester.view.physicalSize = const Size(360, 1500);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        L10n.current = lang;
        Intl.defaultLocale = lang.code;
        addTearDown(() {
          L10n.current = AppLang.en;
          Intl.defaultLocale = 'en';
        });
        final s = (await tester.runAsync(() => store('u1')))!;
        final water = WaterCubit(s);
        final fasting = FastingCubit(s);
        await tester.runAsync(() async {
          await water.load();
          await water.drink(1250);
          await fasting.load();
          await fasting
              .start(DateTime.now().subtract(const Duration(hours: 9)));
        });

        await tester.pumpWidget(app(
            BlocProvider.value(value: water, child: const WaterTrackerPage()),
            lang,
            size));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('1.25 L'), findsOneWidget);
        await expectLater(
            find.byType(Scaffold),
            matchesGoldenFile(
                'goldens/water_${lang.code}_${size.name}.png'));
        // One tap on the big button adds a glass.
        await tester.tap(find.byIcon(Icons.local_drink_rounded));
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump();
        expect(water.state.todayMl, 1500);

        // The profile repository is not registered here: no diabetes note.
        expect(sl.isRegistered<Object>(instanceName: 'x'), false);
        await tester.pumpWidget(app(
            BlocProvider.value(
                value: fasting, child: const FastingTrackerPage()),
            lang,
            size));
        await tester.pump();
        expect(tester.takeException(), isNull);
        await expectLater(
            find.byType(Scaffold),
            matchesGoldenFile(
                'goldens/fasting_${lang.code}_${size.name}.png'));
        await tester.pumpWidget(const SizedBox()); // stop the page's timer
      });
    }
  }

  testWidgets('text size selector', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final cubit = TextSizeCubit(prefs);
    await tester.pumpWidget(BlocProvider.value(
      value: cubit,
      child: BlocBuilder<TextSizeCubit, AppTextSize>(
        builder: (context, size) => MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: size.scaler(context)),
            child: child!,
          ),
          home: const Scaffold(
              body: Column(children: [TextSizeSelector(), Text('Hello')])),
        ),
      ),
    ));
    double height() => tester.getSize(find.text('Hello')).height;
    final before = height();
    await tester.tap(find.text('A').last);
    await tester.pumpAndSettle();
    expect(cubit.state, AppTextSize.extraLarge);
    expect(height(), greaterThan(before * 1.3));
    expect(prefs.getString('text_size'), 'extraLarge');
    expect(TextSizeCubit(prefs).state, AppTextSize.extraLarge);
  });
}
