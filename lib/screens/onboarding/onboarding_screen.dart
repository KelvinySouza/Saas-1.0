// ============================================================
//  onboarding_screen.dart — Configuração inicial da empresa
//  Wizard de 4 etapas | Só na primeira vez
//  Dados podem ser editados depois em SettingsScreen
// ============================================================

import 'package:flutter/material.dart';
import '../../services/company_service.dart';
import '../../widgets/crm_button.dart';
import '../../widgets/crm_text_field.dart';
import '../dashboard/dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _companyService = CompanyService();
  int _currentStep = 0;
  bool _saving = false;

  // Dados coletados no wizard
  final _nameCtrl     = TextEditingController();
  final _slugCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _cnpjCtrl     = TextEditingController();
  final _addressCtrl  = TextEditingController();
  final _cityCtrl     = TextEditingController();
  String _businessType = 'tecnologia';
  Color _primaryColor = const Color(0xFF185FA5);
  final _whatsappCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _welcomeMsgCtrl = TextEditingController(text: 'Olá! Como posso te ajudar hoje?');

  static const _colors = [
    Color(0xFF185FA5), Color(0xFF0F6E56), Color(0xFF534AB7),
    Color(0xFF993C1D), Color(0xFF3B6D11), Color(0xFF993556),
  ];

  final _steps = ['Sua empresa', 'Aparência', 'Integrações', 'Pronto!'];

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _companyService.saveOnboarding(
        name: _nameCtrl.text,
        slug: _slugCtrl.text,
        email: _emailCtrl.text,
        phone: _phoneCtrl.text,
        cnpj: _cnpjCtrl.text,
        address: _addressCtrl.text,
        city: _cityCtrl.text,
        businessType: _businessType,
        primaryColor:
            '#${(_primaryColor.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
        whatsappToken: _whatsappCtrl.text,
        instagramToken: _instagramCtrl.text,
        welcomeMessage: _welcomeMsgCtrl.text,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              children: [
                // Header
                const SizedBox(height: 24),
                const Text('Configurar minha empresa',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('${_currentStep + 1} de ${_steps.length} — ${_steps[_currentStep]}',
                  style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 16),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / _steps.length,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(_primaryColor),
                  ),
                ),
                const SizedBox(height: 28),

                // Card do step
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _buildStep(),
                ),
                const SizedBox(height: 20),

                // Navegação
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentStep > 0)
                      TextButton.icon(
                        onPressed: () => setState(() => _currentStep--),
                        icon: const Icon(Icons.arrow_back_ios, size: 16),
                        label: const Text('Voltar'),
                      )
                    else
                      const SizedBox(),
                    CRMButton(
                      label: _currentStep == _steps.length - 1 ? 'Entrar no sistema' : 'Continuar',
                      onPressed: _currentStep == _steps.length - 1
                          ? _save
                          : () => setState(() => _currentStep++),
                      loading: _saving,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0: return _step1DadosEmpresa();
      case 1: return _step2Aparencia();
      case 2: return _step3Integracoes();
      case 3: return _step4Pronto();
      default: return const SizedBox();
    }
  }

  // ---- STEP 1: Dados da empresa ----
  Widget _step1DadosEmpresa() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Dados da sua empresa'),
        _row([
          CRMTextField(controller: _nameCtrl, label: 'Nome da empresa', hint: 'TechBrasil Ltda.'),
          CRMTextField(controller: _slugCtrl, label: 'ID único', hint: 'techbrasil'),
        ]),
        const SizedBox(height: 12),
        _row([
          CRMTextField(controller: _emailCtrl, label: 'Email comercial', hint: 'contato@empresa.com'),
          CRMTextField(controller: _phoneCtrl, label: 'Telefone/WhatsApp', hint: '(11) 99999-9999'),
        ]),
        const SizedBox(height: 12),
        _row([
          CRMTextField(controller: _cnpjCtrl, label: 'CNPJ (opcional)', hint: '00.000.000/0001-00'),
          DropdownButtonFormField<String>(
            // Seleção controlada pelo estado; initialValue não reflete mudanças de `setState` neste wizard.
            // ignore: deprecated_member_use
            value: _businessType,
            decoration: const InputDecoration(labelText: 'Setor', border: OutlineInputBorder()),
            items: ['tecnologia','varejo','servicos','saude','educacao','outro']
                .map((s) => DropdownMenuItem(value: s, child: Text(s[0].toUpperCase() + s.substring(1))))
                .toList(),
            onChanged: (v) => setState(() => _businessType = v!),
          ),
        ]),
        const SizedBox(height: 12),
        CRMTextField(controller: _addressCtrl, label: 'Endereço (opcional)', hint: 'Rua das Flores, 123'),
        const SizedBox(height: 12),
        CRMTextField(controller: _cityCtrl, label: 'Cidade', hint: 'São Paulo — SP'),
      ],
    );
  }

  // ---- STEP 2: Aparência / White-label ----
  Widget _step2Aparencia() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Personalização visual'),
        const Text('Escolha a cor principal do seu sistema:',
          style: TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _colors.map((c) => GestureDetector(
            onTap: () => setState(() => _primaryColor = c),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _primaryColor == c ? Colors.black : Colors.transparent,
                  width: 3,
                ),
              ),
              child: _primaryColor == c
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          )).toList(),
        ),
        const SizedBox(height: 24),
        _sectionTitle('Mensagem de boas-vindas automática'),
        CRMTextField(
          controller: _welcomeMsgCtrl,
          label: 'Mensagem inicial (WhatsApp/Instagram)',
          hint: 'Olá! Como posso ajudar?',
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Você poderá alterar cores, logo e domínio a qualquer momento em Configurações.',
                style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
              )),
            ],
          ),
        ),
      ],
    );
  }

  // ---- STEP 3: Integrações ----
  Widget _step3Integracoes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Conectar canais (opcional)'),
        const Text('Você pode pular e conectar depois em Configurações.',
          style: TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 20),
        Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.phone_android, color: Colors.green, size: 20)),
          const SizedBox(width: 10),
          const Text('WhatsApp Business API', style: TextStyle(fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        CRMTextField(
          controller: _whatsappCtrl,
          label: 'Token do WhatsApp',
          hint: 'EAABxxxxx...',
        ),
        const SizedBox(height: 20),
        Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: Colors.pink.shade100, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.camera_alt_outlined, color: Colors.pink, size: 20)),
          const SizedBox(width: 10),
          const Text('Instagram Business', style: TextStyle(fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        CRMTextField(
          controller: _instagramCtrl,
          label: 'Token do Instagram',
          hint: 'IGQxxxxx...',
        ),
      ],
    );
  }

  // ---- STEP 4: Tudo pronto ----
  Widget _step4Pronto() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle),
          child: Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 40),
        ),
        const SizedBox(height: 20),
        const Text('Tudo configurado!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text(
          'Seu sistema está pronto. Você pode alterar qualquer informação depois em Configurações → Minha empresa.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        _checkItem('CRM + Leads configurado'),
        _checkItem('Chat WhatsApp + Instagram ativo'),
        _checkItem('Dashboard de vendas pronto'),
        _checkItem('Financeiro e garantias disponíveis'),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _checkItem(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Icon(Icons.check_circle, color: Colors.green.shade600, size: 18),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(fontSize: 14)),
    ]),
  );

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
  );

  Widget _row(List<Widget> children) => Row(
    children: children.map((w) => Expanded(
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: w),
    )).toList(),
  );
}
