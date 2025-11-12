import 'dart:async';

import 'package:flutter/material.dart';
import 'onboarding_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 800), () {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const OnboardingPage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.primary,
      body: Center(
        child: Text('Car', style: TextStyle(fontSize: 36, color: scheme.onPrimary, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
