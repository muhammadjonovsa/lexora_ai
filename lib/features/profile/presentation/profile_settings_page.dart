import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/routes/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_widgets.dart';
import '../../../services/local_auth_service.dart';
import '../../../services/local_storage_service.dart';

// Riverpod theme state manager provider
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system; // system default
});

class ProfileSettingsPage extends ConsumerStatefulWidget {
  const ProfileSettingsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends ConsumerState<ProfileSettingsPage> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isSavingKey = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  // Load key from LocalStorageService (Hive Box)
  Future<void> _loadApiKey() async {
    final key = LocalStorageService.getSetting(AppConstants.keyApiKey, defaultValue: '') as String;
    setState(() {
      _apiKeyController.text = key;
    });
  }

  // Save key
  Future<void> _saveApiKey() async {
    setState(() => _isSavingKey = true);
    final key = _apiKeyController.text.trim();
    
    await LocalStorageService.saveSetting(AppConstants.keyApiKey, key);
    
    setState(() => _isSavingKey = false);
    
    if (mounted) {
      LexoraSnackbar.show(
        context,
        message: key.isEmpty 
            ? "API kalit o'chirildi! Hozir Sandbox rejimidamiz." 
            : "Gemini API kaliti muvaffaqiyatli saqlandi!",
        type: key.isEmpty ? SnackbarType.warning : SnackbarType.success,
      );
    }
  }

  // Toggle app-wide theme mode
  Future<void> _toggleTheme(bool isDark) async {
    final mode = isDark ? ThemeMode.dark : ThemeMode.light;
    ref.read(themeModeProvider.notifier).state = mode;
    
    await LocalStorageService.saveSetting(AppConstants.keyDarkMode, isDark);
  }

  // Handle Log Out
  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);
    
    final authService = ref.read(authServiceProvider);
    
    try {
      await authService.signOut(ref);
      if (mounted) {
        LexoraSnackbar.show(context, message: "Muvaffaqiyatli tizimdan chiqildi!", type: SnackbarType.success);
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        LexoraSnackbar.show(context, message: "Chiqishda xatolik yuz berdi.", type: SnackbarType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark || 
        (ref.watch(themeModeProvider) == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
    
    final isGuest = ref.watch(guestModeProvider);
    final user = ref.read(authServiceProvider).currentUser;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Sozlamalar va Profil", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. User Profile Detail Panel
              _buildProfileCard(theme, isGuest, user),
              const SizedBox(height: 24),

              // 2. AI API Settings Section
              Text(
                "Sun'iy Intellekt Sozlamalari",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor, width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.vpn_key_outlined, color: Color(0xFF8B5CF6)),
                        const SizedBox(width: 10),
                        Text(
                          "Gemini API Kaliti",
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Matn Muharriri to'liq va cheksiz AI imkoniyatlaridan foydalanish uchun o'zingizning shaxsiy Gemini API kalitingizni kiriting.",
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    LexoraTextField(
                      controller: _apiKeyController,
                      label: "Gemini API kaliti (AI Key)",
                      hint: "AIzaSy...",
                      isObscure: true,
                    ),
                    const SizedBox(height: 16),
                    LexoraButton(
                      text: "Kalitni saqlash",
                      isLoading: _isSavingKey,
                      onPressed: _saveApiKey,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Application Configurations (Theme and Modes)
              Text(
                "Ilova Sozlamalari",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 1,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.dark_mode_outlined),
                      title: const Text("Tungi rejim (Dark Mode)"),
                      trailing: Switch(
                        value: isDarkMode,
                        onChanged: _toggleTheme,
                        activeColor: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. About Lexora Accordion Details
              Text(
                "Ilova haqida",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      _buildAboutItem(
                        icon: Icons.auto_awesome_rounded,
                        title: "AI Imkoniyatlari",
                        subtitle: "Mavzu bo'yicha matn yozish, tarjima, imlo xatolarini tuzatish va chat yordamchi.",
                        theme: theme,
                      ),
                      const Divider(height: 16),
                      _buildAboutItem(
                        icon: Icons.mic_rounded,
                        title: "Ovoz orqali yozish (Dictation)",
                        subtitle: "Real vaqt rejimida aytib turib matn yozish, uzbek tili qo'llab-quvvatlanadi.",
                        theme: theme,
                      ),
                      const Divider(height: 16),
                      _buildAboutItem(
                        icon: Icons.document_scanner_rounded,
                        title: "OCR Hujjat Skaneri",
                        subtitle: "Rasm va kameradan olingan fotosuratlardagi matnlarni bir zumda aniqlab olish.",
                        theme: theme,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // 5. Logout CTA Button
              LexoraButton(
                text: "Tizimdan chiqish",
                isSecondary: true,
                isLoading: _isLoggingOut,
                onPressed: _handleLogout,
                icon: Icons.logout_rounded,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(ThemeData theme, bool isGuest, dynamic user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGuest ? "Mehmon Foydalanuvchi" : (user?.email?.split('@').first ?? "Foydalanuvchi"),
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  isGuest ? "Oflayn rejim faol" : (user?.email ?? "Tizimga kirilgan"),
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isGuest ? "Guest" : "Pro",
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAboutItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: theme.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
