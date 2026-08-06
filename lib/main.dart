import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'ui/theme/falcon_theme.dart';
import 'ui/screens/home_screen.dart';
import 'ui/window/falcon_window.dart';

void main() {
  runApp(
    const ProviderScope(
      child: FalconApp(),
    ),
  );

  doWhenWindowReady(() {
    final win = appWindow;
    const initialSize = Size(1280, 720);
    win.minSize = const Size(800, 600);
    win.size = initialSize;
    win.alignment = Alignment.center;
    win.title = "Falcon AI";
    win.show();
  });
}

class FalconApp extends StatelessWidget {
  const FalconApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Falcon AI',
      debugShowCheckedModeBanner: false,
      theme: FalconTheme.darkTheme,
      home: const FalconWindow(child: HomeScreen()),
    );
  }
}
