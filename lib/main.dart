import 'package:flutter/material.dart';
import 'map_page.dart';
import 'home_page.dart';
import 'centers_page.dart';
// splash_page.dart kept in project but not used when starting directly at Home
import 'app_state.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final seed = Colors.deepPurple;
    final scheme = ColorScheme.fromSeed(seedColor: seed);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Car Drive',
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: scheme.secondary,
            foregroundColor: scheme.onSecondary,
          ),
        ),
      ),
      routes: {'/main': (_) => const MainShell()},
      // start directly at main shell (Home tab) per user request
      home: const MainShell(),
    );
  }
}

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = [const HomePage(), const MapPage(), const CentersPage()];
    return ValueListenableBuilder<int>(
      valueListenable: AppState.instance.selectedTab,
      builder: (context, selected, _) {
        return Scaffold(
          body: pages[selected],
          bottomNavigationBar: NavigationBar(
            selectedIndex: selected,
            onDestinationSelected: (i) =>
                AppState.instance.selectedTab.value = i,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.dashboard), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
              NavigationDestination(
                icon: Icon(Icons.room_service),
                label: 'Centers',
              ),
            ],
          ),
        );
      },
    );
  }
}
