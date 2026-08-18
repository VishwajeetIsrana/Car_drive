import 'package:flutter/material.dart';
import 'map_page.dart';
import 'home_page.dart';
import 'centers_page.dart';
import 'app_state.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Colors.indigo;
    final lightScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppState.instance.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Car Drive',
          themeMode: themeMode,
          theme: ThemeData(
            colorScheme: lightScheme,
            useMaterial3: true,
            appBarTheme: AppBarTheme(
              backgroundColor: lightScheme.primary,
              foregroundColor: lightScheme.onPrimary,
              elevation: 0,
            ),
            cardTheme: CardThemeData(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: darkScheme,
            useMaterial3: true,
            appBarTheme: AppBarTheme(
              backgroundColor: darkScheme.surface,
              foregroundColor: darkScheme.onSurface,
              elevation: 0,
            ),
            cardTheme: CardThemeData(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          routes: {'/main': (_) => const MainShell()},
          home: const MainShell(),
        );
      },
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
              NavigationDestination(
                icon: Icon(Icons.directions_car_outlined),
                selectedIcon: Icon(Icons.directions_car),
                label: 'Vehicle',
              ),
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'Map',
              ),
              NavigationDestination(
                icon: Icon(Icons.build_outlined),
                selectedIcon: Icon(Icons.build),
                label: 'Service',
              ),
            ],
          ),
        );
      },
    );
  }
}
