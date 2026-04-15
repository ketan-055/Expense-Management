import 'package:flutter/material.dart';

import 'ui/screens/splash_screen.dart';
import 'ui/theme/app_theme.dart';

class KharchaPaniApp extends StatelessWidget {
  const KharchaPaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppTheme.title,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}
