import 'package:material_ui/material_ui.dart';

import '../app/app_state.dart';
import 'bike_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
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

/// Home, History and Bike tabs, with "Log refuel" always one tap away.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('MeraBiKE')),
    body: IndexedStack(
      index: _tab,
      children: [
        HomeScreen(onOpenHistory: () => setState(() => _tab = 1)),
        const HistoryScreen(),
        const BikeScreen(),
      ],
    ),
    floatingActionButton: _tab == 2
        ? null
        : FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const RefuelFormScreen()),
            ),
            icon: const Icon(Icons.local_gas_station),
            label: const Text('Log refuel'),
          ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (tab) => setState(() => _tab = tab),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.speed), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        NavigationDestination(icon: Icon(Icons.two_wheeler), label: 'Bike'),
      ],
    ),
  );
}
