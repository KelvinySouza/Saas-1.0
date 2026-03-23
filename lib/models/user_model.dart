// ============================================================
//  user_model.dart — Modelo de Usuário
// ============================================================

class UserModel {
  final String id;
  final String companyId;
  final String email;
  final String fullName;
  final String role; // 'admin', 'manager', 'user'
  final List<String> permissions; // ['read', 'write', 'delete', etc]
  final bool active;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.companyId,
    required this.email,
    required this.fullName,
    required this.role,
    required this.permissions,
    required this.active,
    required this.createdAt,
    this.updatedAt,
  });

  // Converte JSON do Supabase para UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String? ?? 'user',
      permissions: List<String>.from(json['permissions'] as List? ?? []),
      active: json['active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at'] as String)
        : null,
    );
  }

  // Converte UserModel para JSON para enviar ao Supabase
  Map<String, dynamic> toJson() => {
    'email': email,
    'full_name': fullName,
    'role': role,
    'permissions': permissions,
    'active': active,
  };

  // Cópia com mudanças
  UserModel copyWith({
    String? id,
    String? companyId,
    String? email,
    String? fullName,
    String? role,
    List<String>? permissions,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'UserModel(id: $id, email: $email, fullName: $fullName)';
}
