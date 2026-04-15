import 'package:flutter/material.dart';

import 'app.dart';
import 'services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.instance.init();
  runApp(const KharchaPaniApp());
}
