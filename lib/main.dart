import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/server_provider.dart';
import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ServerProvider()),
      ],
      child: const SshRemoteApp(),
    ),
  );
}

class SshRemoteApp extends StatelessWidget {
  const SshRemoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServerProvider>();

    return MaterialApp(
      title: 'SSH Remote',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: provider.themeMode,
      home: const DashboardScreen(),
    );
  }
}
