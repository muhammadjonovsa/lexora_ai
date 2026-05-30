import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/routes/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_widgets.dart';
import '../../../services/local_auth_service.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final authService = ref.read(authServiceProvider);
    
    try {
      if (authService.isFirebaseAvailable) {
        await authService.signIn(_emailController.text.trim(), _passwordController.text.trim());
        if (mounted) {
          LexoraSnackbar.show(context, message: "Muvaffaqiyatli kirildi!", type: SnackbarType.success);
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        }
      } else {
        throw Exception("Firebase mavjud emas. Iltimos, Mehmon rejimidan foydalaning.");
      }
    } catch (e) {
      if (mounted) {
        LexoraSnackbar.show(
          context, 
          message: e.toString().replaceFirst("Exception: ", ""), 
          type: SnackbarType.error
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGuestMode() async {
    setState(() => _isLoading = true);
    await ref.read(authServiceProvider).loginAsGuest(ref);
    if (mounted) {
      setState(() => _isLoading = false);
      LexoraSnackbar.show(
        context, 
        message: "Mehmon rejimida kirildi. Hujjatlar qurilmada saqlanadi.", 
        type: SnackbarType.ai
      );
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              
              // Top branding
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                   Text(
                    "Matn Muharriri",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  )
                ],
              ),
              const SizedBox(height: 40),
              
              Text(
                "Xush kelibsiz!",
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Hujjatlarni aqlli AI yordamida yozing va tahrirlang.",
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 40),
              
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    LexoraTextField(
                      controller: _emailController,
                      label: "Email",
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.text,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return "Foydalanuvchi nomi kiritish majburiy";
                        if (val.trim().length < 3) return "Foydalanuvchi nomi kamida 3 ta belgi bo'lishi kerak";
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    LexoraTextField(
                      controller: _passwordController,
                      label: "Parol",
                      prefixIcon: Icons.lock_outlined,
                      isObscure: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Parol kiritish majburiy";
                        if (val.length < 6) return "Parol kamida 6 belgidan iborat bo'lishi kerak";
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                        child: Text(
                          "Parolni unutdingizmi?",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    LexoraButton(
                      text: "Tizimga kirish",
                      isLoading: _isLoading,
                      onPressed: _handleLogin,
                    ),
                    
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Hisobingiz yo'qmi? ",
                          style: theme.textTheme.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, AppRoutes.register),
                          child: Text(
                            "Ro'yxatdan o'ting",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        const Expanded(child: Divider(thickness: 1.2)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text("YOKI", style: theme.textTheme.bodyMedium),
                        ),
                        const Expanded(child: Divider(thickness: 1.2)),
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                    LexoraButton(
                      text: "Mehmon sifatida davom etish",
                      isSecondary: true,
                      onPressed: _handleGuestMode,
                      icon: Icons.person_outline_rounded,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final authService = ref.read(authServiceProvider);
    
    try {
      if (authService.isFirebaseAvailable) {
        await authService.signUp(_emailController.text.trim(), _passwordController.text.trim());
        if (mounted) {
          LexoraSnackbar.show(context, message: "Hisob muvaffaqiyatli yaratildi!", type: SnackbarType.success);
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        }
      } else {
        throw Exception("Firebase faollashtirilmagan.");
      }
    } catch (e) {
      if (mounted) {
        LexoraSnackbar.show(
          context, 
          message: e.toString().replaceFirst("Exception: ", ""), 
          type: SnackbarType.error
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hisob yaratish",
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Matn Muharriri bilan kelajak matn muharririga a'zo bo'ling.",
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 40),
              
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    LexoraTextField(
                      controller: _emailController,
                      label: "Email",
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.text,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return "Foydalanuvchi nomi kiritish majburiy";
                        if (val.trim().length < 3) return "Foydalanuvchi nomi kamida 3 ta belgi bo'lishi kerak";
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    LexoraTextField(
                      controller: _passwordController,
                      label: "Parol",
                      prefixIcon: Icons.lock_outlined,
                      isObscure: _obscurePassword,
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Parol kiritish majburiy";
                        if (val.length < 6) return "Parol kamida 6 belgidan iborat bo'lishi kerak";
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    LexoraTextField(
                      controller: _confirmPasswordController,
                      label: "Parolni tasdiqlash",
                      prefixIcon: Icons.lock_clock_outlined,
                      isObscure: _obscurePassword,
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Parolni tasdiqlang";
                        if (val != _passwordController.text) return "Parollar mos kelmadi";
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    LexoraButton(
                      text: "Hisob yaratish",
                      isLoading: _isLoading,
                      onPressed: _handleRegister,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Hisobingiz bormi? ",
                          style: theme.textTheme.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            "Tizimga kiring",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      await ref.read(authServiceProvider).sendPasswordReset(_emailController.text.trim());
      if (mounted) {
        LexoraSnackbar.show(
          context, 
          message: "Parolni tiklash havolasi email manzilingizga yuborildi!", 
          type: SnackbarType.success
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        LexoraSnackbar.show(
          context, 
          message: e.toString().replaceFirst("Exception: ", ""), 
          type: SnackbarType.error
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Parolni tiklash",
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Parolni tiklash havolasini olish uchun hisobingizdagi email manzilini kiriting.",
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 40),
              
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    LexoraTextField(
                      controller: _emailController,
                      label: "Email",
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.text,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return "Foydalanuvchi nomi kiritish majburiy";
                        if (val.trim().length < 3) return "Foydalanuvchi nomi kamida 3 ta belgi bo'lishi kerak";
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    LexoraButton(
                      text: "Parolni tiklash",
                      isLoading: _isLoading,
                      onPressed: _handleReset,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
