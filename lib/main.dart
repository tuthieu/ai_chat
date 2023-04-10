import 'package:ai_chat/global_key.dart';
import 'package:ai_chat/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => _MyAppState();

  static void setLocale(BuildContext context, Locale locale) {
    _MyAppState state = context.findAncestorStateOfType<_MyAppState>()!;
    state.setLocale(locale);
  }
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _locale,
      home: Builder(
        builder: (context) =>
            HomePage(title: AppLocalizations.of(context)!.appTitle),
      ),
      navigatorKey: navigatorKey,
    );
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }
}
