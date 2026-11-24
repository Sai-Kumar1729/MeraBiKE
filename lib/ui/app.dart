import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app/app_state.dart';
import '../data/android_bridge.dart';
import 'bike_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'insights_screen.dart';
import 'onboarding_screen.dart';
import 'refuel_form_screen.dart';

class MeraBikeApp extends StatelessWidget {
  const MeraBikeApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) => AppScope(
    state: state,
    child: MaterialApp(
      title: 'MeraBiKE',
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const _Root(),
    ),
  );
}

ThemeData _theme(Brightness brightness) => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF00796B),
    brightness: brightness,
  ),
);

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (!state.onboardingDone) return const OnboardingScreen();
    if (state.bike == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Set up your bike')),
        body: const BikeScreen(),
      );
    }
    return const HomeShell();
  }
}

/// Home, History, Insights and Bike tabs, with "Log refuel" one tap away (or
/// one long-press on the app icon).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _bikeTab = 3;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _listenForShortcut());
  }

  Future<void> _listenForShortcut() async {
    final bridge = AppScope.read(context).bridge;
    bridge.onShortcut((action) {
      if (action == AndroidBridge.logRefuelAction) _logRefuel();
    });
    try {
      if (await bridge.takeLaunchAction() == AndroidBridge.logRefuelAction) {
        _logRefuel();
      }
    } on MissingPluginException {
      // Not running on Android (tests): no shortcut.
    }
  }

  void _logRefuel() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const RefuelFormScreen()),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('MeraBiKE')),
    body: IndexedStack(
      index: _tab,
      children: [
        HomeScreen(
          onOpenHistory: () => setState(() => _tab = 1),
          onOpenBike: () => setState(() => _tab = _bikeTab),
        ),
        const HistoryScreen(),
        const InsightsScreen(),
        const BikeScreen(),
      ],
    ),
    floatingActionButton: _tab == _bikeTab
        ? null
        : FloatingActionButton.extended(
            onPressed: _logRefuel,
            icon: const Icon(Icons.local_gas_station),
            label: const Text('Log refuel'),
          ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (tab) => setState(() => _tab = tab),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.speed), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        NavigationDestination(icon: Icon(Icons.insights), label: 'Insights'),
        NavigationDestination(icon: Icon(Icons.two_wheeler), label: 'Bike'),
      ],
    ),
  );
}
