// ============================================================
//  users_screen.dart — Gestão de Logins / Usuários
//  Adicionar, editar, remover e definir permissões
//  Acessível após onboarding em Configurações
// ============================================================

import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/users_service.dart';
import '../../widgets/crm_button.dart';
import '../../widgets/crm_text_field.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _usersService = UsersService();
  List<UserModel> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    final users = await _usersService.getAll();
    setState(() { _users = users; _loading = false; });
  }

  void _openUserForm({UserModel? user}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => UserFormSheet(
        user: user,
        onSaved: (data) async {
          if (user == null) {
            await _usersService.create(data);
          } else {
            await _usersService.update(user.id, data);
          }
          await _loadUsers();
        },
      ),
    );
  }

  Future<void> _toggleActive(UserModel user) async {
    await _usersService.setActive(user.id, !user.isActive);
    await _loadUsers();
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover usuário'),
        content: Text('Deseja remover ${user.name}? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _usersService.delete(user.id);
      await _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Usuários e Logins'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CRMButton(
              label: '+ Novo usuário',
              onPressed: () => _openUserForm(),
              small: true,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Resumo
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _statCard('Total', '${_users.length}', Colors.blue),
                      const SizedBox(width: 12),
                      _statCard('Ativos', '${_users.where((u) => u.isActive).length}', Colors.green),
                      const SizedBox(width: 12),
                      _statCard('Inativos', '${_users.where((u) => !u.isActive).length}', Colors.orange),
                    ],
                  ),
                ),

                // Lista de usuários
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _userCard(_users[i]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _userCard(UserModel user) {
    final roleColors = {
      'super_admin': Colors.purple,
      'admin': Colors.blue,
      'supervisor': Colors.teal,
      'seller': Colors.grey.shade700,
    };
    final roleLabels = {
      'super_admin': 'Super Admin',
      'admin': 'Admin',
      'supervisor': 'Supervisor',
      'seller': 'Vendedor',
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: roleColors[user.role]?.withOpacity(0.15),
            child: Text(
              user.name.substring(0, 2).toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: roleColors[user.role],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColors[user.role]?.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(roleLabels[user.role] ?? user.role,
                        style: TextStyle(fontSize: 11, color: roleColors[user.role], fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(user.email, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),

          // Status toggle
          Switch(
            value: user.isActive,
            onChanged: (_) => _toggleActive(user),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),

          // Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Editar')),
              const PopupMenuItem(value: 'permissions', child: Text('Permissões')),
              PopupMenuItem(
                value: 'delete',
                child: Text('Remover', style: TextStyle(color: Colors.red.shade700)),
              ),
            ],
            onSelected: (v) {
              if (v == 'edit') _openUserForm(user: user);
              if (v == 'permissions') _openPermissionsSheet(user);
              if (v == 'delete') _deleteUser(user);
            },
          ),
        ],
      ),
    );
  }

  void _openPermissionsSheet(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => PermissionsSheet(user: user, usersService: _usersService),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}

// ---- Formulário de usuário ----
class UserFormSheet extends StatefulWidget {
  final UserModel? user;
  final Future<void> Function(Map<String, dynamic>) onSaved;

  const UserFormSheet({super.key, this.user, required this.onSaved});

  @override
  State<UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<UserFormSheet> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _role = 'seller';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _nameCtrl.text = widget.user!.name;
      _emailCtrl.text = widget.user!.email;
      _role = widget.user!.role;
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSaved({
      'name': _nameCtrl.text,
      'email': _emailCtrl.text,
      if (_passCtrl.text.isNotEmpty) 'password': _passCtrl.text,
      'role': _role,
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.user != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isEdit ? 'Editar usuário' : 'Novo usuário',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 18),
          CRMTextField(controller: _nameCtrl, label: 'Nome completo', hint: 'João da Silva'),
          const SizedBox(height: 12),
          CRMTextField(controller: _emailCtrl, label: 'Email', hint: 'joao@empresa.com',
            keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          CRMTextField(
            controller: _passCtrl,
            label: isEdit ? 'Nova senha (deixe vazio para manter)' : 'Senha',
            hint: '••••••••',
            obscureText: true,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _role,
            decoration: const InputDecoration(labelText: 'Cargo / Permissão', border: OutlineInputBorder()),
            items: [
              const DropdownMenuItem(value: 'admin', child: Text('Admin')),
              const DropdownMenuItem(value: 'supervisor', child: Text('Supervisor')),
              const DropdownMenuItem(value: 'seller', child: Text('Vendedor')),
            ],
            onChanged: (v) => setState(() => _role = v!),
          ),
          const SizedBox(height: 20),
          CRMButton(
            label: isEdit ? 'Salvar alterações' : 'Criar usuário',
            onPressed: _save,
            loading: _saving,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}

// ---- Permissões granulares ----
class PermissionsSheet extends StatefulWidget {
  final UserModel user;
  final UsersService usersService;
  const PermissionsSheet({super.key, required this.user, required this.usersService});

  @override
  State<PermissionsSheet> createState() => _PermissionsSheetState();
}

class _PermissionsSheetState extends State<PermissionsSheet> {
  late Map<String, bool> _perms;

  @override
  void initState() {
    super.initState();
    _perms = {
      'can_view_financial': widget.user.permissions?.canViewFinancial ?? false,
      'can_edit_financial': widget.user.permissions?.canEditFinancial ?? false,
      'can_view_all_leads': widget.user.permissions?.canViewAllLeads ?? false,
      'can_edit_stock': widget.user.permissions?.canEditStock ?? false,
      'can_manage_users': widget.user.permissions?.canManageUsers ?? false,
      'can_export_data': widget.user.permissions?.canExportData ?? false,
    };
  }

  final _labels = {
    'can_view_financial': 'Ver financeiro',
    'can_edit_financial': 'Editar financeiro',
    'can_view_all_leads': 'Ver todos os leads',
    'can_edit_stock': 'Editar estoque',
    'can_manage_users': 'Gerenciar usuários',
    'can_export_data': 'Exportar dados',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Permissões — ${widget.user.name}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ..._perms.entries.map((e) => SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_labels[e.key] ?? e.key, style: const TextStyle(fontSize: 14)),
            value: e.value,
            onChanged: (v) => setState(() => _perms[e.key] = v),
          )),
          const SizedBox(height: 14),
          CRMButton(
            label: 'Salvar permissões',
            fullWidth: true,
            onPressed: () async {
              await widget.usersService.updatePermissions(widget.user.id, _perms);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
