import 'package:chronomap_mobile/scalable/bloc_provider.dart';
import 'package:chronomap_mobile/scalable/timeline/timeline.dart';
import 'package:chronomap_mobile/tab.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'serverpod_client.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // 多言語化のためにインポート
import 'package:shared_preferences/shared_preferences.dart'; // 言語設定の保存・読み込みのためにインポート

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeServerpodClient();

  // splash画面を表示時間を調整するために、下の2行を追加します。
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState state = context.findAncestorStateOfType<_MyAppState>()!;
    state.setLocale(newLocale);
  }

  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  void setLocale(Locale newLocale) {
    setState(() {
      _locale = newLocale;
    });
  }

  void _loadSavedLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedLanguageCode = prefs.getString('languageCode');
    if (savedLanguageCode != null) {
      setState(() {
        _locale = Locale(savedLanguageCode);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      t: Timeline(Theme.of(context).platform),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ChronoMap for Mobile',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF2f4f4f),
          brightness: Brightness.light,
          textTheme: GoogleFonts.sawarabiMinchoTextTheme(),
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: const [Locale('en'), Locale('ja'), Locale('fr')],
        locale: _locale,
        home: const TabWidget(),
      ),
    );
  }
}