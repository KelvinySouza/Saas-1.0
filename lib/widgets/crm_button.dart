// ============================================================
//  crm_button.dart — Widget de Botão Customizado
//  Usa design system da aplicação
// ============================================================

import 'package:flutter/material.dart';

class CRMButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool loading;
  final bool enabled;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final BorderRadiusGeometry? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool fullWidth;

  const CRMButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.enabled = true,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 48,
    this.borderRadius,
    this.padding,
    this.fullWidth = false,
  });

  @override
  State<CRMButton> createState() => _CRMButtonState();
}

class _CRMButtonState extends State<CRMButton> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = widget.backgroundColor ?? theme.colorScheme.primary;
    final txtColor = widget.textColor ?? Colors.white;

    final buttonContent = widget.loading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(txtColor),
            ),
          )
        : Text(
            widget.label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: txtColor,
              fontWeight: FontWeight.w600,
            ),
          );

    final button = ElevatedButton(
      onPressed: widget.enabled && !widget.loading ? widget.onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        disabledBackgroundColor: bgColor.withOpacity(0.5),
        foregroundColor: bgColor,
        padding: widget.padding ?? 
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(10),
        ),
        fixedSize: Size(
          widget.width ?? (widget.fullWidth ? double.infinity : 120),
          widget.height,
        ),
      ),
      child: buttonContent,
    );

    return button;
  }
}

// Variações de botão
class CRMOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool loading;
  final bool enabled;
  final Color? borderColor;
  final Color? textColor;
  final double width;
  final double height;

  const CRMOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.enabled = true,
    this.borderColor,
    this.textColor,
    this.width = double.infinity,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = borderColor ?? theme.colorScheme.primary;
    final txtColor = textColor ?? theme.colorScheme.primary;

    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: enabled && !loading ? onPressed : null,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: border, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: loading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(txtColor),
                ),
              )
            : Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: txtColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
