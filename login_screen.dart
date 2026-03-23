// ============================================================
//  login_screen.dart — Tela de Login
//  Suporta: slug da empresa + email + senha
// ============================================================

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/crm_button.dart';
import '../../widgets/crm_text_field.dart';
import '../onboarding/onboarding_screen.dart';
import '../dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  bool _obscurePass = true;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      final result = await _authService.login(
        slug: _slugCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      if (!mounted) return;

      if (result.onboardingPending) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      setState(() { _error = 'Email, senha ou empresa inválidos.'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _slugCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                // Logo / Brand
                const Icon(Icons.show_chart_rounded, size: 52, color: Color(0xFF185FA5)),
                const SizedBox(height: 12),
                const Text(
                  'VendaFlow',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF185FA5)),
                ),
                const SizedBox(height: 4),
                Text('Plataforma de Vendas',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                const SizedBox(height: 36),

                // Card de login
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Entrar na sua conta',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 22),

                        // Slug da empresa
                        CRMTextField(
                          controller: _slugCtrl,
                          label: 'ID da empresa',
                          hint: 'ex: techbrasil',
                          prefixIcon: Icons.business_outlined,
                          validator: (v) => v!.isEmpty ? 'Informe o ID da empresa' : null,
                        ),
                        const SizedBox(height: 14),

                        // Email
                        CRMTextField(
                          controller: _emailCtrl,
                          label: 'Email',
                          hint: 'seu@email.com',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v!.isEmpty ? 'Informe o email' : null,
                        ),
                        const SizedBox(height: 14),

                        // Senha
                        CRMTextField(
                          controller: _passCtrl,
                          label: 'Senha',
                          hint: '••••••••',
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscurePass,
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, size: 20),
                            onPressed: () => setState(() => _obscurePass = !_obscurePass),
                          ),
                          validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                        ),
                        const SizedBox(height: 8),

                        // Erro
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(_error!,
                              style: const TextStyle(color: Colors.red, fontSize: 13)),
                          ),

                        // Botão entrar
                        CRMButton(
                          label: 'Entrar',
                          onPressed: _login,
                          loading: _loading,
                          fullWidth: true,
                        ),
                        const SizedBox(height: 14),

                        // Esqueci senha
                        Center(
                          child: TextButton(
                            onPressed: () {},
                            child: const Text('Esqueci minha senha'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
