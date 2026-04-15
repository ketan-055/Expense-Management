import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import 'main_shell.dart';

/// Black splash with app title; navigates to the main shell after ~2.5s.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Duration _displayDuration = Duration(milliseconds: 2500);

  @override
  void initState() {
    super.initState();
    unawaited(_goToMain());
  }

  Future<void> _goToMain() async {
    await Future<void>.delayed(_displayDuration);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => const MainShell(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          AppConstants.appName,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
