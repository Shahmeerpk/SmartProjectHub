import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'screens/main_shell.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService(prefs)),
        ChangeNotifierProvider<AuthService>(
          create: (ctx) => AuthService(ctx.read<ApiService>()),
        ),
      ],
      child: const SmartAcademicHubApp(),
    ),
  );
}

class SmartAcademicHubApp extends StatelessWidget {
  const SmartAcademicHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Academic Project Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Consumer<AuthService>(
        builder: (context, auth, _) {
          if (auth.isLoggedIn) return const MainShell();
          return const LoginScreen();
        },
      ),
    );
  }
}
