// ============================================================
//  main.dart — Ponto de entrada do app Flutter
//  CRM SaaS Multi-tenant | Flutter 3.x
// ============================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://SEU_PROJECT_ID.supabase.co',
    anonKey: 'SUA_ANON_KEY',
  );

  runApp(const CRMApp());
}

class CRMApp extends StatelessWidget {
  const CRMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VendaFlow CRM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF185FA5)),
        fontFamily: 'Inter',
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      home: const AppRouter(),
    );
  }
}

// Roteador principal — decide qual tela mostrar
class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthState>(
      future: _authService.getInitialState(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final state = snapshot.data;

        // Não logado → tela de login
        if (state == AuthState.unauthenticated) {
          return const LoginScreen();
        }

        // Logado mas onboarding não concluído → onboarding
        if (state == AuthState.onboardingPending) {
          return const OnboardingScreen();
        }

        // Tudo certo → dashboard CRM
        return const DashboardScreen();
      },
    );
  }
}

enum AuthState { unauthenticated, onboardingPending, authenticated }
