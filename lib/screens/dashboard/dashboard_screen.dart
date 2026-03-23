// ============================================================
//  dashboard_screen.dart — Tela Principal (Dashboard)
//  Menu de navegação e quadros de resumo
// ============================================================

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/company_service.dart';
import '../auth/login_screen.dart';
import 'ai_assistant_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
  final _companyService = CompanyService();
  
  int _selectedIndex = 0;
  CompanyModel? _company;

  @override
  void initState() {
    super.initState();
    _loadCompany();
  }

  Future<void> _loadCompany() async {
    // Aqui você buscaria o companyId do usuário autenticado
    // Por ora, deixamos como exemplo
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VendaFlow CRM'),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Contatos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Vendas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configurações',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHome();
      case 1:
        return _buildContacts();
      case 2:
        return _buildSales();
      case 3:
        return _buildSettings();
      default:
        return _buildHome();
    }
  }

  Widget _buildHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bem-vindo!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          
          // Cards de resumo
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Contatos',
                  value: '234',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Vendas',
                  value: '12',
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Tarefas',
                  value: '8',
                  icon: Icons.check_circle,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Receita',
                  value: 'R\$ 45k',
                  icon: Icons.attach_money,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          Text(
            'Atividades Recentes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildActivityList(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.check_circle, color: Colors.white),
          ),
          title: Text('Atividade ${index + 1}'),
          subtitle: const Text('Há 2 horas'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        );
      },
    );
  }

  Widget _buildContacts() {
    return const Center(
      child: Text('Tela de Contatos (em desenvolvimento)'),
    );
  }

  Widget _buildSales() {
    return const Center(
      child: Text('Tela de Vendas (em desenvolvimento)'),
    );
  }

  Widget _buildSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Configurações', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.smart_toy),
              title: const Text('Abrir Assistente IA'),
              subtitle: const Text('Use IA para sugerir textos, ações e resumo de vendas'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AIAssistantScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Text('Outras configurações em desenvolvimento...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
