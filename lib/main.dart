import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flutter_web_plugins/url_strategy.dart';
import 'backend/firebase/firebase_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'flutter_flow/nav/nav.dart';
import 'index.dart';
import 'services/app_prefs.dart';
import 'student/student_profile_provider.dart';

const List<Locale> kSupportedLocales = [Locale('ar'), Locale('en')];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();
  await EasyLocalization.ensureInitialized();

  await initFirebase();

  await FlutterFlowTheme.initialize();

  final appState = FFAppState(); // Initialize FFAppState
  await appState.initializePersistedState();

  // Boot directly in the student's saved language (AppPrefs is the single
  // source of truth — see its "App language" section) so there's no flash of
  // the wrong locale before easy_localization's own persisted value loads.
  final savedLanguage = await AppPrefs.getAppLanguage();

  runApp(
    EasyLocalization(
      supportedLocales: kSupportedLocales,
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      startLocale: Locale(savedLanguage),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => appState),
          ChangeNotifierProvider(create: (context) => StudentProfileProvider()),
        ],
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.path;
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();
  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
        FlutterFlowTheme.saveThemeMode(mode);
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'شادو',
      // From easy_localization: the Global*Localizations delegates plus its
      // own delegate that loads assets/translations/*.json for .tr().
      localizationsDelegates: context.localizationDelegates,
      // context.locale follows whatever the student picked in Settings
      // (persisted by easy_localization itself); MaterialApp/WidgetsApp then
      // derive the ambient Directionality from it automatically — RTL for
      // 'ar', LTR for 'en' — so screens no longer need a hardcoded
      // Directionality wrapper for this to work.
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: false,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: false,
      ),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}
