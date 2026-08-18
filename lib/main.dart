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
    // Premium Midnight Blue / Modern Dark Electric palette
    const primarySeed = Color(0xFF2563EB); // Royal Electric Blue

    final lightScheme = ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: Brightness.light,
      surface: const Color(0xFFF8FAFC), // Slate 50 ultra clean background
      onSurface: const Color(0xFF0F172A),
    );

    final darkScheme = ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: Brightness.dark,
      surface: const Color(0xFF0F172A), // Deep Slate dark background
      onSurface: const Color(0xFFF8FAFC),
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
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            fontFamily: 'Roboto',
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFFF8FAFC),
              foregroundColor: lightScheme.onSurface,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: lightScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            navigationBarTheme: NavigationBarThemeData(
              height: 70,
              elevation: 0,
              backgroundColor: Colors.white,
              indicatorColor: primarySeed.withValues(alpha: 0.15),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: primarySeed,
                  );
                }
                return const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                );
              }),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: darkScheme,
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF0B0F19),
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFF0B0F19),
              foregroundColor: darkScheme.onSurface,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: darkScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Color(0xFF334155), width: 1),
              ),
            ),
            navigationBarTheme: NavigationBarThemeData(
              height: 70,
              elevation: 0,
              backgroundColor: const Color(0xFF0F172A),
              indicatorColor: const Color(0xFF3B82F6).withValues(alpha: 0.25),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF60A5FA),
                  );
                }
                return const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                );
              }),
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
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: NavigationBar(
              selectedIndex: selected,
              onDestinationSelected: (i) =>
                  AppState.instance.selectedTab.value = i,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.directions_car_outlined, size: 24),
                  selectedIcon: Icon(
                    Icons.directions_car_filled,
                    size: 24,
                    color: Color(0xFF2563EB),
                  ),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.map_outlined, size: 24),
                  selectedIcon: Icon(
                    Icons.map_rounded,
                    size: 24,
                    color: Color(0xFF2563EB),
                  ),
                  label: 'Live Map',
                ),
                NavigationDestination(
                  icon: Icon(Icons.build_outlined, size: 24),
                  selectedIcon: Icon(
                    Icons.build_rounded,
                    size: 24,
                    color: Color(0xFF2563EB),
                  ),
                  label: 'Services',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
