// ============================================================
//  auth_service.dart — Serviço de Autenticação
//  Integração com Supabase para login multi-tenant
// ============================================================

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthResult {
  final bool success;
  final String? userId;
  final String? companyId;
  final String? error;
  final bool onboardingPending;

  AuthResult({
    required this.success,
    this.userId,
    this.companyId,
    this.error,
    this.onboardingPending = false,
  });
}

class AuthService {
  final _supabase = Supabase.instance.client;

  // Faz login com slug da empresa, email e senha
  Future<AuthResult> login({
    required String slug,
    required String email,
    required String password,
  }) async {
    try {
      // 1. Recupera o company_id baseado no slug
      final companyRes = await _supabase
          .from('companies')
          .select('id')
          .eq('slug', slug)
          .maybeSingle();

      if (companyRes == null) {
        return AuthResult(
          success: false,
          error: 'Empresa não encontrada',
        );
      }

      final companyId = companyRes['id'] as String;

      // 2. Autentica com Supabase Auth
      final authRes = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authRes.user == null) {
        return AuthResult(
          success: false,
          error: 'Credenciais inválidas',
        );
      }

      final userId = authRes.user!.id;

      // 3. Verifica se o usuário completou onboarding
      final userRes = await _supabase
          .from('users')
          .select('onboarding_completed')
          .eq('id', userId)
          .eq('company_id', companyId)
          .maybeSingle();

      final onboardingPending = userRes == null || 
          !(userRes['onboarding_completed'] as bool? ?? false);

      return AuthResult(
        success: true,
        userId: userId,
        companyId: companyId,
        onboardingPending: onboardingPending,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Erro ao fazer login: ${e.toString()}',
      );
    }
  }

  // Registra nova empresa e usuário admin
  Future<AuthResult> signup({
    required String companyName,
    required String companySlug,
    required String adminEmail,
    required String adminName,
    required String password,
  }) async {
    try {
      // 1. Cria conta de autenticação
      final authRes = await _supabase.auth.signUpWithPassword(
        email: adminEmail,
        password: password,
      );

      if (authRes.user == null) {
        return AuthResult(
          success: false,
          error: 'Erro ao criar conta',
        );
      }

      final userId = authRes.user!.id;

      // 2. Cria empresa
      final companyRes = await _supabase
          .from('companies')
          .insert({
            'name': companyName,
            'slug': companySlug,
            'created_by': userId,
          })
          .select()
          .single();

      final companyId = companyRes['id'] as String;

      // 3. Cria usuário admin
      await _supabase.from('users').insert({
        'id': userId,
        'company_id': companyId,
        'email': adminEmail,
        'full_name': adminName,
        'role': 'admin',
        'permissions': ['read', 'write', 'delete', 'manage_users'],
        'active': true,
        'onboarding_completed': false,
      });

      return AuthResult(
        success: true,
        userId: userId,
        companyId: companyId,
        onboardingPending: true,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Erro ao registrar: ${e.toString()}',
      );
    }
  }

  // Faz logout
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // Recupera usuário autenticado
  User? getCurrentUser() => _supabase.auth.currentUser;

  // Verifica se está autenticado
  bool isAuthenticated() => _supabase.auth.currentUser != null;
}
