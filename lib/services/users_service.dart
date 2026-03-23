// ============================================================
//  users_service.dart — Serviço de Gestão de Usuários
//  CRUD de usuários dentro de uma empresa
// ============================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UsersService {
  final _supabase = Supabase.instance.client;

  // Recupera todos os usuários da empresa
  Future<List<UserModel>> getAll({String? companyId}) async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return [];

      // Se não passou companyId, busca da metadata do usuário
      final finalCompanyId = companyId ?? 
          _supabase.auth.currentUser?.userMetadata?['company_id'] as String?;

      if (finalCompanyId == null) {
        print('Company ID não encontrado');
        return [];
      }

      final res = await _supabase
          .from('users')
          .select()
          .eq('company_id', finalCompanyId)
          .order('created_at', ascending: false);

      return (res as List)
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erro ao buscar usuários: $e');
      return [];
    }
  }

  // Recupera usuário por ID
  Future<UserModel?> getById(String userId) async {
    try {
      final res = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return res != null ? UserModel.fromJson(res) : null;
    } catch (e) {
      print('Erro ao buscar usuário: $e');
      return null;
    }
  }

  // Cria novo usuário
  Future<UserModel?> create(Map<String, dynamic> data) async {
    try {
      final companyId = 
          _supabase.auth.currentUser?.userMetadata?['company_id'] as String?;
      if (companyId == null) throw Exception('Company ID não encontrado');

      // Cria conta de autenticação
      final authRes = await _supabase.auth.admin.createUser(
        AdminUserAttributes(
          email: data['email'] as String,
          password: data['password'] as String? ?? 'TempPass123!@#',
          emailConfirm: true,
        ),
      );

      // Cria registro do usuário
      final userRes = await _supabase
          .from('users')
          .insert({
            'id': authRes.user.id,
            'company_id': companyId,
            'email': data['email'],
            'full_name': data['full_name'] ?? '',
            'role': data['role'] ?? 'user',
            'permissions': data['permissions'] ?? ['read'],
            'active': true,
          })
          .select()
          .single();

      return UserModel.fromJson(userRes);
    } catch (e) {
      print('Erro ao criar usuário: $e');
      return null;
    }
  }

  // Atualiza usuário
  Future<bool> update(String userId, Map<String, dynamic> data) async {
    try {
      await _supabase
          .from('users')
          .update(data)
          .eq('id', userId);

      return true;
    } catch (e) {
      print('Erro ao atualizar usuário: $e');
      return false;
    }
  }

  // Deleta usuário
  Future<bool> delete(String userId) async {
    try {
      // Remove da tabela users
      await _supabase
          .from('users')
          .delete()
          .eq('id', userId);

      // Remove conta de autenticação
      await _supabase.auth.admin.deleteUser(userId);

      return true;
    } catch (e) {
      print('Erro ao deletar usuário: $e');
      return false;
    }
  }

  // Busca por email
  Future<UserModel?> findByEmail(String email) async {
    try {
      final res = await _supabase
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();

      return res != null ? UserModel.fromJson(res) : null;
    } catch (e) {
      print('Erro ao buscar por email: $e');
      return null;
    }
  }

  // Atualiza permissões de um usuário
  Future<bool> updatePermissions(String userId, List<String> permissions) async {
    return update(userId, {'permissions': permissions});
  }

  // Ativa/desativa usuário
  Future<bool> toggleActive(String userId, bool active) async {
    return update(userId, {'active': active});
  }
}
