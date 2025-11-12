import 'package:flutter/material.dart';
// Don't import main.dart to avoid circular import; we'll navigate by named route '/main'.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to Car')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text('Find your vehicle, nearest service centers, and connect remotely (simulated)', style: TextStyle(fontSize: 16, color: scheme.onSurface)),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // navigate to main shell via named route to avoid circular imports
                Navigator.of(context).pushReplacementNamed('/main');
              },
              child: const Text('Get started'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/main');
              },
              child: const Text('Skip'),
            )
          ],
        ),
      ),
    );
  }
}
