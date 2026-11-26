import 'package:flutter/material.dart';

import 'core/store.dart';
import 'core/theme.dart';
import 'ui/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await AppStore.load();
  runApp(OneReaderApp(store: store));
}

class OneReaderApp extends StatelessWidget {
  const OneReaderApp({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => MaterialApp(
        title: 'One Reader（练手版）',
        debugShowCheckedModeBanner: false,
        themeMode: store.themeMode,
        theme: buildAppTheme(Brightness.light),
        darkTheme: buildAppTheme(Brightness.dark),
        home: HomeShell(store: store),
      ),
    );
  }
}
