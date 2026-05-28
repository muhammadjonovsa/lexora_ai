import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LexoraButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;
  final double width;
  final double height;
  final Gradient? customGradient;

  const LexoraButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
    this.width = double.infinity,
    this.height = 56,
    this.customGradient,
  }) : super(key: key);

  @override
  State<LexoraButton> createState() => _LexoraButtonState();
}

class _LexoraButtonState extends State<LexoraButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget buttonContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.isSecondary
                    ? (isDark ? Colors.white : theme.primaryColor)
                    : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ] else if (widget.icon != null) ...[
          Icon(
            widget.icon,
            size: 20,
            color: widget.isSecondary
                ? (isDark ? Colors.white : theme.primaryColor)
                : Colors.white,
          ),
          const SizedBox(width: 10),
        ],
        Text(
          widget.text,
          style: theme.textTheme.titleMedium?.copyWith(
            color: widget.isSecondary
                ? (isDark ? Colors.white : theme.primaryColor)
                : Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: widget.isSecondary
                ? null
                : (widget.customGradient ?? AppTheme.primaryGradient),
            color: widget.isSecondary
                ? (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0))
                : null,
            boxShadow: widget.isSecondary || widget.onPressed == null
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Center(child: buttonContent),
          ),
        ),
      ),
    );
  }
}

class LexoraTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool isObscure;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  const LexoraTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.isObscure = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      style: theme.textTheme.bodyLarge,
      cursorColor: theme.primaryColor,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              )
            : null,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

enum SnackbarType { success, error, warning, ai }

class LexoraSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.success,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(context);
    
    IconData icon;
    Color bgColor;
    Gradient? gradient;
    
    switch (type) {
      case SnackbarType.success:
        icon = Icons.check_circle_rounded;
        bgColor = const Color(0xFF10B981);
        break;
      case SnackbarType.error:
        icon = Icons.error_rounded;
        bgColor = const Color(0xFFEF4444);
        break;
      case SnackbarType.warning:
        icon = Icons.warning_rounded;
        bgColor = const Color(0xFFF59E0B);
        break;
      case SnackbarType.ai:
        icon = Icons.auto_awesome_rounded;
        bgColor = const Color(0xFF8B5CF6);
        gradient = AppTheme.aiGradient;
        break;
    }

    final snack = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      duration: duration,
      margin: const EdgeInsets.all(16),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(snack);
  }
}

class LexoraLoader extends StatelessWidget {
  final String? statusText;

  const LexoraLoader({Key? key, this.statusText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                  ),
                ),
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 24,
                  color: theme.primaryColor,
                ),
              ],
            ),
          ),
          if (statusText != null) ...[
            const SizedBox(height: 16),
            Text(
              statusText!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
