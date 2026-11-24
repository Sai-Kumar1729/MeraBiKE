import 'package:material_ui/material_ui.dart';

import '../app/app_state.dart';

/// One screen that teaches the only habit the app needs: the anchor.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, this.reviewing = false});

  /// Opened again from Bike setup, rather than on first launch.
  final bool reviewing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget point(IconData icon, String title, String body) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title, style: theme.textTheme.titleMedium),
      subtitle: Text(body),
    );
    return Scaffold(
      appBar: reviewing ? AppBar(title: const Text('How anchors work')) : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (!reviewing) ...[
              Text('MeraBiKE', style: theme.textTheme.displaySmall),
              const SizedBox(height: 8),
              const Text(
                'Real mileage from the ₹100–₹500 fills you already do. No '
                'full-tank tests.',
              ),
              const SizedBox(height: 24),
            ],
            point(
              Icons.flag,
              'The anchor',
              'The moment the second-last bar disappears (1 bar left), with '
                  'the bike upright. Fill right then, and log it with the '
                  'odometer and "1 bar".',
            ),
            point(
              Icons.local_gas_station,
              'Every other fill',
              'Just the amount. Odometer and gauge are optional.',
            ),
            point(
              Icons.timeline,
              'The result',
              'At your next anchor the tank is back at the same level, so the '
                  'fuel you added equals the fuel you used. More litres in a '
                  'chain means more confidence: under 4 L Low, 4–8 L Medium, '
                  'over 8 L High.',
            ),
            point(
              Icons.build,
              'Services',
              'Log them. Results before and after a service are kept apart.',
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                if (reviewing) {
                  Navigator.pop(context);
                } else {
                  await AppScope.of(context).finishOnboarding();
                }
              },
              child: Text(reviewing ? 'Got it' : 'Start'),
            ),
          ],
        ),
      ),
    );
  }
}
