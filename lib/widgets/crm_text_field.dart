// ============================================================
//  crm_text_field.dart — Widget de Campo de Texto
//  Com validação e estilo customizado
// ============================================================

import 'package:flutter/material.dart';

class CRMTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscureText;
  final int maxLines;
  final int? maxLength;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? errorText;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final bool readOnly;
  final TextInputAction textInputAction;

  const CRMTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.suffixIcon,
    this.prefixIcon,
    this.errorText,
    this.onTap,
    this.onChanged,
    this.readOnly = false,
    this.textInputAction = TextInputAction.next,
  });

  @override
  State<CRMTextField> createState() => _CRMTextFieldState();
}

class _CRMTextFieldState extends State<CRMTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          obscureText: _obscure,
          keyboardType: widget.keyboardType,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          readOnly: widget.readOnly,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          onTap: widget.onTap,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outlineVariant,
            ),
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: theme.colorScheme.onSurface,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : widget.suffixIcon,
            errorText: widget.errorText,
            filled: true,
            fillColor: theme.colorScheme.surface,
          ),
        ),
      ],
    );
  }
}

// Campo de texto com máscaras especiais
class CRMPhoneField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const CRMPhoneField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return CRMTextField(
      label: label,
      controller: controller,
      validator: validator,
      keyboardType: TextInputType.phone,
      hint: '(11) 9 8765-4321',
      prefixIcon: const Icon(Icons.phone),
    );
  }
}

class CRMEmailField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const CRMEmailField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return CRMTextField(
      label: label,
      controller: controller,
      validator: validator ?? _validateEmail,
      keyboardType: TextInputType.emailAddress,
      hint: 'exemplo@empresa.com',
      prefixIcon: const Icon(Icons.email),
      textInputAction: TextInputAction.done,
    );
  }

  static String? _validateEmail(String? value) {
    if (value?.isEmpty ?? true) return 'Email é obrigatório';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
      return 'Email inválido';
    }
    return null;
  }
}

class CRMPasswordField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const CRMPasswordField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return CRMTextField(
      label: label,
      controller: controller,
      validator: validator ?? _validatePassword,
      obscureText: true,
      hint: '••••••••',
      prefixIcon: const Icon(Icons.lock),
      textInputAction: TextInputAction.done,
    );
  }

  static String? _validatePassword(String? value) {
    if (value?.isEmpty ?? true) return 'Senha é obrigatória';
    if (value!.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }
}
