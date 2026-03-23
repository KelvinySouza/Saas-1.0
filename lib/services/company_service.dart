// ============================================================
//  company_service.dart — Serviço de Empresa
//  CRUD de configurações e dados da empresa
// ============================================================

import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyModel {
  final String id;
  final String name;
  final String slug;
  final String? logo;
  final String? website;
  final Map<String, dynamic>? config;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CompanyModel({
    required this.id,
    required this.name,
    required this.slug,
    this.logo,
    this.website,
    this.config,
    required this.createdAt,
    this.updatedAt,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      logo: json['logo'] as String?,
      website: json['website'] as String?,
      config: json['config'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at'] as String)
        : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'slug': slug,
    'logo': logo,
    'website': website,
    'config': config,
  };
}

class CompanyService {
  final _supabase = Supabase.instance.client;

  // Recupera dados da empresa
  Future<CompanyModel?> getCompany(String companyId) async {
    try {
      final res = await _supabase
          .from('companies')
          .select()
          .eq('id', companyId)
          .maybeSingle();

      return res != null ? CompanyModel.fromJson(res) : null;
    } catch (e) {
      print('Erro ao buscar empresa: $e');
      return null;
    }
  }

  // Atualiza configurações da empresa
  Future<bool> updateCompany(String companyId, {
    String? name,
    String? website,
    String? logo,
    Map<String, dynamic>? config,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (website != null) updates['website'] = website;
      if (logo != null) updates['logo'] = logo;
      if (config != null) updates['config'] = config;

      await _supabase
          .from('companies')
          .update(updates)
          .eq('id', companyId);

      return true;
    } catch (e) {
      print('Erro ao atualizar empresa: $e');
      return false;
    }
  }

  // Completa onboarding da empresa
  Future<bool> completeOnboarding(String companyId) async {
    try {
      final config = {
        'onboarding_completed_at': DateTime.now().toIso8601String(),
        'onboarding_completed': true,
      };

      return await updateCompany(companyId, config: config);
    } catch (e) {
      print('Erro ao completar onboarding: $e');
      return false;
    }
  }
}
